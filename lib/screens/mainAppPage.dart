import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:notesharingapp/NavBarScreens/myNotesScreen.dart';
import 'package:notesharingapp/NavBarScreens/settingScreen.dart';
import 'package:notesharingapp/NavBarScreens/sharedNotesScreen.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({super.key});

  @override
  State<MainAppPage> createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  int _selectedIndex = 0;

  void _selectionBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logout failed: ${e.toString()}")),
        );
      }
    }
  }

  void _showUserMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero, ancestor: overlay);

    showMenu<void>(
      context: context,
      color: const Color.fromARGB(255, 45, 45, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + button.size.height + 4,
        offset.dx + button.size.width + 160,
        0,
      ),
      items: [
        PopupMenuItem(
          onTap: () {
            // Navigate to view account screen , ala pa ako idea
          },
          child: Row(
            children: const [
              Icon(
                Icons.account_circle_outlined,
                color: Color.fromARGB(255, 200, 200, 200),
                size: 26,
              ),
              SizedBox(width: 14),
              Text(
                "View Account",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          onTap: () async {
            await Future.delayed(const Duration(milliseconds: 150));
            _handleLogout();
          },
          child: Row(
            children: const [
              Icon(
                Icons.logout_rounded,
                color: Color.fromARGB(255, 200, 200, 200),
                size: 26,
              ),
              SizedBox(width: 14),
              Text(
                "Logout",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  final List<Widget> _navBarScreensList = [
    MyNotesPage(),
    SharedNotesPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        titleTextStyle: const TextStyle(
          color: Color.fromARGB(255, 177, 206, 255),
          fontSize: 20,
        ),
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        automaticallyImplyLeading: false,
        leading: Builder(
          builder: (ctx) => IconButton(
            onPressed: () => _showUserMenu(ctx),
            icon: Container(
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 210, 210, 210),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.person,
                color: Color.fromARGB(255, 60, 60, 60),
                size: 22,
              ),
            ),
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.refresh_rounded,
              color: Color.fromARGB(255, 177, 206, 255),
              size: 30,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.search_rounded,
              color: Color.fromARGB(255, 177, 206, 255),
              size: 30,
            ),
          ),
        ],
      ),
      body: _navBarScreensList[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        selectedItemColor: const Color.fromARGB(255, 197, 225, 233),
        unselectedItemColor: const Color.fromARGB(255, 14, 17, 22),
        currentIndex: _selectedIndex,
        onTap: _selectionBottomBar,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.note), label: "My Notes"),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Shared Notes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
