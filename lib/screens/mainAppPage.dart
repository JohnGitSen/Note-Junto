import 'package:cloud_firestore/cloud_firestore.dart';
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
  String _username = '';
  Color _avatarColor = Colors.blueGrey;

  static const List<Color> _avatarColors = [
    Color.fromARGB(255, 99, 136, 255),
    Color.fromARGB(255, 255, 99, 132),
    Color.fromARGB(255, 99, 200, 132),
    Color.fromARGB(255, 255, 165, 0),
    Color.fromARGB(255, 180, 99, 255),
    Color.fromARGB(255, 0, 188, 212),
    Color.fromARGB(255, 255, 87, 34),
    Color.fromARGB(255, 76, 175, 80),
  ];

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists && mounted) {
      final username = doc.data()?['username'] as String? ?? '';
      final colorIndex = username.isNotEmpty
          ? username.codeUnitAt(0) % _avatarColors.length
          : 0;
      setState(() {
        _username = username;
        _avatarColor = _avatarColors[colorIndex];
      });
    }
  }

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
            // Navigate to view account screen
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
    final firstLetter = _username.isNotEmpty ? _username[0].toUpperCase() : '?';

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
            icon: CircleAvatar(
              backgroundColor: _avatarColor,
              radius: 18,
              child: Text(
                firstLetter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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
