import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';

import 'package:classnav/app.dart';
import 'package:classnav/models/app_user.dart';
import 'package:classnav/providers/auth_provider.dart';
import 'package:classnav/providers/theme_provider.dart';
import 'package:classnav/services/auth_service.dart';
import 'package:classnav/services/preferences_service.dart';

class TestAuthService implements AuthService {
  @override
  Future<AppUser?> getCurrentUser() async => null;

  @override
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<AppUser?> register({
    required String email,
    required String password,
    required UserRole role,
    required String name,
    required String year,
    required String course,
  }) async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
            create: (_) => AuthProvider(TestAuthService()),
          ),
        ],
        child: const ClassNestApp(),
      ),
    );

    await tester.pump();

    expect(find.byType(ClassNestApp), findsOneWidget);
  });
}