import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../auth/welcome_screen.dart';
import 'favourites_screen.dart';
import 'order_history_screen.dart';
import 'payment_methods_screen.dart';
import 'saved_addresses_screen.dart';
import 'active_orders_screen.dart';
import 'edit_profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'contact_homeeats_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.regular,
            AppSpacing.page,
            110,
          ),
          child: Column(
            children: [
            _buildProfileHeader(context),
              const SizedBox(height: AppSpacing.large),
              _buildAccountSection(context),
              const SizedBox(height: AppSpacing.large),
              _buildSavedSection(context),
              const SizedBox(height: AppSpacing.large),
              _buildSettingsSection(context),
              const SizedBox(height: AppSpacing.large),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

 Widget _buildProfileHeader(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return const SizedBox.shrink();
  }

  return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.large),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final data = snapshot.data?.data();

      final fullName =
          (data?['fullName'] ?? 'User').toString();

      final email =
          (data?['email'] ?? user.email ?? '').toString();

      final phone =
          (data?['phone'] ?? '').toString();

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.primaryLight,
              child: Icon(
                Icons.person_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.regular),
            Text(
              fullName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              email,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                phone,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}
  Widget _buildAccountSection(BuildContext context) {
    return _buildSection(
      title: 'My Account',
      children: [
        _buildProfileTile(
          icon: Icons.receipt_long_outlined,
          title: 'Order History',
          subtitle: 'View your previous orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderHistoryScreen(),
              ),
            );
          },
        ),
        _buildDivider(),
        _buildProfileTile(
          icon: Icons.delivery_dining_outlined,
          title: 'Active Orders',
          subtitle: 'Track current orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ActiveOrdersScreen(),
              ),
            );
          },
        ),
        _buildDivider(),
      _buildProfileTile(
  icon: Icons.person_outline_rounded,
  title: 'Edit Profile',
  subtitle: 'Update your personal information',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  },
),
      ],
    );
  }

  Widget _buildSavedSection(BuildContext context) {
    return _buildSection(
      title: 'Saved',
      children: [
        _buildProfileTile(
          icon: Icons.favorite_border_rounded,
          title: 'Favourite Meals',
          subtitle: 'Meals you have saved',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavouritesScreen()),
            );
          },
        ),
        _buildDivider(),
        _buildProfileTile(
          icon: Icons.location_on_outlined,
          title: 'Saved Addresses',
          subtitle: 'Manage delivery addresses',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedAddressesScreen(),
              ),
            );
          },
        ),
        _buildDivider(),
        _buildProfileTile(
          icon: Icons.credit_card_outlined,
          title: 'Payment Methods',
          subtitle: 'Manage cards and payment options',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentMethodsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return _buildSection(
      title: 'Settings',
      children: [
        _buildProfileTile(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          subtitle: 'Order and promotional notifications',
          onTap: () {
            _showMessage(context, 'Notification settings will open here.');
          },
        ),
        _buildDivider(),
        _buildProfileTile(
          icon: Icons.help_outline_rounded,
          title: 'Help Centre',
          subtitle: 'Get help with your account or orders',
          onTap: () {
            _showMessage(context, 'Help centre will open here.');
          },
        ),
        _buildDivider(),
        _buildProfileTile(
  icon: Icons.support_agent_rounded,
  title: 'Contact HomeEats',
  subtitle: 'Send a message to the HomeEats team',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const ContactHomeEatsScreen(),
      ),
    );
  },
),
_buildDivider(),
        _buildProfileTile(
          icon: Icons.info_outline_rounded,
          title: 'About',
          subtitle: 'About Home Food Marketplace',
          onTap: () {
            _showMessage(context, 'About page will open here.');
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.regular),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: 2,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 58),
      child: Divider(height: 1),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
          );
        },
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: const Text(
          'Log Out',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
