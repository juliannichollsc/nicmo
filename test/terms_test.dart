import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nicmo/il8n/app_localizations.dart';
import 'package:nicmo/screens/legal/terms.dart';

void main() {
  testWidgets('the terms open from the notice and cover the key points', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340); // 360 x 780 dp
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: GoRouter(
          initialLocation: '/home',
          routes: [
            GoRoute(
              path: '/home',
              builder: (_, _) => const Scaffold(
                body: Center(child: TermsNotice(color: Colors.black)),
              ),
            ),
            GoRoute(path: '/terms', builder: (_, _) => const TermsScreen()),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Términos y condiciones'));
    await tester.pumpAndSettle();
    expect(find.text('EN RESUMEN'), findsOneWidget);
    expect(find.textContaining('no vendemos tus datos'), findsOneWidget);

    // Every section is reachable by scrolling, and nothing overflows.
    for (final title in [
      '3. De dónde salen las rutas',
      '5. Tu seguridad y tu salud',
      '6. Tus datos personales',
      '7. Publicidad y notificaciones',
      '10. Ley aplicable',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 300);
      expect(find.text(title), findsOneWidget);
    }
    await tester.scrollUntilVisible(find.text('Entendido'), 300);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.byType(TermsNotice), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
