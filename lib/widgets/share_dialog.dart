import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

Future<bool> doesUserExist(String email) async {
  final query = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isEqualTo: email)
      .limit(1)
      .get();
  return query.docs.isNotEmpty;
}

void openShareDialog(
  BuildContext context,
  List<String> sharedWith,
  VoidCallback onUpdate,
) {
  final TextEditingController emailController = TextEditingController();
  bool isChecking = false;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future<void> addEmail() async {
            final email = emailController.text.trim();
            final currentUserEmail =
                FirebaseAuth.instance.currentUser?.email ?? '';

            if (email.isEmpty || !email.contains('@')) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Enter a valid email!')),
              );
              return;
            }
            if (email == currentUserEmail) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text("You can't share a note with yourself!"),
                ),
              );
              return;
            }
            if (sharedWith.contains(email)) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Already added this email!')),
              );
              return;
            }

            setDialogState(() => isChecking = true);
            final exists = await doesUserExist(email);
            setDialogState(() => isChecking = false);

            if (!exists) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text(
                    'User not found! Make sure they have an account.',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }

            setDialogState(() => sharedWith.add(email));
            onUpdate();
            emailController.clear();
          }

          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 38, 47, 66),
            title: const Text(
              'Share Note',
              style: TextStyle(color: Colors.white),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: (_) => addEmail(),
                          decoration: InputDecoration(
                            hintText: 'Enter email address',
                            hintStyle: const TextStyle(color: Colors.white38),
                            filled: true,
                            fillColor: const Color.fromARGB(255, 55, 65, 85),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      isChecking
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color.fromARGB(255, 172, 202, 255),
                              ),
                            )
                          : IconButton(
                              onPressed: addEmail,
                              icon: const Icon(
                                Icons.add_circle,
                                color: Color.fromARGB(255, 172, 202, 255),
                                size: 32,
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sharedWith.isNotEmpty) ...[
                    const Text(
                      'Shared with:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ...sharedWith.map(
                      (email) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 55, 65, 85),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.person,
                                color: Colors.white54,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  email,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setDialogState(
                                    () => sharedWith.remove(email),
                                  );
                                  onUpdate();
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ] else
                    const Text(
                      'No one added yet.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Color.fromARGB(255, 172, 202, 255)),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
