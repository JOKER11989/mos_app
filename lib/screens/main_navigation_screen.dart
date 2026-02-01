import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'favorites_screen.dart';
import 'auctions_screen.dart';
import 'purchases_screen.dart';
import 'notifications_screen.dart';

import 'package:curved_labeled_navigation_bar/curved_navigation_bar.dart';
import 'package:curved_labeled_navigation_bar/curved_navigation_bar_item.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // Start with Home (الرئيسية)

  final List<Widget> _screens = const [
    NotificationsScreen(),
    PurchasesScreen(),
    HomeScreen(),
    AuctionsScreen(),
    FavoritesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        color: const Color(0xFF1E1E1E),
        buttonBackgroundColor: Colors.blueAccent,
        items: [
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 0
                  ? Icons.notifications
                  : Icons.notifications_outlined,
              color: _currentIndex == 0 ? Colors.white : Colors.grey,
            ),
            label: 'الإشعارات',
          ),
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 1
                  ? Icons.shopping_bag
                  : Icons.shopping_bag_outlined,
              color: _currentIndex == 1 ? Colors.white : Colors.grey,
            ),
            label: 'المشتريات',
          ),
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 2 ? Icons.home : Icons.home_outlined,
              color: _currentIndex == 2 ? Colors.white : Colors.grey,
            ),
            label: 'الرئيسية',
          ),
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 3 ? Icons.gavel : Icons.gavel_outlined,
              color: _currentIndex == 3 ? Colors.white : Colors.grey,
            ),
            label: 'المناقصات',
          ),
          CurvedNavigationBarItem(
            child: Icon(
              _currentIndex == 4 ? Icons.favorite : Icons.favorite_border,
              color: _currentIndex == 4 ? Colors.white : Colors.grey,
            ),
            label: 'المفضلة',
          ),
        ],
      ),
    );
  }
}
