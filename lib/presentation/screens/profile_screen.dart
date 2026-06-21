import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isLoggedIn || auth.user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign In'),
          ),
        ),
      );
    }

    final user = auth.user!;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        children: [
          _ProfileHeader(name: user.name, email: user.email),
          const SizedBox(height: 16),
          _Section(
            title: 'Account',
            items: [
              _TileData(
                icon: Icons.person_outlined,
                label: 'Name',
                value: user.name,
              ),
              _TileData(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              if (user.phone != null)
                _TileData(
                  icon: Icons.phone_outlined,
                  label: 'Phone',
                  value: user.phone!,
                ),
            ],
          ),
          _Section(
            title: 'Support',
            items: [
              _TileData(
                icon: Icons.help_outline,
                label: 'Help Center',
                onTap: () {},
              ),
              _TileData(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy Policy',
                onTap: () {},
              ),
              _TileData(
                icon: Icons.description_outlined,
                label: 'Terms of Service',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/');
              },
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: const Text('Sign Out',
                  style: TextStyle(color: AppTheme.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.error.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  const _ProfileHeader({required this.name, required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF00B37A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(email,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TileData {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  const _TileData({required this.icon, required this.label, this.value, this.onTap});
}

class _Section extends StatelessWidget {
  final String title;
  final List<_TileData> items;
  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, top: 8),
            child: Text(title,
                style: const TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: const Color(0xFFBFC9C4).withOpacity(0.5)),
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    ListTile(
                      leading:
                          Icon(item.icon, color: AppTheme.primary, size: 20),
                      title: Text(item.label,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: item.value != null
                          ? Text(item.value!,
                              style: const TextStyle(
                                  color: AppTheme.onSurfaceVariant,
                                  fontSize: 13))
                          : null,
                      trailing: item.onTap != null
                          ? const Icon(Icons.arrow_forward_ios,
                              size: 14, color: AppTheme.onSurfaceVariant)
                          : null,
                      onTap: item.onTap,
                    ),
                    if (i < items.length - 1)
                      const Divider(height: 1, indent: 56),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
