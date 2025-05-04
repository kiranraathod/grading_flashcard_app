// Alternative version with icon for "View Answer" button
// To use this version, replace the "View Answer" button section with:

/*
// View Answer button with icon
ElevatedButton.icon(
  onPressed: onViewAnswer,
  icon: Icon(
    Icons.visibility_outlined,
    size: 18,
    color: context.isDarkMode 
        ? const Color(0xFF6EE7B7)  // Very bright emerald for max contrast
        : const Color(0xFF10B981),  // Original emerald in light mode
  ),
  label: Text(
    'View Answer',
    style: TextStyle(
      fontSize: 16,  // Increased from 15
      fontWeight: FontWeight.w700,  // Bold for better readability
      letterSpacing: 0.3,  // Slightly increased letter spacing
      color: context.isDarkMode 
          ? const Color(0xFF6EE7B7)  // Very bright emerald for max contrast
          : const Color(0xFF10B981),  // Original emerald in light mode
    ),
  ),
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    elevation: 0,
    backgroundColor: context.isDarkMode 
        ? const Color(0xFF4ADE80).withOpacity(0.15)  // Light emerald background in dark mode
        : const Color(0xFF10B981).withOpacity(0.1),  // Light emerald background in light mode
    foregroundColor: context.isDarkMode 
        ? const Color(0xFF6EE7B7)  // Very bright emerald for max contrast
        : const Color(0xFF10B981),  // Original emerald in light mode
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: context.isDarkMode 
            ? const Color(0xFF4ADE80).withOpacity(0.5)
            : const Color(0xFF10B981).withOpacity(0.3),
        width: 1,
      ),
    ),
  ),
),
*/

// Alternative with outlined style for even better contrast:

/*
// View Answer button - outlined style
OutlinedButton.icon(
  onPressed: onViewAnswer,
  icon: Icon(
    Icons.visibility_outlined,
    size: 18,
    color: context.isDarkMode 
        ? const Color(0xFF6EE7B7)  // Very bright emerald for max contrast
        : const Color(0xFF10B981),  // Original emerald in light mode
  ),
  label: Text(
    'View Answer',
    style: TextStyle(
      fontSize: 16,  // Increased from 15
      fontWeight: FontWeight.w700,  // Bold for better readability
      letterSpacing: 0.3,  // Slightly increased letter spacing
      color: context.isDarkMode 
          ? const Color(0xFF6EE7B7)  // Very bright emerald for max contrast
          : const Color(0xFF10B981),  // Original emerald in light mode
    ),
  ),
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    minimumSize: Size.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    side: BorderSide(
      color: context.isDarkMode 
          ? const Color(0xFF6EE7B7)  // Very bright emerald border
          : const Color(0xFF10B981),  // Original emerald border
      width: 2,  // Thicker border for visibility
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
),
*/
