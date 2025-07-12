import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'update_profile_screen.dart';

class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      final authService = Provider.of<AuthService>(context, listen: false);
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => UpdateProfileScreen(
                            isFromOnboarding: false,
                            existingProfile: authService.userProfile,
                            autoPickImage: true,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      backgroundImage: _getAvatarImage(authService),
                      child: _getAvatarImage(authService) == null
                          ? Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.onPrimary,
                              size: 50,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authService.userDisplayName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 8),
                        if (authService.userProfile?.bio != null && authService.userProfile!.bio!.isNotEmpty) ...[
                          Text(
                            authService.userProfile!.bio!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (authService.userProfile?.origin != null && authService.userProfile!.origin!.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                authService.userProfile!.origin!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (authService.userProfile?.createdAt != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Joined ${_formatJoinDate(authService.userProfile!.createdAt!)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Travel Statistics
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Travel Statistics',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              context,
                              _formatNumber(authService.userProfile?.totalKm ?? 0.0),
                              'KM Traveled',
                              Icons.straighten_outlined,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              context,
                              '${authService.userProfile?.totalCountries ?? 0}',
                              'Countries',
                              Icons.public_outlined,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Travel Style',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildStyleTags(context, authService.userProfile?.styleTags ?? []),
                      const SizedBox(height: 32),
                      _buildCompactOptions(context, authService),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widgets and methods below --------------------------------------------------

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color, {
    bool isWide = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isWide
            ? Row(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                      ),
                      Text(
                        label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(icon, color: color, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStyleTags(BuildContext context, List<String> styleTags) {
    if (styleTags.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No travel styles added yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: styleTags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tag,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
          ),
        );
      }).toList(),
    );
  }

  String _formatJoinDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  Widget _buildCompactOptions(BuildContext context, AuthService authService) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCompactOption(
            context,
            Icons.edit_outlined,
            'Edit Profile',
            () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (context) => UpdateProfileScreen(
                    isFromOnboarding: false,
                    existingProfile: authService.userProfile,
                  ),
                ),
              );
              if (result == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profile updated successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          _buildCompactOption(
            context,
            Icons.settings_outlined,
            'Settings',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),
          _buildCompactOption(
            context,
            Icons.help_outline,
            'Help',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help coming soon!')),
              );
            },
          ),
          _buildCompactOption(
            context,
            Icons.info_outline,
            'About',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('About coming soon!')),
              );
            },
          ),
          _buildCompactOption(
            context,
            Icons.logout,
            'Sign Out',
            () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/onboarding',
                  (route) => false,
                );
              }
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  ImageProvider? _getAvatarImage(AuthService authService) {
    final profileAvatarUrl = authService.userProfile?.avatarUrl;
    final googleAvatarUrl = authService.userAvatarUrl;

    final avatarUrl = profileAvatarUrl?.isNotEmpty == true
        ? profileAvatarUrl
        : (googleAvatarUrl.isNotEmpty ? googleAvatarUrl : null);

    return avatarUrl != null ? NetworkImage(avatarUrl) : null;
  }

  Widget _buildCompactOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isDestructive
                  ? Colors.red
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDestructive
                        ? Colors.red
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 11,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------- end helpers
} 