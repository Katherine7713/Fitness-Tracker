import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/data/datasources/accelerometer_datasource.dart';
import 'features/auth/data/datasources/biometric_datasource.dart';
import 'features/auth/domain/entities/step_data.dart';
import 'features/auth/domain/usecases/authenticate_user.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/steps/presentation/widgets/step_counter_widget.dart';
import 'features/tracking/presentation/widgets/route_map_widget.dart';
import 'features/welcome/presentation/pages/welcome_screen.dart';
import 'features/history/domain/entities/activity_record.dart';
import 'features/history/presentation/pages/history_page.dart';
import 'features/history/data/datasources/activity_repository_impl.dart';
import 'features/history/presentation/bloc/history_bloc.dart';
import 'services/activity_announcer.dart';
import 'services/fall_detector.dart';
import 'widgets/fall_dialog.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FitnessApp());
}

class FitnessApp extends StatelessWidget {
  const FitnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    final biometricDataSource = BiometricDataSourceImpl();
    final authenticateUser = AuthenticateUser(biometricDataSource);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Fitness Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6366F1)),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => AuthBloc(authenticateUser),
        child: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _showLogin = false;
  bool _isAuthenticated = false;

  void _onSwipeUp() {
    setState(() => _showLogin = true);
  }

  void _onAuthSuccess() {
    setState(() => _isAuthenticated = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return const HomePage();
    }
    if (_showLogin) {
      return LoginPage(onAuthSuccess: _onAuthSuccess);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta! < -5) {
          _onSwipeUp();
        }
      },
      child: WelcomeScreen(onSwipeUp: _onSwipeUp),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _stepKey = GlobalKey<StepCounterWidgetState>();
  final _routeKey = GlobalKey<RouteMapWidgetState>();
  final AccelerometerDataSource _dataSource = AccelerometerDataSourceImpl();
  final ActivityAnnouncer _announcer = ActivityAnnouncer();
  final FallDetector _fallDetector = FallDetector();
  final _repository = ActivityRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _fallDetector.onFallDetected = _onFallDetected;
    _fallDetector.start();
  }

  @override
  void dispose() {
    _announcer.dispose();
    _fallDetector.dispose();
    super.dispose();
  }

  void _onFallDetected() {
    _announcer.speakMessage('Has sufrido una caída');
    FallDialog.show(
      context: navigatorKey.currentContext!,
      onConfirm: () {},
    );
  }

  void _saveToHistory() {
    final stepState = _stepKey.currentState;
    final routeState = _routeKey.currentState;

    if (stepState == null) return;

    final now = DateTime.now();
    final category = stepState.activityType == ActivityType.walking
        ? ActivityCategory.walking
        : stepState.activityType == ActivityType.running
            ? ActivityCategory.running
            : ActivityCategory.stationary;

    final route = routeState?.routeData;
    final startTime =
        route?.startTime ?? now.subtract(const Duration(minutes: 30));
    final endTime = route?.endTime ?? now;

    final record = ActivityRecord(
      category: category,
      startTime: startTime,
      endTime: endTime,
      steps: stepState.stepCount,
      distanceKm: route?.distanceKm ?? 0,
      calories: stepState.calories + (route?.estimatedCalories ?? 0),
      averageSpeedKmh: route?.averageSpeed ?? 0,
    );

    _repository.create(record).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Actividad guardada en el historial'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fitness Tracker'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Guardar en historial',
            onPressed: _saveToHistory,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => HistoryBloc(ActivityRepositoryImpl()),
                    child: const HistoryPage(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            StepCounterWidget(
              key: _stepKey,
              dataSource: _dataSource,
              onActivityChanged: (type) => _announcer.onActivityUpdate(type),
            ),
            const SizedBox(height: 16),
            RouteMapWidget(key: _routeKey),
          ],
        ),
      ),
    );
  }
}
