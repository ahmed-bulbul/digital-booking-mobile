import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/search_models.dart';

class BusCard extends StatelessWidget {
  final SearchResult result;
  final VoidCallback onTap;

  const BusCard({super.key, required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: const Color(0xFFBFC9C4).withOpacity(0.6)),
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
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(result.productName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(result.providerName,
                            style: const TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${result.currency} ${result.minPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppTheme.primary),
                      ),
                      const Text('per seat',
                          style: TextStyle(
                              color: AppTheme.onSurfaceVariant, fontSize: 11)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _TimeBlock(
                    time: AppDateUtils.formatTime(result.departureAt),
                    label: result.sourceName,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          AppDateUtils.formatDuration(result.durationMinutes),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 1.5,
                                color: const Color(0xFFBFC9C4),
                              ),
                            ),
                            const Icon(Icons.arrow_forward,
                                size: 14, color: AppTheme.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _TimeBlock(
                    time: AppDateUtils.formatTime(result.arrivalAt),
                    label: result.destinationName,
                    alignRight: true,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _Chip(
                    icon: Icons.event_seat_outlined,
                    label: '${result.availableCount} seats left',
                    color: result.availableCount <= 5
                        ? AppTheme.error
                        : AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _Chip(
                    icon: Icons.schedule_outlined,
                    label: AppDateUtils.formatShortDate(result.departureAt),
                    color: AppTheme.onSurfaceVariant,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, Color(0xFF00B37A)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('Select Seat',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
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

class _TimeBlock extends StatelessWidget {
  final String time;
  final String label;
  final bool alignRight;
  const _TimeBlock(
      {required this.time, required this.label, this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(time,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.onSurfaceVariant, fontSize: 11),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
