import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'data/models/search_models.dart';
import 'data/services/api_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/search_service.dart';
import 'data/services/booking_service.dart';
import 'data/services/payment_service.dart';
import 'providers/auth_provider.dart';
import 'providers/search_provider.dart';
import 'presentation/screens/main_scaffold.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/search_screen.dart';
import 'presentation/screens/seat_selection_screen.dart';
import 'presentation/screens/checkout_screen.dart';
import 'presentation/screens/booking_confirmation_screen.dart';
import 'presentation/screens/booking_detail_screen.dart';
import 'presentation/screens/bookings_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/register_screen.dart';
import 'presentation/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiService = ApiService();
  await apiService.init();
  runApp(JatraXpressApp(apiService: apiService));
}

class JatraXpressApp extends StatelessWidget {
  final ApiService apiService;
  const JatraXpressApp({super.key, required this.apiService});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService(apiService);
    final searchService = SearchService(apiService);
    final bookingService = BookingService(apiService);
    final paymentService = PaymentService(apiService);

    return MultiProvider(
      providers: [
        Provider<ApiService>.value(value: apiService),
        Provider<SearchService>.value(value: searchService),
        Provider<BookingService>.value(value: bookingService),
        Provider<PaymentService>.value(value: paymentService),
        ChangeNotifierProvider(
          create: (_) =>
              AuthProvider(authService, apiService)..tryRestoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => SearchProvider(searchService),
        ),
      ],
      child: MaterialApp.router(
        title: 'JatraXpress',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: _router,
      ),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/home',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        final tabIndex = _tabIndex(state.uri.path);
        if (tabIndex < 0) return child;
        return MainScaffold(currentIndex: tabIndex, child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        GoRoute(path: '/bookings', builder: (_, __) => const BookingsScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
    GoRoute(path: '/', redirect: (_, __) => '/home'),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(
      path: '/seat-selection',
      builder: (_, state) => SeatSelectionScreen(
        scheduleResult: state.extra as SearchResult,
      ),
    ),
    GoRoute(
      path: '/checkout',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return CheckoutScreen(
          scheduleResult: extra['scheduleResult'] as SearchResult,
          selectedItems: extra['selectedItems'] as List<InventoryItem>,
          sessionId: extra['sessionId'] as String,
        );
      },
    ),
    GoRoute(
      path: '/booking-confirmation',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BookingConfirmationScreen(
          bookingId: extra['bookingId'] as int,
          bookingRef: extra['bookingRef'] as String,
          grandTotal: (extra['grandTotal'] as num).toDouble(),
          currency: extra['currency'] as String,
          status: extra['status'] as String,
        );
      },
    ),
    GoRoute(
      path: '/booking-detail',
      builder: (_, state) => BookingDetailScreen(bookingId: state.extra as int),
    ),
  ],
);

int _tabIndex(String path) {
  if (path.startsWith('/home')) return 0;
  if (path.startsWith('/search')) return 1;
  if (path.startsWith('/bookings')) return 2;
  if (path.startsWith('/profile')) return 3;
  return -1;
}
