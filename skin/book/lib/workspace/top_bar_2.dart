// Part of top_bar.dart (cut there by size, as it was).
part of 'top_bar.dart';

class _WaitedState extends State<_Waited> {
  final _open = OverlayPortalController(), _at = LayerLink();
  late final Timer _look;
  final _born = Stopwatch()..start();
  int _count = 0, _inside = -1, _insideSeen = 0, _lateCount = 0, _lastFinish = 0;   // (the inside's count as last read; what of it was seen while the window was shown)
  bool _moved = false;   // (played, or a hand down dragging or scrolling, since the window's last timings came)
  final _late = <String>[];   // (the window's own missed frames, timed: the last 200)

  static const _beat = 1000000 ~/ 60;   // (1/60 s in microseconds: a frame's budget, as Flutter's performance overlay judges it)

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_timings);
    GestureBinding.instance.pointerRouter.addGlobalRoute(_hand);
    _look = Timer.periodic(const Duration(milliseconds: 500), (_) {   // (read without waiting: the inside's count)
      final ws = WsScope.read(context);
      _moved |= ws.playing;
      final n = ws.inside?.brokenCount ?? 0;
      final shown = switch (WidgetsBinding.instance.lifecycleState) { AppLifecycleState.hidden || AppLifecycleState.paused => false, _ => true };
      if (_inside >= 0 && shown) _insideSeen += math.max(0, n - _inside);   // (the inside's, counted only while the window is shown)
      _inside = n;
      _recount();
    });
  }

  void _hand(PointerEvent e) {
    if (e.down || e is PointerScrollEvent || e is PointerPanZoomUpdateEvent) _moved = true;
  }

  /// Flutter's own per-frame timings (FrameTiming): a frame whose build (UI thread) or raster (raster thread) took longer
  /// than a beat missed 60 fps. Counted only while something moves: drawn right after the frame before (within two
  /// beats of its raster's end) while played or handled, and not in the window's opening seconds.
  void _timings(List<FrameTiming> timings) {
    if (!mounted) return;
    final moved = _moved || WsScope.read(context).playing;
    _moved = false;
    if (timings.isEmpty) return;
    final now = DateTime.now(), last = timings.last.timestampInMicroseconds(FramePhase.rasterFinish);
    for (final f in timings) {
      final start = f.timestampInMicroseconds(FramePhase.vsyncStart), finish = f.timestampInMicroseconds(FramePhase.rasterFinish);
      final going = _lastFinish > 0 && start - _lastFinish <= 2 * _beat;
      _lastFinish = finish;
      final build = f.buildDuration.inMicroseconds, raster = f.rasterDuration.inMicroseconds;
      if (!moved || !going || _born.elapsed.inSeconds < 3 || (build <= _beat && raster <= _beat)) continue;
      final at = now.subtract(Duration(microseconds: last - finish));
      String ms(int us) => (us / 1000).toStringAsFixed(1);
      final slow = [if (build > _beat) "the window's build ${ms(build)} ms", if (raster > _beat) "the window's raster ${ms(raster)} ms"].join(', ');
      _late.add('${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}:${at.second.toString().padLeft(2, '0')}.${at.millisecond.toString().padLeft(3, '0')} '
          '$slow (build ${ms(build)}, raster ${ms(raster)}, all ${ms(f.totalSpan.inMicroseconds)})${kDebugMode ? ', a debug build: slower than the app' : ''}');
      if (_late.length > 200) _late.removeAt(0);
      _lateCount++;
    }
    _recount();
  }

  void _recount() {
    final n = _insideSeen + _lateCount;
    if (n != _count && mounted) setState(() => _count = n);
  }

  @override
  void dispose() {
    _look.cancel();
    SchedulerBinding.instance.removeTimingsCallback(_timings);
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_hand);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) return const SizedBox.shrink();
    final lines = _open.isShowing   // (the inside's and the window's, newest first: each line starts with its clock time)
        ? ([...(WsScope.read(context).inside?.broken ?? '').split('\n').where((l) => l.isNotEmpty), ..._late]..sort((a, b) => b.compareTo(a))).take(40).toList()
        : const <String>[];
    return CompositedTransformTarget(
      link: _at,
      child: OverlayPortal(
        controller: _open,
        overlayChildBuilder: (overlay) => CompositedTransformFollower(
          link: _at,
          targetAnchor: Alignment.bottomRight,
          followerAnchor: Alignment.topRight,
          offset: const Offset(0, 6),
          child: Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => setState(_open.hide),
              child: Container(
                width: Shape.z(520),
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(overlay).height * .7),   // (each line whole, wrapped; many: scrolled, none cut)
                padding: EdgeInsets.all(Shape.s(10)),
                decoration: BoxDecoration(color: WsT.card, borderRadius: BorderRadius.all(Shape.r(6)), border: Border.all(color: Grey.g26)),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [for (final l in lines) Padding(padding: EdgeInsets.only(bottom: Shape.s(3)), child: Text(l, softWrap: true, style: T.micro(Grey.g76)))],
                  ),
                ),
              ),
            ),
          ),
        ),
        child: _Hover(
          onTap: () => setState(_open.toggle),
          builder: (h) => Padding(
            padding: EdgeInsets.only(right: Shape.s(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: Shape.z(6), height: Shape.z(6), decoration: BoxDecoration(color: ColorTheme.of('Alert', const Color(0xFFE5484D)), shape: BoxShape.circle)),
                SizedBox(width: Shape.s(5)),
                Text('$_count', style: T.label(h ? Grey.g91 : Grey.g63)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
