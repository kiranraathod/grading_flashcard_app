/// Category model for Supabase integration with dual ownership support
/// 
/// Supports both guest users and authenticated users while maintaining
/// backward compatibility with the existing CategoryMapper system.
class Category {
  // ===== CORE FIELDS =====
  final String id;                    // UUID primary key
  final String name;                  // Category display name
  final String description;           // Category description
  final String internalId;            // For CategoryMapper compatibility
  final int displayOrder;             // Sort order for UI
  final bool isDefault;               // Whether this is a default category
  final String? colorScheme;          // UI color scheme identifier
  final String? iconName;             // Icon identifier for UI
  
  // ===== SUPABASE OWNERSHIP FIELDS =====
  final String? userId;               // References auth.users(id) - null for guest users
  final String? guestSessionId;       // References guest_sessions(session_id) - null for authenticated users
  final bool isGuestData;             // Tracks ownership type: true = guest, false = authenticated user
  final DateTime createdAt;           // Database creation timestamp
  final DateTime updatedAt;           // Database last update timestamp
  
  Category({
    required this.id,
    required this.name,
    this.description = '',
    required this.internalId,
    this.displayOrder = 0,
    this.isDefault = false,
    this.colorScheme,
    this.iconName,
    // Supabase ownership fields
    this.userId,
    this.guestSessionId,
    this.isGuestData = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
  
  /// Copy with method for immutable updates
  Category copyWith({
    String? name,
    String? description,
    String? internalId,
    int? displayOrder,
    bool? isDefault,
    String? colorScheme,
    String? iconName,
    String? userId,
    String? guestSessionId,
    bool? isGuestData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      internalId: internalId ?? this.internalId,
      displayOrder: displayOrder ?? this.displayOrder,
      isDefault: isDefault ?? this.isDefault,
      colorScheme: colorScheme ?? this.colorScheme,
      iconName: iconName ?? this.iconName,
      userId: userId ?? this.userId,
      guestSessionId: guestSessionId ?? this.guestSessionId,
      isGuestData: isGuestData ?? this.isGuestData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  /// JSON serialization with backward compatibility
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      internalId: json['internal_id'] ?? json['internalId'] ?? '',
      displayOrder: json['display_order'] ?? json['displayOrder'] ?? 0,
      isDefault: json['is_default'] ?? json['isDefault'] ?? false,
      colorScheme: json['color_scheme'] ?? json['colorScheme'],
      iconName: json['icon_name'] ?? json['iconName'],
      // Supabase fields with safe defaults for backward compatibility
      userId: json['user_id'] ?? json['userId'],
      guestSessionId: json['guest_session_id'] ?? json['guestSessionId'],
      isGuestData: json['is_guest_data'] ?? json['isGuestData'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : 
                (json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : 
                (json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now()),
    );
  }
  
  /// JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'internal_id': internalId,
      'display_order': displayOrder,
      'is_default': isDefault,
      'color_scheme': colorScheme,
      'icon_name': iconName,
      // Supabase ownership fields
      'user_id': userId,
      'guest_session_id': guestSessionId,
      'is_guest_data': isGuestData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
  
  /// JSON serialization compatible with legacy CategoryMapper
  Map<String, dynamic> toLegacyJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'internalId': internalId,
      'displayOrder': displayOrder,
      'isDefault': isDefault,
      'colorScheme': colorScheme,
      'iconName': iconName,
    };
  }
  
  // ===== CONVENIENCE METHODS =====
  
  /// Returns true if this category belongs to an authenticated user
  bool get isAuthenticatedUserData => !isGuestData && userId != null;
  
  /// Returns true if this category belongs to a guest session
  bool get isGuestUserData => isGuestData && guestSessionId != null;
  
  /// Returns the owner identifier (userId for auth users, guestSessionId for guests)
  String? get ownerId => isGuestData ? guestSessionId : userId;
  
  /// Creates a copy of this category for an authenticated user
  Category copyAsAuthenticatedUserData(String userId) {
    return copyWith(
      userId: userId,
      guestSessionId: null,
      isGuestData: false,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Creates a copy of this category for a guest session
  Category copyAsGuestData(String guestSessionId) {
    return copyWith(
      userId: null,
      guestSessionId: guestSessionId,
      isGuestData: true,
      updatedAt: DateTime.now(),
    );
  }
  
  // ===== FACTORY CONSTRUCTORS =====
  
  /// Factory constructor for creating a new guest user category
  factory Category.forGuest({
    required String id,
    required String name,
    required String internalId,
    required String guestSessionId,
    String description = '',
    int displayOrder = 0,
    bool isDefault = false,
    String? colorScheme,
    String? iconName,
  }) {
    final now = DateTime.now();
    return Category(
      id: id,
      name: name,
      description: description,
      internalId: internalId,
      displayOrder: displayOrder,
      isDefault: isDefault,
      colorScheme: colorScheme,
      iconName: iconName,
      guestSessionId: guestSessionId,
      isGuestData: true,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Factory constructor for creating a new authenticated user category
  factory Category.forUser({
    required String id,
    required String name,
    required String internalId,
    required String userId,
    String description = '',
    int displayOrder = 0,
    bool isDefault = false,
    String? colorScheme,
    String? iconName,
  }) {
    final now = DateTime.now();
    return Category(
      id: id,
      name: name,
      description: description,
      internalId: internalId,
      displayOrder: displayOrder,
      isDefault: isDefault,
      colorScheme: colorScheme,
      iconName: iconName,
      userId: userId,
      isGuestData: false,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Factory constructor from CategoryMapper internal ID (for backward compatibility)
  factory Category.fromCategoryMapper({
    required String id,
    required String internalId,
    required String guestSessionId,
    String? userId,
    bool isGuestData = true,
  }) {
    // Use CategoryMapper to get the UI name
    final name = _getUINameFromInternalId(internalId);
    final description = _getDescriptionFromInternalId(internalId);
    final colorScheme = _getColorSchemeFromInternalId(internalId);
    final iconName = _getIconNameFromInternalId(internalId);
    
    final now = DateTime.now();
    return Category(
      id: id,
      name: name,
      description: description,
      internalId: internalId,
      displayOrder: _getDisplayOrderFromInternalId(internalId),
      isDefault: _isDefaultCategory(internalId),
      colorScheme: colorScheme,
      iconName: iconName,
      userId: userId,
      guestSessionId: guestSessionId,
      isGuestData: isGuestData,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  // ===== PRIVATE HELPER METHODS FOR CATEGORYMAPPE INTEGRATION =====
  
  static String _getUINameFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 'Data Analysis',
      'machine_learning': 'Machine Learning',
      'sql': 'SQL',
      'python': 'Python',
      'web_development': 'Web Development',
      'statistics': 'Statistics',
      'technical': 'Data Analysis',
      'applied': 'Machine Learning',
      'behavioral': 'Python',
      'case': 'Statistics',
      'job': 'Web Development',
    };
    return mapping[internalId] ?? 'General';
  }
  
  static String _getDescriptionFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 'Data cleaning, preprocessing, and exploratory analysis',
      'machine_learning': 'ML algorithms, model training, and evaluation',
      'sql': 'Database queries, joins, and data manipulation',
      'python': 'Python programming fundamentals and libraries',
      'web_development': 'API development and web technologies',
      'statistics': 'Statistical analysis and inference',
    };
    return mapping[internalId] ?? 'General category for study materials';
  }
  
  static String _getColorSchemeFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 'blue',
      'machine_learning': 'green',
      'sql': 'orange',
      'python': 'purple',
      'web_development': 'red',
      'statistics': 'teal',
    };
    return mapping[internalId] ?? 'gray';
  }
  
  static String _getIconNameFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 'analytics',
      'machine_learning': 'psychology',
      'sql': 'storage',
      'python': 'code',
      'web_development': 'web',
      'statistics': 'trending_up',
    };
    return mapping[internalId] ?? 'category';
  }
  
  static int _getDisplayOrderFromInternalId(String internalId) {
    const mapping = {
      'data_analysis': 1,
      'machine_learning': 2,
      'sql': 3,
      'python': 4,
      'web_development': 5,
      'statistics': 6,
    };
    return mapping[internalId] ?? 99;
  }
  
  static bool _isDefaultCategory(String internalId) {
    return ['data_analysis', 'machine_learning', 'sql', 'python'].contains(internalId);
  }
  
  @override
  String toString() {
    return 'Category(id: $id, name: $name, internalId: $internalId, ownerId: $ownerId)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }
  
  @override
  int get hashCode => id.hashCode;
}
