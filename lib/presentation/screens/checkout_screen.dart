import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/search_models.dart';
import '../../data/services/booking_service.dart';
import '../../data/services/payment_service.dart';
import '../../data/services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/auth_models.dart';

class CheckoutScreen extends StatefulWidget {
  final SearchResult scheduleResult;
  final List<InventoryItem> selectedItems;
  final String sessionId;

  const CheckoutScreen({
    super.key,
    required this.scheduleResult,
    required this.selectedItems,
    required this.sessionId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _stepPassengers = 0;
  static const _stepPayment = 1;

  int _step = _stepPassengers;

  final _formKey = GlobalKey<FormState>();
  final List<_PassengerForm> _passengerForms = [];

  PaymentMethod _paymentMethod = PaymentMethod.bkash;
  final _txCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  // Booking created in step 1, payment in step 2
  int? _bookingId;
  String? _bookingRef;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.selectedItems.length; i++) {
      _passengerForms.add(_PassengerForm());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().user;
      if (user != null && _passengerForms.isNotEmpty) {
        setState(() => _passengerForms.first.fillFromUser(user));
      }
    });
  }

  @override
  void dispose() {
    for (final f in _passengerForms) f.dispose();
    _txCtrl.dispose();
    super.dispose();
  }

  double get _total =>
      widget.selectedItems.fold(0, (s, i) => s + i.finalPrice + i.taxAmount);

  String get _currency =>
      widget.selectedItems.isNotEmpty ? widget.selectedItems.first.currency : 'BDT';

  // ── Step 1: lock seats + create passengers + create booking ──
  Future<void> _submitPassengers() async {
    if (!_formKey.currentState!.validate()) return;

    final bookingService = context.read<BookingService>();
    final apiService = context.read<ApiService>();

    setState(() { _loading = true; _error = null; });

    try {
      final userId = await apiService.getStoredUserId();
      if (userId == null) throw Exception('Please sign in first');

      final items = <Map<String, dynamic>>[];
      for (int i = 0; i < widget.selectedItems.length; i++) {
        final seat = widget.selectedItems[i];
        final form = _passengerForms[i];

        await bookingService.lockSeat(
            seat.scheduleInventoryId, widget.sessionId, seat.lockVersion);

        final ageText = form.ageCtrl.text.trim();
        final passenger = await bookingService.createPassenger(
          userId: userId,
          firstName: form.firstNameCtrl.text.trim(),
          lastName: form.lastNameCtrl.text.trim(),
          gender: form.gender,
          age: ageText.isEmpty ? null : int.tryParse(ageText),
          phone: form.phoneCtrl.text.trim(),
          email: form.emailCtrl.text.trim(),
        );

        items.add({
          'scheduleInventoryId': seat.scheduleInventoryId,
          'passengerId': passenger.id,
          'lockVersion': seat.lockVersion,
        });
      }

      final booking = await bookingService.createBooking(
        userId: userId,
        sessionId: widget.sessionId,
        items: items,
        couponCode: null,
      );

      setState(() {
        _bookingId = booking.bookingId;
        _bookingRef = booking.bookingRef;
        _step = _stepPayment;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Step 2: create payment + mark success if online ──
  Future<void> _submitPayment() async {
    if (_bookingId == null) return;
    final isManual = _paymentMethod != PaymentMethod.card;
    if (isManual && _txCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter your transaction ID');
      return;
    }

    final paymentService = context.read<PaymentService>();
    setState(() { _loading = true; _error = null; });

    try {
      final result = await paymentService.createPayment(
        bookingId: _bookingId!,
        method: _paymentMethod,
        transactionId: isManual ? _txCtrl.text.trim() : null,
      );

      if (!isManual) {
        await paymentService.markPaymentSuccess(result.paymentId);
      }

      if (mounted) {
        context.go('/booking-confirmation', extra: {
          'bookingId': _bookingId!,
          'bookingRef': _bookingRef ?? '',
          'grandTotal': _total,
          'currency': _currency,
          'status': 'CONFIRMED',
        });
      }
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(_step == _stepPassengers ? 'Passenger Details' : 'Payment'),
        leading: _step == _stepPayment
            ? BackButton(onPressed: () => setState(() { _step = _stepPassengers; _error = null; }))
            : null,
      ),
      body: Column(
        children: [
          _StepIndicator(current: _step),
          Expanded(
            child: _step == _stepPassengers
                ? _PassengerStep(
                    formKey: _formKey,
                    result: widget.scheduleResult,
                    items: widget.selectedItems,
                    forms: _passengerForms,
                    total: _total,
                    currency: _currency,
                    loading: _loading,
                    error: _error,
                    onSubmit: _submitPassengers,
                  )
                : _PaymentStep(
                    bookingRef: _bookingRef ?? '',
                    total: _total,
                    currency: _currency,
                    selectedMethod: _paymentMethod,
                    txCtrl: _txCtrl,
                    loading: _loading,
                    error: _error,
                    onMethodChanged: (m) => setState(() => _paymentMethod = m),
                    onSubmit: _submitPayment,
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Step indicator ──
class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Row(
        children: [
          _StepDot(index: 0, label: 'Passengers', current: current),
          Expanded(child: Divider(color: current >= 1 ? AppTheme.primary : const Color(0xFFBFC9C4))),
          _StepDot(index: 1, label: 'Payment', current: current),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final String label;
  final int current;
  const _StepDot({required this.index, required this.label, required this.current});

  @override
  Widget build(BuildContext context) {
    final done = index < current;
    final active = index == current;
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (done || active) ? AppTheme.primary : const Color(0xFFBFC9C4),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text('${index + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: active ? AppTheme.primary : AppTheme.onSurfaceVariant, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}

// ── Step 1: Passenger details ──
class _PassengerStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final SearchResult result;
  final List<InventoryItem> items;
  final List<_PassengerForm> forms;
  final double total;
  final String currency;
  final bool loading;
  final String? error;
  final VoidCallback onSubmit;

  const _PassengerStep({
    required this.formKey,
    required this.result,
    required this.items,
    required this.forms,
    required this.total,
    required this.currency,
    required this.loading,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _JourneySummary(result: result, items: items),
          const SizedBox(height: 16),
          if (error != null) ...[_ErrorBanner(message: error!), const SizedBox(height: 16)],
          ...List.generate(items.length, (i) => _PassengerFormCard(
                index: i,
                seatNumber: items[i].itemNumber,
                form: forms[i],
              )),
          const SizedBox(height: 16),
          _PriceSummary(items: items, total: total),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: loading ? null : onSubmit,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Continue to Payment · $currency ${total.toStringAsFixed(0)}'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Step 2: Payment ──
class _PaymentStep extends StatelessWidget {
  final String bookingRef;
  final double total;
  final String currency;
  final PaymentMethod selectedMethod;
  final TextEditingController txCtrl;
  final bool loading;
  final String? error;
  final ValueChanged<PaymentMethod> onMethodChanged;
  final VoidCallback onSubmit;

  const _PaymentStep({
    required this.bookingRef,
    required this.total,
    required this.currency,
    required this.selectedMethod,
    required this.txCtrl,
    required this.loading,
    required this.error,
    required this.onMethodChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _BookingRefCard(ref: bookingRef, total: total, currency: currency),
        const SizedBox(height: 20),
        if (error != null) ...[_ErrorBanner(message: error!), const SizedBox(height: 16)],
        Text('Select Payment Method',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...PaymentMethod.values.map((m) => _MethodTile(
              method: m,
              selected: selectedMethod == m,
              onTap: () => onMethodChanged(m),
            )),
        if (selectedMethod != PaymentMethod.card) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: txCtrl,
            decoration: InputDecoration(
              labelText: 'Transaction ID',
              hintText: 'Enter your ${selectedMethod.label} transaction ID',
              prefixIcon: const Icon(Icons.receipt_long_outlined),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send $currency ${total.toStringAsFixed(0)} to our ${selectedMethod.label} number, then enter the Transaction ID above.',
            style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant),
          ),
        ] else ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primary.withAlpha(40)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outlined, color: AppTheme.primary, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You will be redirected to our secure payment gateway.',
                    style: TextStyle(color: AppTheme.primary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: loading ? null : onSubmit,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: loading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Pay $currency ${total.toStringAsFixed(0)}'),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;
  const _MethodTile({required this.method, required this.selected, required this.onTap});

  IconData get _icon {
    switch (method) {
      case PaymentMethod.bkash:
      case PaymentMethod.nagad:
        return Icons.smartphone_outlined;
      case PaymentMethod.card:
        return Icons.credit_card_outlined;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_outlined;
      case PaymentMethod.cash:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : const Color(0xFFBFC9C4),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: selected ? AppTheme.primary : AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: selected ? Colors.white : AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Text(method.label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected ? AppTheme.primary : AppTheme.onSurface)),
            const Spacer(),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppTheme.primary : const Color(0xFFBFC9C4), width: 2),
              ),
              child: selected
                  ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.primary)))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingRefCard extends StatelessWidget {
  final String ref;
  final double total;
  final String currency;
  const _BookingRefCard({required this.ref, required this.total, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFC9C4).withAlpha(128)),
      ),
      child: Row(
        children: [
          const Icon(Icons.confirmation_number_outlined, color: AppTheme.primary, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Booking Reference', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
              Text(ref, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1.5)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Total', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
              Text('$currency ${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ──
class _PassengerForm {
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  String? gender;

  void fillFromUser(CurrentUser user) {
    final parts = user.name.trim().split(RegExp(r'\s+'));
    firstNameCtrl.text = parts.first;
    lastNameCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    emailCtrl.text = user.email;
    if (user.phone != null && user.phone!.isNotEmpty) {
      phoneCtrl.text = user.phone!;
    }
  }

  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    ageCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
  }
}

class _PassengerFormCard extends StatefulWidget {
  final int index;
  final String seatNumber;
  final _PassengerForm form;
  const _PassengerFormCard({required this.index, required this.seatNumber, required this.form});

  @override
  State<_PassengerFormCard> createState() => _PassengerFormCardState();
}

class _PassengerFormCardState extends State<_PassengerFormCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFC9C4).withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Passenger ${widget.index + 1} · Seat ${widget.seatNumber}',
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: TextFormField(
              controller: widget.form.firstNameCtrl,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            )),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(
              controller: widget.form.lastNameCtrl,
              decoration: const InputDecoration(labelText: 'Last Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(
              controller: widget.form.ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age (optional)'),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                final age = int.tryParse(v);
                if (age == null || age < 1 || age > 120) return 'Invalid age';
                return null;
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gender (optional)', style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                DropdownButton<String?>(
                  value: widget.form.gender,
                  isExpanded: true,
                  hint: const Text('Select'),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => widget.form.gender = v),
                ),
              ],
            )),
          ]),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.form.phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone_outlined)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: widget.form.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email (optional)', prefixIcon: Icon(Icons.email_outlined)),
          ),
        ],
      ),
    );
  }
}

class _JourneySummary extends StatelessWidget {
  final SearchResult result;
  final List<InventoryItem> items;
  const _JourneySummary({required this.result, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF00B37A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(result.productName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        Text(result.providerName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppDateUtils.formatTime(result.departureAt), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(result.sourceName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Column(children: [
            Text(AppDateUtils.formatDuration(result.durationMinutes), style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const Icon(Icons.arrow_forward, color: Colors.white70, size: 18),
          ]),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(AppDateUtils.formatTime(result.arrivalAt), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(result.destinationName, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: items.map((i) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.white.withAlpha(51), borderRadius: BorderRadius.circular(20)),
          child: Text('Seat ${i.itemNumber}', style: const TextStyle(color: Colors.white, fontSize: 11)),
        )).toList()),
      ]),
    );
  }
}

class _PriceSummary extends StatelessWidget {
  final List<InventoryItem> items;
  final double total;
  const _PriceSummary({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    final currency = items.isNotEmpty ? items.first.currency : 'BDT';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFC9C4).withAlpha(128)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Seat ${item.itemNumber} (${item.className})', style: const TextStyle(fontSize: 13)),
                Text('$currency ${(item.finalPrice + item.taxAmount).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
              ]),
            )),
        const Divider(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text('$currency ${total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.primary)),
        ]),
      ]),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.error.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.error.withAlpha(76)),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: AppTheme.error, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: TextStyle(color: AppTheme.error, fontSize: 13))),
      ]),
    );
  }
}
