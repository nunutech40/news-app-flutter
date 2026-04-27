import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_app/features/auth/presentation/widgets/edit_profile_bottom_sheet.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () {
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return const Center(child: Text('Profile not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    image: (user.avatarUrl.isNotEmpty)
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(user.avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user.avatarUrl.isEmpty
                      ? const Icon(Icons.person, size: 60, color: AppTheme.textMuted)
                      : null,
                ),
                const SizedBox(height: 16),

                // Name & Email
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 32),

                // Edit Button
                ElevatedButton.icon(
                  onPressed: () => EditProfileBottomSheet.show(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),

                const SizedBox(height: 40),

                // Details Card
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileRowItem(
                        icon: Icons.info_outline,
                        label: 'Bio',
                        value: user.bio.isEmpty ? 'Say something about yourself' : user.bio,
                      ),
                      const Divider(height: 32),
                      _ProfileRowItem(
                        icon: Icons.phone_outlined,
                        label: 'Phone Number',
                        value: user.phone.isEmpty ? 'Not set' : user.phone,
                      ),
                      const Divider(height: 32),
                      _ProfileRowItem(
                        icon: Icons.local_offer_outlined,
                        label: 'Preferences',
                        value: (user.preferences.isEmpty || user.preferences == '{}') 
                            ? 'No topics selected' 
                            : user.preferences.split(',').map((e) => e[0].toUpperCase() + e.substring(1)).join(', '),
                      ),
                      const Divider(height: 32),
                      _ProfileRowItem(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member Since',
                        value: user.createdAt != null 
                            ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                            : 'Unknown',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileRowItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileRowItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
