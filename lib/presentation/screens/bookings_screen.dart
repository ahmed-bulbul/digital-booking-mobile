import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/booking_models.dart';
import '../../data/services/booking_service.dart';
import '../../providers/auth_provider.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<MyBooking> _allBookings = [];
  bool _loading = true;
  String? _error;

  final _tabs = const ['All', 'Upcoming', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      setState(() => _loading = false);
      return;
    }
    try {
      final bookings =
          await context.read<BookingService>().getMyBookings(size: 50);
      setState(() {
        _allBookings = bookings;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<MyBooking> _filtered(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _allBookings
            .where((b) => b.status == 'CONFIRMED' || b.status == 'PENDING')
            .toList();
      case 2:
        return _allBookings
            .where((b) => b.status == 'COMPLETED')
            .toList();
      case 3:
        return _allBookings
            .where((b) => b.status == 'CANCELLED')
            .toList();
      default:
        return _allBookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: !auth.isLoggedIn
          ? _NotLoggedIn(onLogin: () => context.push('/login'))
          : _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppTheme.primary))
              : _error != null
                  ? _ErrorView(
                      message: _error!, onRetry: _loadBookings)
                  : TabBarView(
                      controller: _tabController,
                      children: List.generate(
                        _tabs.length,
                        (i) => _BookingsList(
                          bookings: _filtered(i),
                          onRefresh: _loadBookings,
                        ),
                      ),
                    ),
    );
  }
}

class _BookingsList extends StatelessWidget {
  final List<MyBooking> bookings;
  final Future<void> Function() onRefresh;
  const _BookingsList({required this.bookings, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_outlined,
                size: 56, color: AppTheme.outline),
            SizedBox(height: 12),
            Text('No bookings found',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (ctx, i) => _BookingCard(booking: bookings[i]),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final MyBooking booking;
  const _BookingCard({required this.booking});

  Color get _statusColor {
    switch (booking.status) {
      case 'CONFIRMED':
        return AppTheme.primary;
      case 'PENDING':
        return Colors.orange;
      case 'CANCELLED':
        return AppTheme.error;
      default:
        return AppTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/booking-detail', extra: booking.bookingId),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFBFC9C4).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.bookingRef,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                        color: _statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppDateUtils.formatTime(booking.departureAt),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(booking.sourceName,
                          style: const TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(Icons.arrow_forward,
                        size: 16, color: AppTheme.primary),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppDateUtils.formatTime(booking.arrivalAt),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(booking.destinationName,
                          style: const TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.directions_bus_outlined,
                    size: 14, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(booking.productName,
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 12)),
                const SizedBox(width: 12),
                const Icon(Icons.event_seat_outlined,
                    size: 14, color: AppTheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(booking.seats.join(', '),
                    style: const TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 12)),
                const Spacer(),
                Text(
                  '${booking.currency} ${booking.grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurface,
                      fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    )); // GestureDetector
  }
}

class _NotLoggedIn extends StatelessWidget {
  final VoidCallback onLogin;
  const _NotLoggedIn({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outlined, size: 56, color: AppTheme.outline),
            const SizedBox(height: 16),
            const Text(
              'Sign in to view your bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onLogin,
              child: const Text('Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
