import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  String _username = '';
  String _email = '';
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
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && mounted) {
      final username = doc.data()?['username'] as String? ?? '';
      final colorIndex = username.isNotEmpty
          ? username.codeUnitAt(0) % _avatarColors.length
          : 0;
      setState(() {
        _username = username;
        _email = user.email ?? '';
        _avatarColor = _avatarColors[colorIndex];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstLetter = _username.isNotEmpty ? _username[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 14, 17, 22),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 38, 47, 66),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.north_west_rounded,
            size: 30,
            color: Color.fromARGB(255, 177, 206, 255),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "My Account",
          style: TextStyle(
            color: Color.fromARGB(255, 177, 206, 255),
            fontSize: 20,
          ),
        ),
      ),
      body: _username.isEmpty
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 177, 206, 255),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  CircleAvatar(
                    backgroundColor: _avatarColor,
                    radius: 48,
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    _username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    _email,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 130, 150, 180),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Info card
                  Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 28, 35, 50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _infoTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Username',
                          value: _username,
                        ),
                        const Divider(
                          color: Color.fromARGB(255, 45, 55, 75),
                          height: 1,
                          indent: 56,
                        ),
                        _infoTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: _email,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color.fromARGB(255, 177, 206, 255)),
      title: Text(
        label,
        style: const TextStyle(
          color: Color.fromARGB(255, 130, 150, 180),
          fontSize: 12,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(color: Colors.white, fontSize: 15),
      ),
    );
  }
}
