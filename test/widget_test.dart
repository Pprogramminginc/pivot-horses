import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pivot_horses/app/backend/app_bootstrap.dart';
import 'package:pivot_horses/app/app.dart';
import 'package:pivot_horses/app/theme/app_theme.dart';
import 'package:pivot_horses/data/sample/sample_horses.dart';
import 'package:pivot_horses/presentation/screens/catalog_screen.dart';
import 'package:pivot_horses/presentation/screens/market_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders Pivot Horses auth screen', (tester) async {
    SharedPreferences.setMockInitialValues(const {});

    await tester.pumpWidget(
      const PivotHorsesApp(
        bootstrap: AppBootstrap(
          mode: BackendMode.local,
          supabaseUrl: '',
          supabaseAnonKey: '',
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Pivot Horses'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('market expansion tier card fits on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final stableHorses = List.generate(12, (index) {
      final horse = starterMarketHorses[index % starterMarketHorses.length];
      return horse.copyWith(
        id: '${horse.id}_stable_$index',
        registryId: '${horse.registryId}-$index',
        currentName: '${horse.currentName} $index',
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: MarketScreen(
          stableHorses: stableHorses,
          marketHorses: starterMarketHorses,
          currentTime: DateTime(2026, 4, 28),
          coinBalance: 10000,
          onPurchaseHorse: (_, _, _) {},
          stableCount: stableHorses.length,
          stableCap: 25,
          slotsRemaining: 13,
          stableExpansionTier: 1,
          stableCapacityRenewsAt: DateTime(2026, 5, 1),
          onPurchaseStoreItem: (_) {},
        ),
      ),
    );

    await tester.tap(find.text('Items').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tier 2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Renew soon'), findsOneWidget);
    expect(find.textContaining('Expiration preview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('catalog monthly rules page fits on a narrow phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: const Scaffold(body: CatalogScreen(embedded: true)),
      ),
    );

    await tester.ensureVisible(find.text('Monthly Rules'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly Rules'));
    await tester.pumpAndSettle();

    expect(find.text('Monthly Rules'), findsWidgets);
    expect(
      find.textContaining('Any active breeding, pregnancy, or cooldown'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
