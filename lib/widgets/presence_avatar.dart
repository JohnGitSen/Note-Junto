import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notesharingapp/widgets/user_color.dart';

class PresenceAvatar extends StatefulWidget {
  final String uid;
  final Map<String, dynamic> data;

  const PresenceAvatar({super.key, required this.uid, required this.data});

  @override
  State<PresenceAvatar> createState() => _PresenceAvatarState();
}

class _PresenceAvatarState extends State<PresenceAvatar>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  Timer? _dismissTimer;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _removeOverlay();
    _animController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showTag(BuildContext context) {
    // Dismiss any existing tag first
    _dismissTimer?.cancel();
    if (_overlayEntry != null) {
      _animController.reverse().then((_) => _removeOverlay());
      return; // toggle off if already showing
    }

    final username = widget.data['username'] as String? ?? '?';
    final isTyping = widget.data['isTyping'] as bool? ?? false;
    final color = userColor(widget.uid);
    final initials = username.trim().isNotEmpty
        ? username.trim()[0].toUpperCase()
        : '?';

    // Find the avatar's position on screen
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        // Center the tag horizontally under the avatar, below the AppBar area
        left: (offset.dx + size.width / 2 - 90).clamp(8.0, double.infinity),
        top: offset.dy + size.height + 6,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 180,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color.fromARGB(242, 30, 38, 54),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTyping
                      ? Colors.greenAccent.withOpacity(0.6)
                      : color.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: color,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isTyping ? '$username is typing...' : username,
                      style: TextStyle(
                        color: isTyping ? Colors.greenAccent : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isTyping) ...[
                    const SizedBox(width: 6),
                    const SizedBox(
                      width: 9,
                      height: 9,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();

    // Auto-dismiss after 2.5 seconds
    _dismissTimer = Timer(const Duration(milliseconds: 2500), () {
      _animController.reverse().then((_) {
        if (mounted) _removeOverlay();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final username = widget.data['username'] as String? ?? '?';
    final isTyping = widget.data['isTyping'] as bool? ?? false;
    final color = userColor(widget.uid);
    final initials = username.trim().isNotEmpty
        ? username.trim()[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => _showTag(context),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isTyping ? Colors.greenAccent : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: color,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            if (isTyping)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
