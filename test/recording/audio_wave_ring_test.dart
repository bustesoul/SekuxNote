import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sekuxnote/features/recording/widgets/audio_wave_ring.dart';

void main() {
  testWidgets('audio wave ring supports silence, sound and paused states', (
    tester,
  ) async {
    Future<void> pumpRing({required double level, bool paused = false}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AudioWaveRing(level: level, paused: paused),
            ),
          ),
        );

    await pumpRing(level: 0);
    expect(find.byKey(const Key('recording_audio_wave_ring')), findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

    await pumpRing(level: 0.8);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

    await pumpRing(level: 0.8, paused: true);
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });
}
