// ── share_invites_bell.dart ───────────────────────────────────────────────────
// Put this in lib/widgets/
// Drop this widget into the mainAppPage appbar actions.
// It shows a bell icon with a red badge count of pending invites.
// Tapping it opens a bottom sheet listing all pending invites.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:notesharingapp/services/share_invite_service.dart';

class ShareInvitesBell extends StatelessWidget {
  const ShareInvitesBell({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: ShareInviteService.pendingInvitesStream(),
      builder: (context, snapshot) {
        final invites = snapshot.data?.docs ?? [];
        final count = invites.length;

        return GestureDetector(
          onTap: count == 0
              ? null
              : () => _showInvitesSheet(context, invites),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  count > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_none_rounded,
                  color: count > 0
                      ? const Color.fromARGB(255, 177, 206, 255)
                      : const Color.fromARGB(255, 100, 120, 150),
                  size: 28,
                ),
                if (count > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF5C5C),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showInvitesSheet(
      BuildContext context, List<QueryDocumentSnapshot> invites) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color.fromARGB(255, 28, 35, 50),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (_) => _InvitesSheet(invites: invites),
    );
  }
}

// ── Bottom sheet that lists all pending invites ───────────────────────────────
class _InvitesSheet extends StatefulWidget {
  final List<QueryDocumentSnapshot> invites;
  const _InvitesSheet({required this.invites});

  @override
  State<_InvitesSheet> createState() => _InvitesSheetState();
}

class _InvitesSheetState extends State<_InvitesSheet> {
  // Track which invite IDs are currently loading (accept/decline in progress)
  final Set<String> _loadingIds = {};

  Future<void> _accept(String inviteId, String noteId) async {
    setState(() => _loadingIds.add(inviteId));
    try {
      await ShareInviteService.acceptInvite(inviteId, noteId);
    } finally {
      if (mounted) setState(() => _loadingIds.remove(inviteId));
    }
  }

  Future<void> _decline(String inviteId) async {
    setState(() => _loadingIds.add(inviteId));
    try {
      await ShareInviteService.declineInvite(inviteId);
    } finally {
      if (mounted) setState(() => _loadingIds.remove(inviteId));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-listen to the stream inside the sheet so it auto-updates as user
    // accepts/declines without needing to close and reopen
    return StreamBuilder<QuerySnapshot>(
      stream: ShareInviteService.pendingInvitesStream(),
      builder: (context, snapshot) {
        final invites = snapshot.data?.docs ?? [];

        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(100, 177, 206, 255),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_rounded,
                      color: Color.fromARGB(255, 177, 206, 255),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Share Requests',
                      style: TextStyle(
                        color: Color.fromARGB(255, 177, 206, 255),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              const Divider(
                color: Color.fromARGB(40, 177, 206, 255),
                height: 1,
              ),

              // Invite list
              invites.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color.fromARGB(255, 80, 100, 130),
                            size: 40,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'All caught up!',
                            style: TextStyle(
                              color: Color.fromARGB(255, 130, 150, 180),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: invites.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = invites[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final inviteId = doc.id;
                          final noteId = data['noteId'] as String? ?? '';
                          final noteTitle =
                              data['noteTitle'] as String? ?? 'Untitled';
                          final ownerUsername =
                              data['ownerUsername'] as String? ?? 'Someone';
                          final ownerEmail =
                              data['ownerEmail'] as String? ?? '';
                          final isLoading = _loadingIds.contains(inviteId);

                          return Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 38, 47, 66),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar circle with first letter
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 50, 65, 95),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color.fromARGB(
                                          80, 177, 206, 255),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      ownerUsername.isNotEmpty
                                          ? ownerUsername[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: Color.fromARGB(
                                            255, 177, 206, 255),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Text info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            color: Color.fromARGB(
                                                255, 200, 215, 235),
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: ownerUsername,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const TextSpan(
                                                text: ' wants to share '),
                                            TextSpan(
                                              text: '"$noteTitle"',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color.fromARGB(
                                                    255, 177, 206, 255),
                                              ),
                                            ),
                                            const TextSpan(text: ' with you'),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        ownerEmail,
                                        style: const TextStyle(
                                          color: Color.fromARGB(
                                              255, 80, 100, 130),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Accept / Decline buttons
                                isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color.fromARGB(
                                              255, 177, 206, 255),
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Decline (X)
                                          GestureDetector(
                                            onTap: () =>
                                                _decline(inviteId),
                                            child: Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 60, 30, 35),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color.fromARGB(
                                                      100, 255, 92, 92),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                color: Color(0xFFFF5C5C),
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Accept (check)
                                          GestureDetector(
                                            onTap: () =>
                                                _accept(inviteId, noteId),
                                            child: Container(
                                              width: 34,
                                              height: 34,
                                              decoration: BoxDecoration(
                                                color: const Color.fromARGB(
                                                    255, 25, 55, 45),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color.fromARGB(
                                                      100, 100, 220, 150),
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: Color(0xFF64DC96),
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}