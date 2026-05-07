import 'package:audioplayers/audioplayers.dart';

enum GameSound {
  uiClick('audio/ui_click.wav', 0.34),
  breedingStart('audio/breeding_start.wav', 0.42),
  foalBirth('audio/foal_birth.wav', 0.48),
  messageSent('audio/message_sent.wav', 0.4);

  const GameSound(this.assetPath, this.volume);

  final String assetPath;
  final double volume;
}

class GameAudioService {
  GameAudioService({AudioPlayer? effectsPlayer, AudioPlayer? backgroundPlayer})
    : _effectsPlayer = effectsPlayer ?? AudioPlayer(),
      _backgroundPlayer = backgroundPlayer ?? AudioPlayer();

  static const String _backgroundAssetPath = 'audio/stable_jingle.wav';
  static const double _backgroundVolume = 1.0;

  final AudioPlayer _effectsPlayer;
  final AudioPlayer _backgroundPlayer;
  bool _audioEnabled = true;
  bool _effectsEnabled = true;
  bool _backgroundEnabled = true;
  bool _backgroundStarted = false;
  double _masterVolume = 1;
  double _effectsVolume = 1;
  double _backgroundVolumeMultiplier = 1;

  Future<void> initialize() async {
    await _effectsPlayer.setPlayerMode(PlayerMode.lowLatency);
    await _effectsPlayer.setReleaseMode(ReleaseMode.stop);
    await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);
    await _applyBackgroundVolume();
  }

  Future<void> configure({
    required bool audioEnabled,
    required bool effectsEnabled,
    required bool backgroundEnabled,
    required double masterVolume,
    required double effectsVolume,
    required double backgroundVolume,
  }) async {
    _audioEnabled = audioEnabled;
    _effectsEnabled = effectsEnabled;
    _backgroundEnabled = backgroundEnabled;
    _masterVolume = masterVolume.clamp(0, 1);
    _effectsVolume = effectsVolume.clamp(0, 1);
    _backgroundVolumeMultiplier = backgroundVolume.clamp(0, 1);
    await _applyBackgroundVolume();
    if (!_canPlayBackground) {
      await pauseBackground();
    } else if (_backgroundStarted) {
      await resumeBackground();
    }
  }

  Future<void> startBackground() async {
    if (!_canPlayBackground) {
      return;
    }
    try {
      _backgroundStarted = true;
      await _backgroundPlayer.play(AssetSource(_backgroundAssetPath));
    } catch (_) {
      // Background music is optional; the app should stay silent if needed.
    }
  }

  Future<void> pauseBackground() async {
    try {
      await _backgroundPlayer.pause();
    } catch (_) {}
  }

  Future<void> resumeBackground() async {
    if (!_canPlayBackground) {
      return;
    }
    try {
      if (_backgroundStarted) {
        await _backgroundPlayer.resume();
      } else {
        await startBackground();
      }
    } catch (_) {
      await startBackground();
    }
  }

  Future<void> play(GameSound sound) async {
    if (!_audioEnabled || !_effectsEnabled) {
      return;
    }
    try {
      await _effectsPlayer.stop();
      await _effectsPlayer.setVolume(
        sound.volume * _masterVolume * _effectsVolume,
      );
      await _effectsPlayer.play(AssetSource(sound.assetPath));
    } catch (_) {
      // Audio should never block gameplay if a device or platform refuses it.
    }
  }

  Future<void> dispose() async {
    await _effectsPlayer.dispose();
    await _backgroundPlayer.dispose();
  }

  bool get _canPlayBackground => _audioEnabled && _backgroundEnabled;

  Future<void> _applyBackgroundVolume() {
    return _backgroundPlayer.setVolume(
      _backgroundVolume * _masterVolume * _backgroundVolumeMultiplier,
    );
  }
}
