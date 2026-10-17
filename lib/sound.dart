import 'package:audioplayers/audioplayers.dart';

/// Timer sounds. Every call is fail-safe: a missing audio engine must never
/// break the timer.
class Sfx {
  static final Map<String, AudioPlayer> _players = {};
  static bool _ready = false;

  /// 10-second warning (two wooden clacks).
  static Future<void> warn() => _play('warn');

  /// Round starts.
  static Future<void> bellStart() => _play('bell_start');

  /// Round ends (three bell strikes).
  static Future<void> bellEnd() => _play('bell_end');

  static Future<void> _setup() async {
    if (_ready) return;
    _ready = true;
    try {
      // Mix with the user's music instead of stopping it.
      await AudioPlayer.global.setAudioContext(AudioContext(
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.sonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ));
    } catch (_) {}
  }

  static Future<void> _play(String name) async {
    try {
      await _setup();
      final p = _players.putIfAbsent(name, () => AudioPlayer());
      await p.stop();
      await p.play(AssetSource('sounds/$name.wav'), volume: 1.0);
    } catch (_) {}
  }
}
