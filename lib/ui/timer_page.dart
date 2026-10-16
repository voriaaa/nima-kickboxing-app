import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../util.dart';

enum _Phase { idle, warmup, work, rest, done }

/// تایمر راند کیک‌بوکس: آماده‌سازی، راند، استراحت. بدون اینترنت کار می‌کند
/// و تا وقتی در حال اجراست صفحه روشن می‌ماند.
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

  _Phase _phase = _Phase.idle;
  int _round = 1;
  DateTime _phaseEnd = DateTime.now();
  Duration _remaining = Duration.zero;
  bool _paused = false;
  bool _warned = false;
  Timer? _ticker;

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
    });
    _signal(strong: p == _Phase.work);
  }

  void _start() {
    WakelockPlus.enable();
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
    WakelockPlus.disable();
    setState(() => _phase = _Phase.done);
    _signal(strong: true);
  }

  void _stop() {
    _ticker?.cancel();
    WakelockPlus.disable();
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
    WakelockPlus.disable();
    super.dispose();
  }

  String _mmss(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return toFa('${two(m)}:${two(s)}');
  }

  @override
  Widget build(BuildContext context) {
    return _running ? _buildRunning(context) : _buildSettings(context);
  }

  // ---------- تنظیم ----------

  void _preset(int rounds, int work, int rest) {
    setState(() {
      _rounds = rounds;
      _workSeconds = work;
      _restSeconds = rest;
    });
  }

  Widget _stepRow({
    required String label,
    required String value,
    required VoidCallback? onMinus,
    required VoidCallback? onPlus,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            IconButton.filledTonal(
              onPressed: onMinus,
              icon: const Icon(Icons.remove),
            ),
            SizedBox(
              width: 80,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton.filledTonal(
              onPressed: onPlus,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (_phase == _Phase.done)
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'تمرین تمام شد. دمت گرم! 💪',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ActionChip(
              label: const Text('۳ راند ۲ دقیقه'),
              onPressed: () => _preset(3, 120, 60),
            ),
            ActionChip(
              label: const Text('۵ راند ۳ دقیقه'),
              onPressed: () => _preset(5, 180, 60),
            ),
            ActionChip(
              label: const Text('اینتروال ۸×۳۰ ثانیه'),
              onPressed: () => _preset(8, 30, 15),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _stepRow(
          label: 'تعداد راند',
          value: toFa(_rounds),
          onMinus: _rounds > 1 ? () => setState(() => _rounds--) : null,
          onPlus: _rounds < 20 ? () => setState(() => _rounds++) : null,
        ),
        _stepRow(
          label: 'مدت هر راند',
          value: _mmss(_workSeconds),
          onMinus: _workSeconds > 15
              ? () => setState(() => _workSeconds -= 15)
              : null,
          onPlus: _workSeconds < 600
              ? () => setState(() => _workSeconds += 15)
              : null,
        ),
        _stepRow(
          label: 'استراحت بین راندها',
          value: _mmss(_restSeconds),
          onMinus: _restSeconds > 0
              ? () => setState(() => _restSeconds -= 15)
              : null,
          onPlus: _restSeconds < 300
              ? () => setState(() => _restSeconds += 15)
              : null,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: Text(_phase == _Phase.done ? 'شروع دوباره' : 'شروع'),
        ),
        const SizedBox(height: 8),
        Text(
          'قبل از اولین راند ${toFa(_warmupSeconds)} ثانیه آماده‌سازی دارد. '
          'تا وقتی تایمر کار می‌کند صفحه روشن می‌ماند.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ---------- در حال اجرا ----------

  Widget _buildRunning(BuildContext context) {
    final theme = Theme.of(context);
    final Color tint;
    final String label;
    switch (_phase) {
      case _Phase.warmup:
        tint = Colors.amber;
        label = 'آماده باش';
      case _Phase.work:
        tint = Colors.redAccent;
        label = 'راند ${toFa(_round)} از ${toFa(_rounds)}';
      case _Phase.rest:
        tint = Colors.green;
        label = 'استراحت';
      case _Phase.idle:
      case _Phase.done:
        tint = Colors.grey;
        label = '';
    }

    final total = _durationOf(_phase).inMilliseconds;
    final progress =
        total == 0 ? 0.0 : 1 - (_remaining.inMilliseconds / total).clamp(0.0, 1.0);
    final seconds = (_remaining.inMilliseconds / 1000).ceil();

    return Container(
      color: tint.withValues(alpha: 0.18),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: tint,
            ),
          ),
          if (_phase == _Phase.rest)
            Text('بعدی: راند ${toFa(_round + 1)}',
                style: theme.textTheme.bodyMedium),
          const SizedBox(height: 24),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              _mmss(seconds),
              style: const TextStyle(fontSize: 110, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: progress, minHeight: 10, color: tint),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
                  onPressed: _togglePause,
                  icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                  label: Text(_paused ? 'ادامه' : 'توقف'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
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
