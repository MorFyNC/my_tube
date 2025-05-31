import 'package:flutter/material.dart';
import 'package:my_tube/pages/home_page.dart';
import 'package:my_tube/pages/search_page.dart';
import 'package:my_tube/pages/upload_page.dart';
import 'package:my_tube/widgets/bottom_nav_bar.dart';

import 'profile_page.dart';

class MainPageWrapper extends StatefulWidget {
  const MainPageWrapper({super.key});

  @override
  State<MainPageWrapper> createState() => _MainPageWrapperState();
}

class _MainPageWrapperState extends State<MainPageWrapper> {
  int _currentIndex = 0;

  Widget getPage(int index) {
  switch (index) {
    case 0: return HomePage(key: UniqueKey());
    case 1: return UploadVideoPage(key: UniqueKey());
    case 2: return ProfilePage(key: UniqueKey());
    default: return HomePage(key: UniqueKey());
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyTube',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => SearchPage()));
            },
          ),
        ],
      ),
      body: Center(
        child: getPage(_currentIndex), 
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}