import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Captures raw PCM audio at 8000 Hz, 16-bit mono.
///
/// [startCapture] returns a [Stream<Int16List>] that emits chunks of PCM
/// samples every [chunkDuration].  Call [stopCapture] to end recording.
class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  StreamController<Int16List>? _controller;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  /// Request microphone permission.  Returns true if granted.
  Future<bool> requestPermission() async {
    return _recorder.hasPermission();
  }

  /// Start capturing PCM audio.
  ///
  /// [chunkDuration] controls how often samples are emitted (default 1 s).
  /// [enableBandPassFilter] applies voice-tuned band-pass filtering when true.
  /// The returned stream emits [Int16List] chunks that are ready for Codec2 encoding.
  Stream<Int16List> startCapture({
    Duration chunkDuration = const Duration(seconds: 1),
    bool enableBandPassFilter = true,
  }) {
    if (_isRecording) {
      throw StateError('VoiceRecorderService: already recording');
    }

    _controller = StreamController<Int16List>(
      onCancel: () => _stopInternal(),
    );
    _isRecording = true;

    _startRecording(
      chunkDuration,
      enableBandPassFilter: enableBandPassFilter,
    );
    return _controller!.stream;
  }

  Future<void> _startRecording(
    Duration chunkDuration, {
    required bool enableBandPassFilter,
  }) async {
    final config = const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 8000,
      numChannels: 1,
      bitRate: 128000, // ignored for PCM, but required by API
    );

    try {
      final stream = await _recorder.startStream(config);
      final voiceFilter = _VoiceBandPassFilter(
        sampleRate: 8000,
        lowCutHz: 250.0,
        highCutHz: 3400.0,
      );
      final chunkBytes = 8000 * 2 * chunkDuration.inMilliseconds ~/ 1000;
      final buffer = <int>[];

      _sub = stream.listen(
        (data) {
          buffer.addAll(data);
          while (buffer.length >= chunkBytes) {
            final chunk = buffer.sublist(0, chunkBytes);
            buffer.removeRange(0, chunkBytes);
            final pcm = _bytesToInt16(Uint8List.fromList(chunk));
            _controller?.add(
              enableBandPassFilter ? voiceFilter.process(pcm) : pcm,
            );
          }
        },
        onDone: () {
          if (buffer.isNotEmpty) {
            final padded = _padToEven(buffer);
            final pcm = _bytesToInt16(Uint8List.fromList(padded));
            _controller?.add(
              enableBandPassFilter ? voiceFilter.process(pcm) : pcm,
            );
          }
          _controller?.close();
        },
        onError: (e) {
          debugPrint('❌ [VoiceRecorder] Stream error: $e');
          _controller?.addError(e);
          _controller?.close();
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('❌ [VoiceRecorder] Failed to start: $e');
      _isRecording = false;
      _controller?.addError(e);
      _controller?.close();
    }
  }

  /// Stop recording and flush remaining samples.
  Future<void> stopCapture() async {
    await _stopInternal();
  }

  Future<void> _stopInternal() async {
    if (!_isRecording) return;
    _isRecording = false;
    await _sub?.cancel();
    _sub = null;
    await _recorder.stop();
  }

  void dispose() {
    _stopInternal();
    _recorder.dispose();
  }

  /// Convert raw little-endian PCM bytes to Int16List.
  static Int16List _bytesToInt16(Uint8List bytes) {
    final bd = ByteData.sublistView(bytes);
    final samples = Int16List(bytes.length ~/ 2);
    for (var i = 0; i < samples.length; i++) {
      samples[i] = bd.getInt16(i * 2, Endian.little);
    }
    return samples;
  }

  static List<int> _padToEven(List<int> buf) {
    if (buf.length % 2 != 0) buf.add(0);
    return buf;
  }
}

/// Band-pass filter tuned for human voice at 8 kHz input.
///
/// Uses a cascaded high-pass + low-pass biquad to attenuate very low-frequency
/// rumble and high-frequency noise outside the speech band.
class _VoiceBandPassFilter {
  final _BiquadFilter _highPass;
  final _BiquadFilter _lowPass;

  _VoiceBandPassFilter({
    required int sampleRate,
    required double lowCutHz,
    required double highCutHz,
  })  : _highPass = _BiquadFilter.highPass(
          sampleRate: sampleRate.toDouble(),
          cutoffHz: lowCutHz,
        ),
        _lowPass = _BiquadFilter.lowPass(
          sampleRate: sampleRate.toDouble(),
          cutoffHz: highCutHz,
        );

  Int16List process(Int16List input) {
    final output = Int16List(input.length);
    for (var i = 0; i < input.length; i++) {
      var sample = input[i].toDouble();
      sample = _highPass.process(sample);
      sample = _lowPass.process(sample);
      output[i] = sample.clamp(-32768.0, 32767.0).round();
    }
    return output;
  }
}

/// Standard biquad IIR filter (Direct Form I).
class _BiquadFilter {
  final double _b0;
  final double _b1;
  final double _b2;
  final double _a1;
  final double _a2;

  double _x1 = 0.0;
  double _x2 = 0.0;
  double _y1 = 0.0;
  double _y2 = 0.0;

  _BiquadFilter._({
    required double b0,
    required double b1,
    required double b2,
    required double a1,
    required double a2,
  })  : _b0 = b0,
        _b1 = b1,
        _b2 = b2,
        _a1 = a1,
        _a2 = a2;

  factory _BiquadFilter.lowPass({
    required double sampleRate,
    required double cutoffHz,
  }) {
    const q = math.sqrt1_2; // Butterworth response (Q = 1/sqrt(2))
    final omega = 2.0 * math.pi * cutoffHz / sampleRate;
    final cosOmega = math.cos(omega);
    final alpha = math.sin(omega) / (2.0 * q);

    final b0 = (1.0 - cosOmega) / 2.0;
    final b1 = 1.0 - cosOmega;
    final b2 = (1.0 - cosOmega) / 2.0;
    final a0 = 1.0 + alpha;
    final a1 = -2.0 * cosOmega;
    final a2 = 1.0 - alpha;

    return _BiquadFilter._(
      b0: b0 / a0,
      b1: b1 / a0,
      b2: b2 / a0,
      a1: a1 / a0,
      a2: a2 / a0,
    );
  }

  factory _BiquadFilter.highPass({
    required double sampleRate,
    required double cutoffHz,
  }) {
    const q = math.sqrt1_2; // Butterworth response (Q = 1/sqrt(2))
    final omega = 2.0 * math.pi * cutoffHz / sampleRate;
    final cosOmega = math.cos(omega);
    final alpha = math.sin(omega) / (2.0 * q);

    final b0 = (1.0 + cosOmega) / 2.0;
    final b1 = -(1.0 + cosOmega);
    final b2 = (1.0 + cosOmega) / 2.0;
    final a0 = 1.0 + alpha;
    final a1 = -2.0 * cosOmega;
    final a2 = 1.0 - alpha;

    return _BiquadFilter._(
      b0: b0 / a0,
      b1: b1 / a0,
      b2: b2 / a0,
      a1: a1 / a0,
      a2: a2 / a0,
    );
  }

  double process(double x) {
    final y = _b0 * x + _b1 * _x1 + _b2 * _x2 - _a1 * _y1 - _a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}
