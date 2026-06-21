import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/search_models.dart';
import '../../data/services/search_service.dart';
import '../../providers/auth_provider.dart';

class SeatSelectionScreen extends StatefulWidget {
  final SearchResult scheduleResult;

  const SeatSelectionScreen({super.key, required this.scheduleResult});

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  ScheduleInventoryLayout? _layout;
  bool _loading = true;
  String? _error;
  final Set<int> _selectedInventoryIds = {};
  final String _sessionId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    final service = context.read<SearchService>();
    try {
      final layout =
          await service.getInventoryLayout(widget.scheduleResult.scheduleId);
      setState(() {
        _layout = layout;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggleSeat(InventoryItem item) {
    if (!item.isAvailable) return;
    setState(() {
      if (_selectedInventoryIds.contains(item.scheduleInventoryId)) {
        _selectedInventoryIds.remove(item.scheduleInventoryId);
      } else {
        if (_selectedInventoryIds.length >= 4) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 4 seats per booking')),
          );
          return;
        }
        _selectedInventoryIds.add(item.scheduleInventoryId);
      }
    });
  }

  List<InventoryItem> get _selectedItems =>
      _layout?.items.where((i) => _selectedInventoryIds.contains(i.scheduleInventoryId)).toList() ?? [];

  double get _totalPrice =>
      _selectedItems.fold(0, (sum, i) => sum + i.finalPrice + i.taxAmount);

  void _proceed() {
    if (!context.read<AuthProvider>().isLoggedIn) {
      context.push('/login');
      return;
    }
    if (_selectedInventoryIds.isEmpty) return;
    context.push('/checkout', extra: {
      'scheduleResult': widget.scheduleResult,
      'selectedItems': _selectedItems,
      'sessionId': _sessionId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.scheduleResult.sourceName} → ${widget.scheduleResult.destinationName}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            Text(
              '${AppDateUtils.formatTime(widget.scheduleResult.departureAt)} · ${widget.scheduleResult.productName}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _selectedInventoryIds.isNotEmpty
          ? _BottomBar(
              selectedCount: _selectedInventoryIds.length,
              total: _totalPrice,
              currency: _selectedItems.first.currency,
              onProceed: _proceed,
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: AppTheme.error),
                      const SizedBox(height: 12),
                      Text(_error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _error = null;
                            });
                            _loadInventory();
                          },
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _SeatGrid(
                  layout: _layout!,
                  selectedIds: _selectedInventoryIds,
                  onToggle: _toggleSeat,
                ),
    );
  }
}

class _SeatGrid extends StatelessWidget {
  final ScheduleInventoryLayout layout;
  final Set<int> selectedIds;
  final void Function(InventoryItem) onToggle;

  const _SeatGrid({
    required this.layout,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final seats = layout.items.where((i) => i.type == 'SEAT').toList();
    final byClass = <String, List<InventoryItem>>{};
    for (final s in seats) {
      byClass.putIfAbsent(s.className, () => []).add(s);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Legend(),
          const SizedBox(height: 16),
          ...byClass.entries.map((entry) => _ClassSection(
                className: entry.key,
                items: entry.value,
                selectedIds: selectedIds,
                onToggle: onToggle,
              )),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(color: Colors.white, border: const Color(0xFFBFC9C4), label: 'Available'),
        const SizedBox(width: 20),
        _LegendItem(color: AppTheme.primary, border: AppTheme.primary, label: 'Selected'),
        const SizedBox(width: 20),
        _LegendItem(color: const Color(0xFFEEEEEE), border: const Color(0xFFBFC9C4), label: 'Taken'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color border;
  final String label;
  const _LegendItem({required this.color, required this.border, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ClassSection extends StatelessWidget {
  final String className;
  final List<InventoryItem> items;
  final Set<int> selectedIds;
  final void Function(InventoryItem) onToggle;

  const _ClassSection({
    required this.className,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(className,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              if (items.isNotEmpty)
                Text(
                  '${items.first.currency} ${items.first.finalPrice.toStringAsFixed(0)} + tax',
                  style: const TextStyle(
                      color: AppTheme.onSurfaceVariant, fontSize: 11),
                ),
            ],
          ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items.map((item) {
            final isSelected = selectedIds.contains(item.scheduleInventoryId);
            final isAvailable = item.isAvailable;
            return GestureDetector(
              onTap: () => onToggle(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primary
                      : isAvailable
                          ? Colors.white
                          : const Color(0xFFEEEEEE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primary
                        : const Color(0xFFBFC9C4),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_seat,
                      size: 20,
                      color: isSelected
                          ? Colors.white
                          : isAvailable
                              ? AppTheme.onSurfaceVariant
                              : const Color(0xFFBFC9C4),
                    ),
                    Text(
                      item.itemNumber,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isAvailable
                                ? AppTheme.onSurface
                                : const Color(0xFFBFC9C4),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int selectedCount;
  final double total;
  final String currency;
  final VoidCallback onProceed;

  const _BottomBar({
    required this.selectedCount,
    required this.total,
    required this.currency,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$selectedCount seat${selectedCount > 1 ? 's' : ''} selected',
                  style: const TextStyle(
                      color: AppTheme.onSurfaceVariant, fontSize: 12)),
              Text(
                '$currency ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: AppTheme.onSurface),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: onProceed,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
