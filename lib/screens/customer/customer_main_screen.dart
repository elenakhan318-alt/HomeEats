import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'favourites_data.dart';

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
  @override
void initState() {
  super.initState();

  favouritesData.loadFavourites();
}

  final List<Widget> _pages = const [
  CustomerHomeScreen(),
  SearchScreen(),
  BasketScreen(),
  NotificationsScreen(),
  ProfileScreen(),
];
Future<void> _markNotificationsAsRead() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return;
  }

  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final document in snapshot.docs) {
      batch.update(document.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  } catch (error) {
    debugPrint(
      'Notifications could not be marked as read: $error',
    );
  }
}
  void _changePage(int index) {
  setState(() {
    _selectedIndex = index;
  });

  if (index == 3) {
    _markNotificationsAsRead();
  }
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
        destinations: [
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
  icon: StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('notifications')
        .where(
          'userId',
          isEqualTo: FirebaseAuth.instance.currentUser?.uid,
        )
        .where('isRead', isEqualTo: false)
        .snapshots(),
    builder: (context, snapshot) {
      final unreadCount = snapshot.data?.docs.length ?? 0;

      return Badge(
        isLabelVisible: unreadCount > 0,
        label: Text(
          unreadCount > 9 ? '9+' : unreadCount.toString(),
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
        ),
      );
    },
  ),
  selectedIcon: const Icon(
    Icons.notifications_rounded,
  ),
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