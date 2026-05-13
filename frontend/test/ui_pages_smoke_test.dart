import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snaprep/main.dart';

void main() {
  Future<void> pumpMobilePage(
      WidgetTester tester, String label, Widget page) async {
    tester.binding.window.physicalSizeTestValue = const Size(470, 900);
    tester.binding.window.devicePixelRatioTestValue = 1;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: page),
    ));
    await tester.pumpAndSettle();

    // Rendering exceptions, including overflows, are surfaced by flutter_test.
  }

  testWidgets('all SnapRep prototype pages render in mobile viewport',
      (tester) async {
    await pumpMobilePage(tester, 'home', HomeScreen(onCamera: () {}));
    await pumpMobilePage(tester, 'guide step 1', const GuideStep1Screen());
    await pumpMobilePage(tester, 'guide step 2', const GuideStep2Screen());
    await pumpMobilePage(tester, 'guide step 3', const GuideStep3Screen());
    await pumpMobilePage(tester, 'workout result', const WorkoutResultScreen());
    await pumpMobilePage(
        tester, 'training practice', const TrainingPracticeScreen());
    await pumpMobilePage(tester, 'result card', const ResultCardScreen());
    await pumpMobilePage(tester, 'profile', ProfileScreen(onHistory: () {}));
    await pumpMobilePage(tester, 'history', const HistoryScreen());
    await pumpMobilePage(tester, 'camera', const CameraScreen(showBack: true));
  });

  testWidgets('camera page switches from scan to recognition state',
      (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(470, 900);
    tester.binding.window.devicePixelRatioTestValue = 1;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: CameraScreen(showBack: true)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(CameraCaptureDock), findsOneWidget);
    await tester.tap(find.byType(CameraCaptureDock));
    await tester.pumpAndSettle();

    expect(find.byType(RecognitionSheet), findsOneWidget);
  });

  testWidgets('start follow button opens training flow', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(470, 900);
    tester.binding.window.devicePixelRatioTestValue = 1;
    addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

    await tester.pumpWidget(const MaterialApp(home: WorkoutResultScreen()));
    await tester.tap(find.byType(CyanButton).last);
    await tester.pumpAndSettle();

    expect(find.byType(TrainingPracticeScreen), findsOneWidget);
    expect(find.byType(PracticeDetailsPanel), findsOneWidget);

    await tester.tap(find.byIcon(Icons.skip_next_rounded));
    await tester.pumpAndSettle();

    expect(find.byType(PracticeProgressPanel), findsOneWidget);
  });
}
