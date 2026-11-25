
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:classnav/app.dart';
import 'package:classnav/providers/auth_provider.dart';
import 'package:classnav/providers/theme_provider.dart';
import 'package:classnav/providers/schedule_provider.dart';
import 'package:classnav/services/auth_service.dart';
import 'package:classnav/services/preferences_service.dart';
import 'package:classnav/services/database_service.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('ClassNest app loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(PreferencesService()),
          ),

          ChangeNotifierProvider(
            create: (_) => AuthProvider(
              AuthService(),
            ),
          ),

          ChangeNotifierProvider(
            create: (_) => ScheduleProvider(
              DatabaseService.instance,
            ),
          ),
        ],
        child: const ClassNestApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(ClassNestApp), findsOneWidget);
  });
}
