// wsNumber and WsBeats: a typed number, and the beat grid the timeline snaps to. The expected values are what the code
// gave when this was written, so a move that changes one fails here. Needs no engine.
import 'package:flutter_test/flutter_test.dart';
import 'package:motolii/workspace/state/beats.dart';

void main() {
  test('wsNumber reads a typed number, full-width digits and spaces around it included', () {
    expect(wsNumber('12.5'), 12.5);
    expect(wsNumber(' １２．５ '), 12.5);
    expect(wsNumber('-3'), -3);
    expect(wsNumber('1e3'), 1000);
    expect(wsNumber(''), isNull);
    expect(wsNumber('abc'), isNull);
    expect(wsNumber('１２８：３０'), isNull);
  });

  test('between gives each beat from one frame to another, ends included, and whether a bar begins there', () {
    expect(const WsBeats(10, 15).between(0, 70), [(10, true), (25, false), (40, false), (55, false), (70, true)]);
    expect(const WsBeats(0, 12.5).between(20, 40), [(25, false), (37.5, false)]);
  });

  test('between counts the bars back from the first one too', () {
    expect(const WsBeats(100, 15).between(40, 100), [(40, true), (55, false), (70, false), (85, false), (100, true)]);
  });

  test('nearest gives the frame of the beat closest to a frame', () {
    const beats = WsBeats(10, 15);
    expect([beats.nearest(30), beats.nearest(33), beats.nearest(10), beats.nearest(0)], [25, 40, 10, -5]);
    expect(const WsBeats(0, 12.5).nearest(32), 38); // The beat is at frame 37.5.
  });
}
