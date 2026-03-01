import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AvtoVodiyApp());
    expect(find.text('Avto Vodiy'), findsOneWidget);
  });
}
