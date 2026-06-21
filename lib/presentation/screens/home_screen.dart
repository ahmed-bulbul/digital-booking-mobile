import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/search_provider.dart';
import '../../data/models/auth_models.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SearchProvider>().loadRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(
        slivers: [
          _AppBar(user: auth.user),
          SliverToBoxAdapter(child: _SearchCard()),
          SliverToBoxAdapter(child: _StatsBar()),
          SliverToBoxAdapter(child: _PopularDestinations()),
          SliverToBoxAdapter(child: _WhyUs()),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  final dynamic user;
  const _AppBar({this.user});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00402F), AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _BubblePainter()),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 160,
              child: SvgPicture.asset(
                'assets/images/banner_illustration.svg',
                fit: BoxFit.fill,
              ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_bus, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'JatraXpress',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
          ),
        ],
      ),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        else
          TextButton(
            onPressed: () => context.push('/login'),
            child: const Text('Sign In',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}

class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.05);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.3), 60, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.7), 80, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SearchCard extends StatefulWidget {
  @override
  State<_SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<_SearchCard> {
  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Find your bus',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.onSurface,
                ),
          ),
          const SizedBox(height: 16),
          _CityInputs(provider: searchProvider),
          const SizedBox(height: 12),
          _DatePicker(provider: searchProvider),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: searchProvider.selectedRoute == null
                ? null
                : () {
                    context.push('/search');
                  },
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Search Buses'),
          ),
        ],
      ),
    );
  }
}

class _CityInputs extends StatefulWidget {
  final SearchProvider provider;
  const _CityInputs({required this.provider});

  @override
  State<_CityInputs> createState() => _CityInputsState();
}

class _CityInputsState extends State<_CityInputs> {
  String? _from;
  String? _to;

  void _tryMatchRoute() {
    if (_from == null || _to == null) return;
    final routes = widget.provider.routes;
    final match = routes.cast<RouteOption?>().firstWhere(
          (r) => r!.sourceName == _from && r.destinationName == _to,
          orElse: () => null,
        );
    if (match != null) widget.provider.setRoute(match);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.provider.loadingRoutes) {
      return const LinearProgressIndicator();
    }

    if (widget.provider.routesError != null) {
      return Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.provider.routesError!,
              style: const TextStyle(color: AppTheme.error, fontSize: 11),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => widget.provider.loadRoutes(forceReload: true),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    final routes = widget.provider.routes;
    final fromCities = routes.map((r) => r.sourceName).toSet().toList()..sort();
    final toCities = routes.map((r) => r.destinationName).toSet().toList()..sort();

    return Column(
      children: [
        _CityAutocomplete(
          label: 'From',
          icon: Icons.trip_origin_outlined,
          cities: fromCities,
          onSelected: (city) {
            setState(() => _from = city);
            _tryMatchRoute();
          },
        ),
        const SizedBox(height: 12),
        _CityAutocomplete(
          label: 'To',
          icon: Icons.location_on_outlined,
          cities: toCities,
          onSelected: (city) {
            setState(() => _to = city);
            _tryMatchRoute();
          },
        ),
      ],
    );
  }
}

class _CityAutocomplete extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<String> cities;
  final ValueChanged<String> onSelected;

  const _CityAutocomplete({
    required this.label,
    required this.icon,
    required this.cities,
    required this.onSelected,
  });

  @override
  State<_CityAutocomplete> createState() => _CityAutocompleteState();
}

class _CityAutocompleteState extends State<_CityAutocomplete> {
  // Once a city is confirmed, suppress options until the text changes away.
  String? _confirmedValue;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (textValue) {
        final text = textValue.text;
        // Hide dropdown when the field still holds the confirmed selection.
        if (text == _confirmedValue) return const Iterable<String>.empty();
        if (text.isEmpty) return widget.cities;
        return widget.cities.where(
          (c) => c.toLowerCase().contains(text.toLowerCase()),
        );
      },
      onSelected: (value) {
        setState(() => _confirmedValue = value);
        widget.onSelected(value);
      },
      fieldViewBuilder: (ctx, controller, focusNode, onSubmit) {
        // Clear confirmed value when user edits text manually.
        controller.addListener(() {
          if (_confirmedValue != null && controller.text != _confirmedValue) {
            setState(() => _confirmedValue = null);
          }
        });
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            hintText: widget.label,
            prefixIcon: Icon(widget.icon, size: 20, color: AppTheme.onSurfaceVariant),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFBFC9C4)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFBFC9C4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        );
      },
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (_, i) {
                  final city = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_city_outlined,
                        size: 18, color: AppTheme.primary),
                    title: Text(city, style: const TextStyle(fontSize: 14)),
                    onTap: () => onSelected(city),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DatePicker extends StatelessWidget {
  final SearchProvider provider;
  const _DatePicker({required this.provider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: provider.travelDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(primary: AppTheme.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) provider.setDate(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFBFC9C4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 20, color: AppTheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              AppDateUtils.formatDate(provider.travelDate),
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsBar extends StatelessWidget {
  static const _stats = [
    ('50K+', 'Travelers'),
    ('120+', 'Routes'),
    ('4.9★', 'Rating'),
    ('24/7', 'Support'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFC9C4).withOpacity(0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _stats.map((s) {
          return Column(
            children: [
              Text(s.$1,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primary)),
              Text(s.$2,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.onSurfaceVariant)),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PopularDestinations extends StatelessWidget {
  static const _destinations = [
    _DestData('Dhaka → Chittagong', '৳850', 'Most Popular'),
    _DestData('Dhaka → Cox\'s Bazar', '৳1,200', 'Selling Fast'),
    _DestData('Dhaka → Sylhet', '৳700', 'Tea Garden Route'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Popular Routes',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ]),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _destinations.length,
            itemBuilder: (ctx, i) => _DestCard(data: _destinations[i]),
          ),
        ),
      ],
    );
  }
}

class _DestData {
  final String title;
  final String price;
  final String badge;
  const _DestData(this.title, this.price, this.badge);
}

class _DestCard extends StatelessWidget {
  final _DestData data;
  const _DestCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/search'),
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF00B37A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(data.badge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            Text(data.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            const SizedBox(height: 4),
            Text('from ${data.price}',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.85), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _WhyUs extends StatefulWidget {
  @override
  State<_WhyUs> createState() => _WhyUsState();
}

class _WhyUsState extends State<_WhyUs> with SingleTickerProviderStateMixin {
  static const _features = [
    (Icons.verified_user_outlined, 'Safety First', 'Monitored journeys & trained drivers'),
    (Icons.confirmation_number_outlined, 'e-Tickets', 'Instant digital tickets'),
    (Icons.support_agent_outlined, '24/7 Support', 'Always here for you'),
    (Icons.event_repeat_outlined, 'Easy Reschedule', 'Change plans hassle-free'),
  ];

  late AnimationController _controller;
  late List<Animation<double>> _fadeAnims;
  late List<Animation<Offset>> _slideAnims;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnims = List.generate(_features.length, (i) {
      final start = (i * 0.18).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      );
    });

    _slideAnims = List.generate(_features.length, (i) {
      final start = (i * 0.18).clamp(0.0, 1.0);
      final end = (start + 0.5).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0.25, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Text(
            'Why JatraXpress',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _features.length,
            separatorBuilder: (context, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final f = _features[i];
              return FadeTransition(
                opacity: _fadeAnims[i],
                child: SlideTransition(
                  position: _slideAnims[i],
                  child: _FeatureCard(icon: f.$1, title: f.$2, subtitle: f.$3),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 158,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFC9C4).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Text(
              subtitle,
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
