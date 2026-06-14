import 'package:flutter_test/flutter_test.dart';

import 'package:doorka/main.dart';

void main() {
  testWidgets('Doorka app can be created', (WidgetTester tester) async {
    expect(const DoorkaApp(), isA<DoorkaApp>());
  });
}
