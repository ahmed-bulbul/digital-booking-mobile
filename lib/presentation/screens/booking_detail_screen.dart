import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/booking_models.dart';
import '../../data/services/booking_service.dart';
import '../../data/services/payment_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final int bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final detail = await context.read<BookingService>().getBookingDetail(widget.bookingId);
      setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _downloadTicket() async {
    final url = context.read<BookingService>().ticketUrl(widget.bookingId);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open ticket URL')));
      }
    }
  }

  Future<void> _cancelBooking() async {
    final reason = await _showCancelDialog();
    if (reason == null) return;
    try {
      await context.read<BookingService>().cancelBooking(widget.bookingId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled')));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _requestRefund() async {
    final reason = await _showRefundDialog();
    if (reason == null) return;
    try {
      await context.read<PaymentService>().requestRefund(
        bookingId: widget.bookingId,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Refund request submitted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<String?> _showCancelDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Please provide a reason for cancellation:'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Reason'),
            maxLines: 3,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? 'No reason provided' : ctrl.text.trim()),
            child: const Text('Cancel Booking', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRefundDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Refund'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Please provide a reason for the refund:'),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Reason'),
            maxLines: 3,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Back')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isEmpty ? 'Refund requested' : ctrl.text.trim()),
            child: const Text('Submit Request', style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Booking Detail'),
        actions: [
          if (_detail != null && _detail!.status == 'CONFIRMED')
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Download Ticket',
              onPressed: _downloadTicket,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppTheme.primary,
                  child: _DetailBody(
                    detail: _detail!,
                    onCancel: _cancelBooking,
                    onRefund: _requestRefund,
                    onDownloadTicket: _downloadTicket,
                  ),
                ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final BookingDetail detail;
  final VoidCallback onCancel;
  final VoidCallback onRefund;
  final VoidCallback onDownloadTicket;

  const _DetailBody({
    required this.detail,
    required this.onCancel,
    required this.onRefund,
    required this.onDownloadTicket,
  });

  @override
  Widget build(BuildContext context) {
    final canCancel = detail.status == 'PENDING' || detail.status == 'CONFIRMED';
    final canRefund = detail.status == 'CANCELLED';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(detail: detail),
        const SizedBox(height: 12),
        _JourneyCard(detail: detail),
        const SizedBox(height: 12),
        _PassengerList(items: detail.items),
        const SizedBox(height: 12),
        _PriceCard(detail: detail),
        const SizedBox(height: 16),
        if (detail.status == 'CONFIRMED') ...[
          ElevatedButton.icon(
            onPressed: onDownloadTicket,
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text('Download E-Ticket (PDF)'),
          ),
          const SizedBox(height: 12),
        ],
        if (canCancel) ...[
          OutlinedButton.icon(
            onPressed: onCancel,
            icon: const Icon(Icons.cancel_outlined, color: AppTheme.error, size: 18),
            label: const Text('Cancel Booking', style: TextStyle(color: AppTheme.error)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppTheme.error.withAlpha(128)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (canRefund) ...[
          OutlinedButton.icon(
            onPressed: onRefund,
            icon: const Icon(Icons.currency_exchange_outlined, color: AppTheme.primary, size: 18),
            label: const Text('Request Refund'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final BookingDetail detail;
  const _HeaderCard({required this.detail});

  Color get _statusColor {
    switch (detail.status) {
      case 'CONFIRMED': return AppTheme.primary;
      case 'PENDING': return Colors.orange;
      case 'CANCELLED': return AppTheme.error;
      default: return AppTheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFC9C4).withAlpha(128)),
      ),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Booking Ref', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
            Text(detail.bookingRef,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(AppDateUtils.formatDate(detail.createdAt),
                style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(detail.status,
                style: TextStyle(color: _statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final BookingDetail detail;
  const _JourneyCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF00B37A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(detail.productName,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(detail.providerName,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 12),
        if (detail.departureAt != null && detail.arrivalAt != null)
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppDateUtils.formatTime(detail.departureAt!),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              Text(detail.sourceName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
            const Icon(Icons.arrow_forward, color: Colors.white70, size: 18),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(AppDateUtils.formatTime(detail.arrivalAt!),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              Text(detail.destinationName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ])),
          ]),
        const SizedBox(height: 8),
        if (detail.departureAt != null)
          Text(AppDateUtils.formatDate(detail.departureAt!),
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}

class _PassengerList extends StatelessWidget {
  final List<SeatPassenger> items;
  const _PassengerList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFC9C4).withAlpha(128)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Passengers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          return Column(children: [
            if (i > 0) const Divider(height: 16),
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primary.withAlpha(25),
                child: Text(p.passengerName.isNotEmpty ? p.passengerName[0].toUpperCase() : '?',
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.passengerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Row(children: [
                  _chip('Seat ${p.seatNumber}'),
                  const SizedBox(width: 6),
                  if (p.gender != null) _chip(p.gender!),
                ]),
              ])),
              if (p.ticketNumber != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withAlpha(15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('# ${p.ticketNumber}',
                      style: const TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ]),
          ]);
        }),
      ]),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.onSurfaceVariant)),
  );
}

class _PriceCard extends StatelessWidget {
  final BookingDetail detail;
  const _PriceCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFC9C4).withAlpha(128)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Price Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        _row('Subtotal', '${detail.currency} ${detail.subtotal.toStringAsFixed(0)}'),
        _row('Tax', '${detail.currency} ${detail.taxTotal.toStringAsFixed(0)}'),
        if (detail.discountTotal > 0)
          _row('Discount', '- ${detail.currency} ${detail.discountTotal.toStringAsFixed(0)}', isGreen: true),
        const Divider(),
        _row('Total', '${detail.currency} ${detail.grandTotal.toStringAsFixed(0)}', bold: true),
      ]),
    );
  }

  Widget _row(String label, String value, {bool bold = false, bool isGreen = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: AppTheme.onSurfaceVariant, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
          color: isGreen ? AppTheme.primary : (bold ? AppTheme.onSurface : AppTheme.onSurface))),
    ]),
  );
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
      ]),
    ));
  }
}
