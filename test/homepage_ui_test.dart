import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gpt_vision_leaf_detect/screens/homepage.dart';

void main() {
  testWidgets('home screen presents the Thai-first plant analysis flow',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );

    expect(find.text('Plant Disease AI'), findsOneWidget);
    expect(find.text('ตรวจโรคพืชด้วย AI'), findsOneWidget);
    expect(find.text('เลือกภาพ'), findsOneWidget);
    expect(find.text('เปิดกล้อง'), findsOneWidget);
    expect(find.text('ยังไม่ได้เลือกภาพ'), findsOneWidget);
    expect(find.text('เลือกภาพใบพืชเพื่อเริ่มตรวจ'), findsOneWidget);
    expect(find.byTooltip('เปิดประวัติการตรวจ'), findsOneWidget);
  });

  testWidgets('history action opens the history page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );

    await tester.tap(find.byTooltip('เปิดประวัติการตรวจ'));
    await tester.pumpAndSettle();

    expect(find.text('ประวัติการตรวจ'), findsOneWidget);
    expect(find.text('โรคสแคปแอปเปิ้ล'), findsOneWidget);
  });
}
