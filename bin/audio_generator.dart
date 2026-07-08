// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  print('Generating retro audio files in assets/audio...');

  // Generate 6 music loops
  for (int i = 1; i <= 6; i++) {
    final path = 'assets/audio/loop_$i.wav';
    generateRockLoop(path, i * 73);
    print('Generated $path');
  }

  // Generate SFX
  generateFlipperSfx('assets/audio/sfx_flipper.wav');
  generateBumperSfx('assets/audio/sfx_bumper.wav');
  generateTargetSfx('assets/audio/sfx_target.wav');
  generateGutterSfx('assets/audio/sfx_gutter.wav');
  print('Generated all SFX files!');
}

/// Helper to write standard WAV RIFF header and return the PCM bytes builder.
BytesBuilder createWavHeader(int sampleRate, int dataSize) {
  final builder = BytesBuilder();
  final fileLength = dataSize + 36;

  // RIFF descriptor
  builder.add('RIFF'.codeUnits);
  builder.add([fileLength & 0xFF, (fileLength >> 8) & 0xFF, (fileLength >> 16) & 0xFF, (fileLength >> 24) & 0xFF]);
  builder.add('WAVE'.codeUnits);

  // FMT sub-chunk
  builder.add('fmt '.codeUnits);
  builder.add([16, 0, 0, 0]); // Sub-chunk size (16)
  builder.add([1, 0]); // Audio format (1 = PCM)
  builder.add([1, 0]); // Channels (1 = mono)
  // Sample rate
  builder.add([sampleRate & 0xFF, (sampleRate >> 8) & 0xFF, (sampleRate >> 16) & 0xFF, (sampleRate >> 24) & 0xFF]);
  // Byte rate = sampleRate * 1 (channels) * 1 (1 byte per sample)
  builder.add([sampleRate & 0xFF, (sampleRate >> 8) & 0xFF, (sampleRate >> 16) & 0xFF, (sampleRate >> 24) & 0xFF]);
  builder.add([1, 0]); // Block align
  builder.add([8, 0]); // Bits per sample (8)

  // DATA sub-chunk
  builder.add('data'.codeUnits);
  builder.add([dataSize & 0xFF, (dataSize >> 8) & 0xFF, (dataSize >> 16) & 0xFF, (dataSize >> 24) & 0xFF]);

  return builder;
}

/// Generates a driving retro rock loop.
void generateRockLoop(String path, int seed) {
  const sampleRate = 11025;
  const duration = 4.0; // 4 seconds
  const numSamples = (sampleRate * duration);
  final random = math.Random(seed);

  // Key frequencies
  final List<double> bassNotes = [55.0, 65.4, 73.4, 82.4]; // A1, C2, D2, E2
  final List<double> leadNotes = [220.0, 261.6, 293.7, 329.6, 392.0]; // A3 pentatonic scale

  final bpm = 125;
  final beatDuration = 60.0 / bpm; // 0.48 seconds
  final samplesPerBeat = (sampleRate * beatDuration).toInt();

  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final beat = i ~/ samplesPerBeat;
    final beatProgress = (i % samplesPerBeat) / samplesPerBeat;

    // 1. Driving Rock Bass (Square wave with warm filter-like vibe)
    final bassFreq = bassNotes[(beat ~/ 2) % bassNotes.length];
    final bassVal = math.sin(2.0 * math.pi * bassFreq * t) >= 0 ? 1.0 : -1.0;

    // 2. High Lead Rock Guitar riff (Aggressive distorted Sawtooth wave)
    final melodyStep = (beat * 2 + (beat % 3)) % leadNotes.length;
    final leadFreq = leadNotes[melodyStep];
    final leadVal = ((t * leadFreq) % 1.0) * 2.0 - 1.0;

    // 3. Simple retro drums (hi-hat, kick, snare)
    double drumVal = 0.0;
    // Kick drum: rapid exponential frequency sweep
    if (beat % 2 == 0) {
      final kickT = beatProgress * beatDuration;
      drumVal += math.sin(2.0 * math.pi * 70.0 * math.exp(-18.0 * kickT)) * math.exp(-6.0 * kickT);
    }
    // Snare drum: white noise burst decay
    if (beat % 2 == 1) {
      final snareT = beatProgress * beatDuration;
      drumVal += (random.nextDouble() * 2.0 - 1.0) * math.exp(-10.0 * snareT);
    }
    // Hi-hat click: short white noise
    final hatSubBeat = (i % (samplesPerBeat ~/ 2)) / (samplesPerBeat ~/ 2);
    drumVal += (random.nextDouble() * 2.0 - 1.0) * 0.12 * math.exp(-45.0 * hatSubBeat);

    // Mix channels
    double mixed = (bassVal * 0.35) + (leadVal * 0.18) + (drumVal * 0.35);
    mixed = mixed.clamp(-1.0, 1.0);

    // Convert to 8-bit unsigned PCM
    final byteVal = ((mixed + 1.0) * 127.5).toInt().clamp(0, 255);
    pcmBytes.addByte(byteVal);
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());

  File(path).writeAsBytesSync(header.takeBytes());
}

/// Snappy upward spring SFX for flippers.
void generateFlipperSfx(String path) {
  const sampleRate = 11025;
  const duration = 0.15;
  const numSamples = (sampleRate * duration);
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    // Sweep frequency from 150Hz to 550Hz
    final freq = 150.0 + (t / duration) * 400.0;
    final val = math.sin(2.0 * math.pi * freq * t) * (1.0 - t / duration);

    final byteVal = ((val + 1.0) * 127.5).toInt().clamp(0, 255);
    pcmBytes.addByte(byteVal);
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
}

/// Descending ringing pitch for bumper hits.
void generateBumperSfx(String path) {
  const sampleRate = 11025;
  const duration = 0.25;
  const numSamples = (sampleRate * duration);
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    // Vibrato chime that decays
    final freq = 600.0 * math.exp(-5.0 * t);
    final val = math.sin(2.0 * math.pi * freq * t + math.sin(30.0 * t)) * math.exp(-8.0 * t);

    final byteVal = ((val + 1.0) * 127.5).toInt().clamp(0, 255);
    pcmBytes.addByte(byteVal);
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
}

/// High-pitched coin pickup chime for target hits.
void generateTargetSfx(String path) {
  const sampleRate = 11025;
  const duration = 0.3;
  const numSamples = (sampleRate * duration);
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    // Play 987 Hz (B5) for first half, then 1318 Hz (E6) for second half
    final freq = t < (duration / 2.0) ? 987.77 : 1318.51;
    final val = math.sin(2.0 * math.pi * freq * t) * math.exp(-12.0 * t);

    final byteVal = ((val + 1.0) * 127.5).toInt().clamp(0, 255);
    pcmBytes.addByte(byteVal);
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
}

/// Down-sweeping rumble crash for gutter loss.
void generateGutterSfx(String path) {
  const sampleRate = 11025;
  const duration = 0.5;
  const numSamples = (sampleRate * duration);
  final random = math.Random();
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    // Descending rumble base mixed with noise
    final freq = 120.0 * (1.0 - t / duration);
    final tone = math.sin(2.0 * math.pi * freq * t);
    final noise = random.nextDouble() * 2.0 - 1.0;
    
    final val = (tone * 0.4 + noise * 0.6) * (1.0 - t / duration);

    final byteVal = ((val + 1.0) * 127.5).toInt().clamp(0, 255);
    pcmBytes.addByte(byteVal);
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
}
