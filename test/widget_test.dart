import 'package:carcare/aplicativo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    // Renderiza o AplicativoCarCare com erro simulado para não precisar do Firebase no teste
    await tester.pumpWidget(const AplicativoCarCare(erroFirebase: 'Erro de teste'));

    // Verifica que a tela de aviso é exibida
    expect(find.textContaining('Erro'), findsOneWidget);
  });
}
