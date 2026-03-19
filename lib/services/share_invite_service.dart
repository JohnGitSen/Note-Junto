// ── share_invite_service.dart ─────────────────────────────────────────────────
// Put this in lib/services/
//
// Firestore structure for an invite document (collection: share-invites):
// {
//   noteId:        String   — the note being shared
//   noteTitle:     String   — title of the note (for display)
//   ownerUid:      String   — uid of person sharing
//   ownerEmail:    String   — email of person sharing
//   ownerUsername: String   — display name of person sharing
//   toEmail:       String   — email of recipient
//   status:        String   — 'pending' | 'accepted' | 'declined'
//   createdAt:     Timestamp
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ShareInviteService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ── Called from share_dialog when owner adds an email ────────────────────────
  // Instead of directly adding to sharedWith, creates a pending invite
  static Future<void> sendInvite({
    required String noteId,
    required String noteTitle,
    required String toEmail,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Fetch owner username for display in the notification
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final ownerUsername =
        userDoc.data()?['username'] as String? ?? user.email ?? 'Someone';

    // Check if invite already pending for this note + recipient
    final existing = await _firestore
        .collection('share-invites')
        .where('noteId', isEqualTo: noteId)
        .where('toEmail', isEqualTo: toEmail)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existing.docs.isNotEmpty) return; // already invited, skip

    await _firestore.collection('share-invites').add({
      'noteId': noteId,
      'noteTitle': noteTitle,
      'ownerUid': user.uid,
      'ownerEmail': user.email ?? '',
      'ownerUsername': ownerUsername,
      'toEmail': toEmail,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Accept invite — adds user to sharedWith and marks invite accepted ────────
  static Future<void> acceptInvite(String inviteId, String noteId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final batch = _firestore.batch();

    // Add current user's email to the note's sharedWith array
    batch.update(_firestore.collection('notes').doc(noteId), {
      'sharedWith': FieldValue.arrayUnion([user.email]),
      'isShared': true,
    });

    // Mark invite as accepted
    batch.update(_firestore.collection('share-invites').doc(inviteId), {
      'status': 'accepted',
    });

    await batch.commit();
  }

  // ── Decline invite — just marks it declined ──────────────────────────────────
  static Future<void> declineInvite(String inviteId) async {
    await _firestore.collection('share-invites').doc(inviteId).update({
      'status': 'declined',
    });
  }

  // ── Stream of pending invites for the current user ───────────────────────────
  static Stream<QuerySnapshot> pendingInvitesStream() {
    final email = _auth.currentUser?.email;
    if (email == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('share-invites')
        .where('toEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
