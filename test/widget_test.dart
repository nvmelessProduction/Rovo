// Smoke test di base per Rova: verifica che l'app si avvii e mostri
// la barra di navigazione con le tre schede.

import 'package:flutter_test/flutter_test.dart';

import 'package:rova/main.dart';

void main() {
  testWidgets('L\'app si avvia e mostra le 3 schede', (WidgetTester tester) async {
    await tester.pumpWidget(const RovaApp());
    await tester.pump();

    // La barra di navigazione ha Mappa, Turismo e Carburante.
    expect(find.text('Mappa'), findsOneWidget);
    expect(find.text('Turismo'), findsWidgets);
    expect(find.text('Carburante'), findsWidgets);
  });
}
