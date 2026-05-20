import 'package:audioplayers/audioplayers.dart';
import 'user_service.dart';

class SoundService {
  static final AudioPlayer _matchPlayer = AudioPlayer();
  static final AudioPlayer _comboPlayer = AudioPlayer();

  static Future<void> init() async {
    await _matchPlayer.setSource(AssetSource('sounds/match.wav'));
    await _comboPlayer.setSource(AssetSource('sounds/combo.wav'));
    await _matchPlayer.setVolume(0.6);
    await _comboPlayer.setVolume(0.8);
  }

  static Future<void> playMatch() async {
    if (!UserService.isSoundEnabled) return;
    await _matchPlayer.stop();
    await _matchPlayer.play(AssetSource('sounds/match.wav'));
  }

  static Future<void> playCombo() async {
    if (!UserService.isSoundEnabled) return;
    await _comboPlayer.stop();
    await _comboPlayer.play(AssetSource('sounds/combo.wav'));
  }

  static void dispose() {
    _matchPlayer.dispose();
    _comboPlayer.dispose();
  }
}
