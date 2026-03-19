import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ArchiveNotesService {
  static Future<void> showArchiveDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 28, 35, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(
          Icons.archive_rounded,
          color: Color.fromARGB(255, 177, 206, 255),
          size: 44,
        ),
        title: const Text(
          'Archive Notes',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFFEAEFF8),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This will create an archive backup of all your current notes into a separate collection.\n\nYour original notes will not be deleted.\n\nYou can restore from this archive later in Settings.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8A96B0), fontSize: 13, height: 1.6),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 177, 206, 255),
                      foregroundColor: const Color.fromARGB(255, 14, 17, 22),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Archive Now',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF8A96B0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color.fromARGB(255, 28, 35, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        content: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color.fromARGB(255, 177, 206, 255),
              ),
              SizedBox(height: 20),
              Text(
                'Archiving your notes...',
                style: TextStyle(color: Color(0xFFEAEFF8), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await _performArchive();
      if (context.mounted) Navigator.pop(context); // close loading
      if (context.mounted) _showSuccessSnack(context);
    } catch (e) {
      if (context.mounted) Navigator.pop(context); // close loading
      if (context.mounted) _showErrorSnack(context, e.toString());
    }
  }

  static Future<void> _performArchive() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final firestore = FirebaseFirestore.instance;

    final notesSnapshot = await firestore
        .collection('notes')
        .where('ownerUid', isEqualTo: uid)
        .get();

    if (notesSnapshot.docs.isEmpty) return;


    final batch = firestore.batch();

    for (final doc in notesSnapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());

      data['originalNoteId'] = doc.id;
      data['archivedAt'] = FieldValue.serverTimestamp();
      data['archivedByUid'] = uid;

      final archiveDocRef = firestore
          .collection('notes-archive-backup')
          .doc(); 

      batch.set(archiveDocRef, data);
    }

    await batch.commit();
  }

  static void _showSuccessSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notes archived successfully!'),
        backgroundColor: const Color.fromARGB(255, 99, 167, 255),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  static void _showErrorSnack(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Archive failed: $error'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
