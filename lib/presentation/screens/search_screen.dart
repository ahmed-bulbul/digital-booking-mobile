import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/search_provider.dart';
import '../widgets/bus_card_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchProvider>().search();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SearchProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: provider.selectedRoute != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.selectedRoute!.label,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    AppDateUtils.formatDate(provider.travelDate),
                    style: const TextStyle(
                        fontSize: 11, color: Colors.white70, fontWeight: FontWeight.normal),
                  ),
                ],
              )
            : const Text('Search Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () => _showSortSheet(context, provider),
          ),
        ],
      ),
      body: provider.searching
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : provider.error != null
              ? _ErrorView(
                  message: provider.error!,
                  onRetry: () => provider.search(),
                )
              : provider.results.isEmpty
                  ? const _EmptyView()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.results.length,
                      itemBuilder: (ctx, i) {
                        final result = provider.results[i];
                        return BusCard(
                          result: result,
                          onTap: () => context.push(
                            '/seat-selection',
                            extra: result,
                          ),
                        );
                      },
                    ),
    );
  }

  void _showSortSheet(BuildContext context, SearchProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _SortSheet(provider: provider),
    );
  }
}

class _SortSheet extends StatelessWidget {
  final SearchProvider provider;
  const _SortSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    const options = [
      (null, 'Default'),
      ('departure', 'Earliest Departure'),
      ('price', 'Lowest Price'),
      ('duration', 'Shortest Duration'),
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort by',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...options.map((o) => ListTile(
                leading: Radio<String?>(
                  value: o.$1,
                  groupValue: provider.sortBy,
                  activeColor: AppTheme.primary,
                  onChanged: (v) {
                    provider.setSortBy(v);
                    provider.search();
                    Navigator.pop(context);
                  },
                ),
                title: Text(o.$2),
                onTap: () {
                  provider.setSortBy(o.$1);
                  provider.search();
                  Navigator.pop(context);
                },
              )),
        ],
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

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus_outlined, size: 64, color: AppTheme.outline),
          SizedBox(height: 16),
          Text('No buses found for this route & date.',
              style: TextStyle(color: AppTheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
