import 'dart:async';
import 'package:flipoff/game/audio_controller.dart';

/// Global test configuration executed by the flutter_test runner.
///
/// Disables the audio controller globally to prevent platform channel hangs
/// during automated widget testing.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GameAudioController.enableAudio = false;
  await testMain();
}
