import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../moves/moves.dart';
import '../theme.dart';
import '../util.dart';

enum _Phase { idle, warmup, work, rest, done }

/// Kickboxing round timer: get-ready, rounds, rest. Works offline and keeps
/// the screen on while running. Optional shadow-boxing mode calls out a
/// random combo every few seconds during rounds.
class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const _warmupSeconds = 10;

  int _rounds = 3;
  int _workSeconds = 120;
  int _restSeconds = 60;
  bool _shadow = false;
  int _shadowLevel = 0;
  int _shadowEvery = 8;

  _Phase _phase = _Phase.idle;
  int _round = 1;
  DateTime _phaseEnd = DateTime.now();
  Duration _remaining = Duration.zero;
  bool _paused = false;
  bool _warned = false;
  Timer? _ticker;

  final _random = math.Random();
  List<String> _call = const [];
  int _nextCallAt = 0; // seconds remaining in round when the next combo appears

  /// Keeps the screen on; never lets a wakelock failure break the timer.
  void _wake(bool on) {
    try {
      (on ? WakelockPlus.enable() : WakelockPlus.disable()).catchError((_) {});
    } catch (_) {}
  }

  bool get _running => _phase != _Phase.idle && _phase != _Phase.done;

  Duration _durationOf(_Phase p) {
    switch (p) {
      case _Phase.warmup:
        return const Duration(seconds: _warmupSeconds);
      case _Phase.work:
        return Duration(seconds: _workSeconds);
      case _Phase.rest:
        return Duration(seconds: _restSeconds);
      case _Phase.idle:
      case _Phase.done:
        return Duration.zero;
    }
  }

  void _signal({required bool strong}) {
    SystemSound.play(SystemSoundType.alert);
    if (strong) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
  }

  void _enter(_Phase p) {
    final d = _durationOf(p);
    setState(() {
      _phase = p;
      _phaseEnd = DateTime.now().add(d);
      _remaining = d;
      _warned = false;
      _call = const [];
      _nextCallAt = _workSeconds - 1;
    });
    _signal(strong: p == _Phase.work);
  }

  void _start() {
    _wake(true);
    _round = 1;
    _paused = false;
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) => _tick());
    _enter(_Phase.warmup);
  }

  void _tick() {
    if (!mounted || !_running || _paused) return;
    final left = _phaseEnd.difference(DateTime.now());
    if (left <= Duration.zero) {
      _advance();
      return;
    }
    if (_phase == _Phase.work &&
        !_warned &&
        _workSeconds > 20 &&
        left <= const Duration(seconds: 10)) {
      _warned = true;
      _signal(strong: false);
    }
    if (_shadow && _phase == _Phase.work) {
      final secLeft = left.inSeconds;
      if (secLeft <= _nextCallAt && secLeft > 2) {
        _call = randomCombo(_random, _shadowLevel);
        _nextCallAt = secLeft - _shadowEvery;
        HapticFeedback.selectionClick();
      }
    }
    setState(() => _remaining = left);
  }

  void _advance() {
    switch (_phase) {
      case _Phase.warmup:
        _enter(_Phase.work);
      case _Phase.work:
        if (_round >= _rounds) {
          _finish();
        } else if (_restSeconds == 0) {
          setState(() => _round++);
          _enter(_Phase.work);
        } else {
          _enter(_Phase.rest);
        }
      case _Phase.rest:
        setState(() => _round++);
        _enter(_Phase.work);
      case _Phase.idle:
      case _Phase.done:
        break;
    }
  }

  void _finish() {
    _ticker?.cancel();
    _wake(false);
    setState(() => _phase = _Phase.done);
    _signal(strong: true);
  }

  void _stop() {
    _ticker?.cancel();
    _wake(false);
    setState(() {
      _phase = _Phase.idle;
      _paused = false;
    });
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        _phaseEnd = DateTime.now().add(_remaining);
        _paused = false;
      } else {
        _paused = true;
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _wake(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _running ? null : AppBar(title: const Text('تایمر راند')),
      body: _running ? SafeArea(child: _buildRunning(context)) : _buildSettings(context),
    );
  }

  // ---------- settings ----------

  void _preset(int rounds, int work, int rest) {
    setState(() {
      _rounds = rounds;
      _workSeconds = work;
      _restSeconds = rest;
    });
  }

  Widget _stepRow({
    required String label,
    required String kicker,
    required String value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kicker, style: display(12, color: AppColors.muted)),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            IconButton.filledTonal(onPressed: onMinus, icon: const Icon(Icons.remove)),
            SizedBox(
              width: 86,
              child: Text(value,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: display(30)),
            ),
            IconButton.filledTonal(onPressed: onPlus, icon: const Icon(Icons.add)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    final total = _rounds * _workSeconds + (_rounds - 1) * _restSeconds;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        if (_phase == _Phase.done)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: const ShapeDecoration(
              shape: cutShape,
              gradient: LinearGradient(colors: [AppColors.blue, AppColors.blueDeep]),
            ),
            child: Column(
              children: [
                Text('WELL DONE', style: display(30)),
                const Text('تمرین تمام شد. دمت گرم!',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ActionChip(
              label: const Text('3 راند × 2 دقیقه'),
              onPressed: () => _preset(3, 120, 60),
            ),
            ActionChip(
              label: const Text('5 راند × 3 دقیقه'),
              onPressed: () => _preset(5, 180, 60),
            ),
            ActionChip(
              label: const Text('اینتروال 8 × 30 ثانیه'),
              onPressed: () => _preset(8, 30, 15),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _stepRow(
          label: 'تعداد راند',
          kicker: 'ROUNDS',
          value: '$_rounds',
          onMinus: _rounds > 1 ? () => setState(() => _rounds--) : null,
          onPlus: _rounds < 20 ? () => setState(() => _rounds++) : null,
        ),
        _stepRow(
          label: 'مدت هر راند',
          kicker: 'ROUND TIME',
          value: mmss(_workSeconds),
          onMinus: _workSeconds > 15 ? () => setState(() => _workSeconds -= 15) : null,
          onPlus: _workSeconds < 600 ? () => setState(() => _workSeconds += 15) : null,
        ),
        _stepRow(
          label: 'استراحت',
          kicker: 'REST',
          value: mmss(_restSeconds),
          onMinus: _restSeconds > 0 ? () => setState(() => _restSeconds -= 15) : null,
          onPlus: _restSeconds < 300 ? () => setState(() => _restSeconds += 15) : null,
        ),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _shadow,
                onChanged: (v) => setState(() => _shadow = v),
                title: const Text('کمبو خوان (شدوبوکس)',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('در طول راند، هر چند ثانیه یک کمبوی تصادفی روی صفحه می‌آید'),
              ),
              if (_shadow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (var i = 0; i < levelLabels.length; i++)
                            ChoiceChip(
                              label: Text(levelLabels[i]),
                              selected: _shadowLevel == i,
                              onSelected: (_) => setState(() => _shadowLevel = i),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('هر', style: TextStyle(color: AppColors.muted)),
                          for (final s in [5, 8, 12])
                            ChoiceChip(
                              label: Text('$s ثانیه'),
                              selected: _shadowEvery == s,
                              onSelected: (_) => setState(() => _shadowEvery = s),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 62)),
          onPressed: _start,
          icon: const Icon(Icons.play_arrow, size: 28),
          label: Text(_phase == _Phase.done ? 'شروع دوباره' : 'شروع تمرین',
              style: const TextStyle(fontSize: 17)),
        ),
        const SizedBox(height: 10),
        Text(
          'مجموع: ${mmss(total)} · قبل از راند اول $_warmupSeconds ثانیه آماده‌سازی. '
          'تا وقتی تایمر کار می‌کند صفحه روشن می‌ماند.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.8),
        ),
      ],
    );
  }

  // ---------- running ----------

  Widget _buildRunning(BuildContext context) {
    final Color tint;
    final String en;
    final String fa;
    switch (_phase) {
      case _Phase.warmup:
        tint = AppColors.gold;
        en = 'GET READY';
        fa = 'آماده باش';
      case _Phase.work:
        tint = AppColors.cyan;
        en = 'ROUND $_round / $_rounds';
        fa = 'مبارزه';
      case _Phase.rest:
        tint = AppColors.success;
        en = 'REST';
        fa = 'استراحت · بعدی راند ${_round + 1}';
      case _Phase.idle:
      case _Phase.done:
        tint = AppColors.muted;
        en = '';
        fa = '';
    }

    final total = _durationOf(_phase).inMilliseconds;
    final progress = total == 0 ? 0.0 : (_remaining.inMilliseconds / total).clamp(0.0, 1.0);
    final seconds = (_remaining.inMilliseconds / 1000).ceil();
    final showCall = _shadow && _phase == _Phase.work && _call.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.2),
          radius: 1.1,
          colors: [tint.withValues(alpha: 0.18), AppColors.bg],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(en, style: display(34, color: tint, spacing: 4)),
          Text(fa, style: const TextStyle(color: AppColors.muted)),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: CustomPaint(
                  painter: _RingPainter(progress: progress, color: tint),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(mmss(seconds),
                            textDirection: TextDirection.ltr,
                            style: display(92, spacing: 1)),
                        if (_paused)
                          Text('PAUSED', style: display(18, color: AppColors.gold)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: showCall
                ? Container(
                    key: ValueKey(_call.join(',')),
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: ShapeDecoration(
                      color: AppColors.surface,
                      shape: BeveledRectangleBorder(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(14),
                          bottomRight: Radius.circular(14),
                        ),
                        side: BorderSide(color: tint),
                      ),
                    ),
                    child: Column(
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            _call.map((id) => moveById(id).code ?? moveById(id).nameEn).join(' · '),
                            textAlign: TextAlign.center,
                            style: display(26, color: AppColors.cyan),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _call.map((id) => moveById(id).nameFa.split(' (').first).join(' + '),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  )
                : const SizedBox(height: 16),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 58)),
                  onPressed: _togglePause,
                  icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                  label: Text(_paused ? 'ادامه' : 'توقف'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 58),
                    backgroundColor: AppColors.danger,
                  ),
                  onPressed: _stop,
                  icon: const Icon(Icons.stop),
                  label: const Text('پایان'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 16;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = AppColors.line,
    );
    final rect = Rect.fromCircle(center: c, radius: r);
    final sweep = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    // tick marks
    final tick = Paint()
      ..color = AppColors.line
      ..strokeWidth = 2;
    for (var i = 0; i < 60; i++) {
      final a = i / 60 * 2 * math.pi;
      final o = Offset(math.cos(a), math.sin(a));
      final len = i % 5 == 0 ? 10.0 : 4.0;
      canvas.drawLine(c + o * (r - 18), c + o * (r - 18 - len), tick);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}
