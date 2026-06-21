import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final int bookingId;
  final String bookingRef;
  final double grandTotal;
  final String currency;
  final String status;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.bookingRef,
    required this.grandTotal,
    required this.currency,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              _SuccessIcon(),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.onSurface),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your seats are reserved. Check your email for the e-ticket.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14),
              ),
              const SizedBox(height: 32),
              _RefCard(
                bookingRef: bookingRef,
                grandTotal: grandTotal,
                currency: currency,
                status: status,
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go('/bookings'),
                    child: const Text('View My Bookings'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        context.push('/booking-detail', extra: bookingId),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      side: const BorderSide(color: AppTheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('View Booking Detail'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100, height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF00B37A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: AppTheme.primary.withAlpha(76), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      child: const Icon(Icons.check_rounded, color: Colors.white, size: 52),
    );
  }
}

class _RefCard extends StatelessWidget {
  final String bookingRef;
  final double grandTotal;
  final String currency;
  final String status;
  const _RefCard({required this.bookingRef, required this.grandTotal, required this.currency, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFC9C4).withAlpha(128)),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        const Icon(Icons.confirmation_number_outlined, color: AppTheme.primary, size: 32),
        const SizedBox(height: 12),
        const Text('Booking Reference', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text(bookingRef, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 2)),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Status', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
          _StatusBadge(status: status),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Paid', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
          Text('$currency ${grandTotal.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.onSurface, fontSize: 13)),
        ]),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status.toUpperCase()) {
      case 'CONFIRMED': color = AppTheme.primary; break;
      case 'PENDING': color = Colors.orange; break;
      default: color = AppTheme.onSurfaceVariant;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}
