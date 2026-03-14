import 'package:flutter/material.dart';

// Pastel color palette for notes
const List<Color> kNoteColors = [
  Color(0xFFFCE594), // default yellow (existing)
  Color(0xFFFFD6D6), // pastel red/pink
  Color(0xFFFFE0CC), // pastel orange
  Color(0xFFFFF5CC), // pastel lemon
  Color(0xFFD6F5D6), // pastel green
  Color(0xFFCCF0F5), // pastel cyan
  Color(0xFFCCE0FF), // pastel blue
  Color(0xFFE8CCFF), // pastel purple
  Color(0xFFFFCCF0), // pastel rose
  Color(0xFFF5F5F5), // near white
  Color(0xFFE8E0D5), // warm sand
  Color(0xFFD5E8E0), // sage
];

// Convert Color to hex string for Firestore storage
String colorToHex(Color color) {
  return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}

// Convert hex string back to Color
Color hexToColor(String hex) {
  try {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    } else if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
  } catch (_) {}
  return kNoteColors[0];
}

class NoteColorPicker extends StatefulWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const NoteColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  State<NoteColorPicker> createState() => _NoteColorPickerState();
}

class _NoteColorPickerState extends State<NoteColorPicker>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late AnimationController _animController;
  late Animation<double> _heightAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0, // starts expanded
    );
    _heightAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Color swatches row — animates in/out
        SizeTransition(
          sizeFactor: _heightAnim,
          axisAlignment: -1,
          child: Container(
            color: const Color.fromARGB(255, 38, 47, 66),
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: kNoteColors.length,
              itemBuilder: (context, index) {
                final color = kNoteColors[index];
                final isSelected = widget.selectedColor.value == color.value;

                return GestureDetector(
                  onTap: () => widget.onColorSelected(color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromARGB(255, 177, 206, 255)
                            : Colors.white.withOpacity(0.4),
                        width: isSelected ? 2.5 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Color.fromARGB(180, 0, 0, 0),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ),

        // Collapse / expand tab
        GestureDetector(
          onTap: _toggle,
          child: Container(
            width: double.infinity,
            color: const Color.fromARGB(255, 30, 38, 54),
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Center(
              child: AnimatedRotation(
                turns: _expanded ? 0.0 : 0.5,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: const Icon(
                  Icons.keyboard_arrow_up_rounded,
                  size: 18,
                  color: Color.fromARGB(180, 177, 206, 255),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
