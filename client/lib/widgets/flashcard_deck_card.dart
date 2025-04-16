import 'package:flutter/material.dart';

class FlashcardDeckCard extends StatefulWidget {
  final String title;
  final String category;
  final int cardCount;
  final int progressPercent;
  final VoidCallback onTap;
  final bool isStudyDeck; // True for study deck, false for interview questions

  const FlashcardDeckCard({
    super.key,
    required this.title,
    required this.category,
    required this.cardCount,
    required this.progressPercent,
    required this.onTap,
    this.isStudyDeck = true,
  });

  @override
  State<FlashcardDeckCard> createState() => _FlashcardDeckCardState();
}

class _FlashcardDeckCardState extends State<FlashcardDeckCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: widget.isStudyDeck
                      ? [Color(0xFFECFDF5), Color(0xFFD1FAE5)]  // emerald-50 to teal-50
                      : [Color(0xFFEEF2FF), Color(0xFFE0E7FF)], // purple-50 to indigo-50
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category badge
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      // Title
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  // Play button (visible on hover)
                  if (_isHovered)
                    Container(
                      height: 32,
                      width: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.play_arrow,
                          size: 16,
                          color: widget.isStudyDeck
                              ? Color(0xFF10B981) // emerald-600
                              : Color(0xFF8B5CF6), // purple-600
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Card info section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card count (always show)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.isStudyDeck
                            ? '${widget.cardCount} cards'
                            : '${widget.cardCount} questions',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (!widget.isStudyDeck)
                        Text(
                          'Updated 2d ago',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                  
                  // Always show progress bar, but with zero width for 0%
                  const SizedBox(height: 8),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      children: [
                        // Progress bar - visible even at 0%
                        Container(
                          width: (MediaQuery.of(context).size.width / 4 - 32) * 
                              (widget.progressPercent > 0 ? widget.progressPercent / 100 : 0.001),
                          decoration: BoxDecoration(
                            color: Color(0xFF10B981), // emerald-500
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Text status below progress bar
                  const SizedBox(height: 4),
                  Text(
                    widget.progressPercent > 0 
                        ? '${widget.progressPercent}% complete' 
                        : 'Not started',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.progressPercent > 0
                          ? Color(0xFF10B981) // emerald-600 for completed
                          : Colors.grey.shade400,
                      fontWeight: widget.progressPercent > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            
            // Spacer to push the button to the bottom
            const Spacer(),
            
            // Action button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: TextButton(
                onPressed: widget.onTap,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isStudyDeck ? 'Start Learning' : 'Practice Questions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}