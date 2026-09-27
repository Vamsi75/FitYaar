import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/push/push_messaging.dart';
import 'core/storage/token_storage.dart';
import 'core/widgets/brand_loading.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/auth_service.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/main_navigation_screen.dart';
import 'features/gym/gym_notifications.dart';
import 'features/gym/gym_service.dart';
import 'features/profile/measurement_service.dart';
import 'features/profile/profile_service.dart';
import 'features/social/social_service.dart';
import 'features/workout/active_workout_model.dart';
import 'features/workout/workout_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushMessaging.instance.init();
  GymNotifications.instance.init();
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final authService = AuthService(apiClient, tokenStorage);

  runApp(FitYaarApp(
    apiClient: apiClient,
    authProvider: AuthProvider(authService, tokenStorage)..bootstrap(),
  ));
}

class FitYaarApp extends StatelessWidget {
  final ApiClient apiClient;
  final AuthProvider authProvider;

  const FitYaarApp({
    super.key,
    required this.apiClient,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<WorkoutService>(
          create: (ctx) => WorkoutService(ctx.read<ApiClient>()),
        ),
        Provider<ProfileService>(
          create: (ctx) => ProfileService(ctx.read<ApiClient>()),
        ),
        Provider<MeasurementService>(
          create: (ctx) => MeasurementService(ctx.read<ApiClient>()),
        ),
        Provider<GymService>(
          create: (ctx) => GymService(ctx.read<ApiClient>()),
        ),
        Provider<SocialService>(
          create: (ctx) => SocialService(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ActiveWorkoutModel>(
          create: (ctx) => ActiveWorkoutModel(ctx.read<WorkoutService>()),
        ),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp(
        title: 'FitYaar',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            primary: Colors.deepOrange,
            secondary: Colors.blueAccent,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          // Transparent scaffolds so the app gradient shows through the glass UI.
          scaffoldBackgroundColor: Colors.transparent,
          appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        ),
        builder: (context, child) => DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF241318), Color(0xFF150F12), Color(0xFF0D0A0B)],
            ),
          ),
          child: child,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

/// Routes to login or the app shell based on auth status.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;
    switch (status) {
      case AuthStatus.unknown:
        return const BrandLoading();
      case AuthStatus.authenticated:
        return const MainNavigationScreen();
      case AuthStatus.unauthenticated:
        return const LoginScreen();
    }
  }
}
