import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'basket_screen.dart';
import 'customer_home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() =>
      _CustomerMainScreenState();
}

class _CustomerMainScreenState
    extends State<CustomerMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
  CustomerHomeScreen(),
  SearchScreen(),
  BasketScreen(),
  NotificationsScreen(),
  ProfileScreen(),
];
  void _changePage(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _changePage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_basket_outlined),
            selectedIcon: Icon(Icons.shopping_basket_rounded),
            label: 'Basket',
          ),
          NavigationDestination(
  icon: Icon(Icons.notifications_none_rounded),
  selectedIcon: Icon(Icons.notifications_rounded),
  label: 'Alerts',
),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}