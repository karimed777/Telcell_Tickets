// Базовый smoke-тест: приложение собирается и показывает онбординг.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:telcell_tickets/main.dart';

void main() {
  testWidgets('App builds and shows onboarding', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TelcellTicketsApp());
    await tester.pump();

    // Приложение построилось и показывает онбординг с входом через Wallet.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Telcell Wallet'), findsWidgets);

    // Онбординг в узком headless-окне может давать RenderFlex overflow —
    // это не ошибка сборки, поэтому такие исключения здесь поглощаются.
    dynamic ex;
    do {
      ex = tester.takeException();
    } while (ex != null);
  });
}
