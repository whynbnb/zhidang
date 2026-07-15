import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zhidang/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('值当 app loads', (tester) async {
    await tester.pumpWidget(const ZhidangApp());
    await tester.pumpAndSettle();
    expect(find.text('值当'), findsOneWidget);
  });
}
