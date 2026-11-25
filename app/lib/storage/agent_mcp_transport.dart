// Minimal loopback Streamable-HTTP MCP server transport (JSON-RPC 2.0 over
// 127.0.0.1) so any ACP agent can call Motolii tools in real time. Panels and
// bridges import this instead of dart:io.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

typedef McpToolHandler = FutureOr<Map<String, Object?>> Function(
  String name,
  Map<String, Object?> arguments,
);

/// Loopback HTTP MCP server authenticated with a per-launch random Bearer token.
class AgentMcpTransport {
  AgentMcpTransport._(this._server, this.url, this.token);

  final HttpServer _server;
  final String url;
  final String token;

  static Future<AgentMcpTransport> start({
    required List<Map<String, Object?>> Function() listTools,
    required McpToolHandler callTool,
    String serverName = 'motolii',
    String serverVersion = '1.0.0',
  }) async {
    final rng = Random.secure();
    final token = List.generate(
      24,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final url = 'http://127.0.0.1:${server.port}/mcp';
    final transport = AgentMcpTransport._(server, url, token);
    unawaited(
      transport._serve(
        listTools: listTools,
        callTool: callTool,
        serverName: serverName,
        serverVersion: serverVersion,
      ),
    );
    return transport;
  }

  Future<void> _serve({
    required List<Map<String, Object?>> Function() listTools,
    required McpToolHandler callTool,
    required String serverName,
    required String serverVersion,
  }) async {
    await for (final req in _server) {
      try {
        final auth = req.headers.value(HttpHeaders.authorizationHeader) ?? '';
        if (auth != 'Bearer $token') {
          req.response
            ..statusCode = HttpStatus.unauthorized
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'error': 'unauthorized'}));
          await req.response.close();
          continue;
        }
        if (req.method == 'DELETE') {
          req.response.statusCode = HttpStatus.noContent;
          await req.response.close();
          continue;
        }
        if (req.method != 'POST') {
          req.response.statusCode = HttpStatus.methodNotAllowed;
          await req.response.close();
          continue;
        }
        final body = await utf8.decoder.bind(req).join();
        final decoded = jsonDecode(body);
        if (decoded is! Map) {
          await _writeJson(req.response, {
            'jsonrpc': '2.0',
            'id': null,
            'error': {'code': -32600, 'message': 'Invalid request'},
          });
          continue;
        }
        final id = decoded['id'];
        final method = '${decoded['method'] ?? ''}';
        final params = decoded['params'] is Map
            ? {
                for (final e in (decoded['params'] as Map).entries)
                  '${e.key}': e.value,
              }
            : const <String, Object?>{};
        // Notifications have no id and expect HTTP 202 Accepted with empty body.
        if (id == null) {
          req.response.statusCode = HttpStatus.accepted;
          await req.response.close();
          continue;
        }
        final result = await _dispatch(
          method: method,
          params: params,
          listTools: listTools,
          callTool: callTool,
          serverName: serverName,
          serverVersion: serverVersion,
        );
        await _writeJson(req.response, {'jsonrpc': '2.0', 'id': id, ...result});
      } catch (e) {
        try {
          await _writeJson(req.response, {
            'jsonrpc': '2.0',
            'id': null,
            'error': {'code': -32603, 'message': '$e'},
          });
        } catch (_) {}
      }
    }
  }

  Future<Map<String, Object?>> _dispatch({
    required String method,
    required Map<String, Object?> params,
    required List<Map<String, Object?>> Function() listTools,
    required McpToolHandler callTool,
    required String serverName,
    required String serverVersion,
  }) async {
    switch (method) {
      case 'initialize':
        final proto = params['protocolVersion'] is String
            ? params['protocolVersion'] as String
            : '2025-03-26';
        return {
          'result': {
            'protocolVersion': proto,
            'capabilities': {
              'tools': {'listChanged': false},
            },
            'serverInfo': {'name': serverName, 'version': serverVersion},
          },
        };
      case 'ping':
        return {'result': <String, Object?>{}};
      case 'tools/list':
        return {
          'result': {'tools': listTools()},
        };
      case 'tools/call':
        final name = '${params['name'] ?? ''}';
        final rawArgs = params['arguments'];
        final args = rawArgs is Map
            ? {for (final e in rawArgs.entries) '${e.key}': e.value}
            : const <String, Object?>{};
        try {
          final res = await callTool(name, args);
          return {'result': res};
        } catch (e) {
          return {
            'result': {
              'isError': true,
              'content': [
                {'type': 'text', 'text': 'Error in $name: $e'},
              ],
            },
          };
        }
      default:
        return {
          'error': {'code': -32601, 'message': 'Method not found: $method'},
        };
    }
  }

  Future<void> _writeJson(
    HttpResponse response,
    Map<String, Object?> body,
  ) async {
    response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    await response.close();
  }

  Future<void> close() => _server.close(force: true);
}
