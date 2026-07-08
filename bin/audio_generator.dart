// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  print('Generating high-quality fun retro rock/pop loops and SFX in assets/audio...');

  // Generate 6 distinct fun music loops (120 BPM, 32 beats = 16.0 seconds, 22.05 kHz)
  generateLoop1('assets/audio/loop_1.wav');
  generateLoop2('assets/audio/loop_2.wav');
  generateLoop3('assets/audio/loop_3.wav');
  generateLoop4('assets/audio/loop_4.wav');
  generateLoop5('assets/audio/loop_5.wav');
  generateLoop6('assets/audio/loop_6.wav');

  // Generate SFX
  generateFlipperSfx('assets/audio/sfx_flipper.wav');
  generateBumperSfx('assets/audio/sfx_bumper.wav');
  generateTargetSfx('assets/audio/sfx_target.wav');
  generateGutterSfx('assets/audio/sfx_gutter.wav');
  print('Generated all retro audio assets successfully!');
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

/// Helper to generate a clean triangle wave (pleasant retro synth lead)
double getTriangleWave(double t, double freq) {
  final double phase = (t * freq) % 1.0;
  return phase < 0.5 ? 4.0 * phase - 1.0 : 3.0 - 4.0 * phase;
}

/// Loop 1: Upbeat Arena Rock (C Major) - Bright chord runs, bouncing bass line
void generateLoop1(String path) {
  const sampleRate = 22050; // Decades ahead of 8kHz! Warm & crystal clear
  const duration = 16.0;
  const numSamples = (sampleRate * duration);
  final List<double> bassNotes = [130.81, 146.83, 164.81, 196.00]; // C3, D3, E3, G3
  final List<double> melodyNotes = [261.63, 293.66, 329.63, 392.00, 440.00]; // C4, D4, E4, G4, A4 (Pentatonic Major)
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final beat = (t * 2.0).floor(); // 120 BPM
    final beatProgress = (t * 2.0) % 1.0;

    // Warm Sine Bass
    final bassFreq = bassNotes[(beat ~/ 4) % bassNotes.length];
    final bassVal = math.sin(2.0 * math.pi * bassFreq * t);

    // Fun Triangle Lead
    final melodyFreq = melodyNotes[(beat * 3) % melodyNotes.length];
    final leadVal = getTriangleWave(t, melodyFreq);

    // Bouncy Rock Kick-Snare
    double drumVal = 0.0;
    if (beat % 2 == 0) {
      drumVal += math.sin(2.0 * math.pi * 75.0 * math.exp(-22.0 * beatProgress)) * math.exp(-6.0 * beatProgress);
    } else {
      // Soft snappy snare decay
      drumVal += math.sin(2.0 * math.pi * 220.0 * math.exp(-30.0 * beatProgress)) * 0.4 * math.exp(-12.0 * beatProgress);
    }

    double mixed = (bassVal * 0.4) + (leadVal * 0.25) + (drumVal * 0.35);
    mixed = mixed.clamp(-1.0, 1.0);
    pcmBytes.addByte(((mixed + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}

/// Loop 2: Power-Pop Anthem (G Major) - Melodic chord walk, energetic tempo
void generateLoop2(String path) {
  const sampleRate = 22050;
  const duration = 16.0;
  const numSamples = (sampleRate * duration);
  final List<double> bassNotes = [196.00, 220.00, 246.94, 293.66]; // G3, A3, B3, D3
  final List<double> melodyNotes = [392.00, 440.00, 493.88, 587.33]; // G4, A4, B4, D5
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final beat = (t * 2.2).floor(); // 132 BPM
    final beatProgress = (t * 2.2) % 1.0;

    final bassFreq = bassNotes[(beat ~/ 2) % bassNotes.length];
    final bassVal = math.sin(2.0 * math.pi * bassFreq * t);

    final melodyFreq = melodyNotes[(beat * 2 + 1) % melodyNotes.length];
    final leadVal = getTriangleWave(t, melodyFreq);

    double drumVal = 0.0;
    // Kick drum
    drumVal += math.sin(2.0 * math.pi * 80.0 * math.exp(-25.0 * beatProgress)) * math.exp(-5.0 * beatProgress);

    double mixed = (bassVal * 0.4) + (leadVal * 0.25) + (drumVal * 0.3);
    mixed = mixed.clamp(-1.0, 1.0);
    pcmBytes.addByte(((mixed + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}

/// Loop 3: Surf Rock Wave (F Major) - Happy sliding melody, double hi-hats
void generateLoop3(String path) {
  const sampleRate = 22050;
  const duration = 16.0;
  const numSamples = (sampleRate * duration);
  final List<double> bassNotes = [174.61, 196.00, 220.00, 261.63]; // F3, G3, A3, C4
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final beat = (t * 2.0).floor();
    final beatProgress = (t * 2.0) % 1.0;

    final bassFreq = bassNotes[(beat ~/ 4) % bassNotes.length];
    final bassVal = math.sin(2.0 * math.pi * bassFreq * t);

    // Sliding lead melody (pleasant slide)
    final slideFreq = 349.23 + 50.0 * math.sin(2.0 * math.pi * t);
    final leadVal = getTriangleWave(t, slideFreq) * 0.25;

    double drumVal = 0.0;
    if (beat % 2 == 0) {
      drumVal += math.sin(2.0 * math.pi * 70.0 * math.exp(-20.0 * beatProgress)) * math.exp(-6.0 * beatProgress);
    }
    // double hi-hat click
    final hatSub = (t * 8.0) % 1.0;
    drumVal += (math.sin(1500.0 * hatSub) * 0.1 * math.exp(-40.0 * hatSub));

    double mixed = (bassVal * 0.4) + leadVal + (drumVal * 0.35);
    mixed = mixed.clamp(-1.0, 1.0);
    pcmBytes.addByte(((mixed + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}

/// Loop 4: Arcade Synth Jam (A Major) - Retro chiptune arpeggio, bouncy bass
void generateLoop4(String path) {
  const sampleRate = 22050;
  const duration = 16.0;
  const numSamples = (sampleRate * duration);
  final List<double> notes = [220.00, 277.18, 329.63, 440.00]; // A3, C#4, E4, A4 arpeggio
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final step = (t * 8.0).floor(); // 8 steps per second
    final beat = (t * 2.0).floor();
    final beatProgress = (t * 2.0) % 1.0;

    final arpFreq = notes[step % notes.length];
    final arpVal = getTriangleWave(t, arpFreq);

    final bassVal = math.sin(2.0 * math.pi * 110.0 * t);

    double drumVal = 0.0;
    if (beat % 2 == 0) {
      drumVal += math.sin(2.0 * math.pi * 75.0 * math.exp(-22.0 * beatProgress)) * math.exp(-5.0 * beatProgress);
    }

    double mixed = (arpVal * 0.28) + (bassVal * 0.4) + (drumVal * 0.3);
    mixed = mixed.clamp(-1.0, 1.0);
    pcmBytes.addByte(((mixed + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}

/// Loop 5: Sunset Cruise (D Major) - Warm triangle melody, upbeat shuffle
void generateLoop5(String path) {
  const sampleRate = 22050;
  const duration = 16.0;
  const numSamples = (sampleRate * duration);
  final List<double> melody = [293.66, 329.63, 369.99, 440.00, 587.33]; // D4, E4, F#4, A4, D5
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final beat = (t * 2.0).floor();
    final beatProgress = (t * 2.0) % 1.0;

    final melodyFreq = melody[(beat * 3) % melody.length];
    final leadVal = getTriangleWave(t, melodyFreq) * 0.25;

    final bassVal = math.sin(2.0 * math.pi * 146.83 * t) * 0.4;

    double drumVal = 0.0;
    if (beat % 2 == 0) {
      drumVal += math.sin(2.0 * math.pi * 70.0 * math.exp(-20.0 * beatProgress)) * math.exp(-6.0 * beatProgress);
    }

    double mixed = leadVal + bassVal + (drumVal * 0.35);
    mixed = mixed.clamp(-1.0, 1.0);
    pcmBytes.addByte(((mixed + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}

/// Loop 6: Happy Carnival Riff (F Major) - Bouncy bell lead, syncopated ride
void generateLoop6(String path) {
  const sampleRate = 22050;
  const duration = 16.0;
  const numSamples = (sampleRate * duration);
  final List<double> notes = [349.23, 392.00, 440.00, 523.25]; // F4, G4, A4, C5
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final beat = (t * 2.4).floor();
    final beatProgress = (t * 2.4) % 1.0;

    final melodyFreq = notes[(beat * 2) % notes.length];
    final leadVal = getTriangleWave(t, melodyFreq) * 0.28;

    final bassVal = math.sin(2.0 * math.pi * 174.61 * t) * 0.4;

    double drumVal = 0.0;
    drumVal += math.sin(2.0 * math.pi * 80.0 * math.exp(-22.0 * beatProgress)) * math.exp(-5.0 * beatProgress);

    double mixed = leadVal + bassVal + (drumVal * 0.3);
    mixed = mixed.clamp(-1.0, 1.0);
    pcmBytes.addByte(((mixed + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}

/// Flipper spring SFX (no unused variables).
void generateFlipperSfx(String path) {
  const sampleRate = 22050;
  const duration = 0.12;
  const numSamples = (sampleRate * duration);
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final freq = 180.0 + (t / duration) * 350.0;
    final val = math.sin(2.0 * math.pi * freq * t) * (1.0 - t / duration);

    pcmBytes.addByte(((val + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}

/// Bumper chime SFX (no unused variables).
void generateBumperSfx(String path) {
  const sampleRate = 22050;
  const duration = 0.22;
  const numSamples = (sampleRate * duration);
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final freq = 550.0 * math.exp(-6.0 * t);
    final val = math.sin(2.0 * math.pi * freq * t + math.sin(25.0 * t)) * math.exp(-6.0 * t);

    pcmBytes.addByte(((val + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}

/// Target coin ping SFX (no unused variables).
void generateTargetSfx(String path) {
  const sampleRate = 22050;
  const duration = 0.25;
  const numSamples = (sampleRate * duration);
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final freq = t < (duration / 2.0) ? 987.77 : 1318.51;
    final val = math.sin(2.0 * math.pi * freq * t) * math.exp(-10.0 * t);

    pcmBytes.addByte(((val + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}

/// Gutter crash rumble SFX (no unused variables).
void generateGutterSfx(String path) {
  const sampleRate = 22050;
  const duration = 0.45;
  const numSamples = (sampleRate * duration);
  final random = math.Random();
  final pcmBytes = BytesBuilder();

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;
    final freq = 130.0 * (1.0 - t / duration);
    final tone = math.sin(2.0 * math.pi * freq * t);
    final noise = random.nextDouble() * 2.0 - 1.0;
    final val = (tone * 0.4 + noise * 0.6) * (1.0 - t / duration);

    pcmBytes.addByte(((val + 1.0) * 127.5).toInt().clamp(0, 255));
  }

  final header = createWavHeader(sampleRate, pcmBytes.length);
  header.add(pcmBytes.takeBytes());
  File(path).writeAsBytesSync(header.takeBytes());
  print('Generated $path');
}
