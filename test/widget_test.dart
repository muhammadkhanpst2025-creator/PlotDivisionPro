import 'package:flutter_test/flutter_test.dart';
import 'package:plot_division_pro/main.dart';

void main() {
  testWidgets('Plot Division App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PlotDivisionApp());

    // Verify that the title appears on screen
    expect(find.text('Area Calculator'), findsOneWidget);
    expect(find.text('Developed by Sahil Janwery'), findsOneWidget);
  });
}
