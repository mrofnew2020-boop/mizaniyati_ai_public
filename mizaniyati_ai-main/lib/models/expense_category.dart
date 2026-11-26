class ExpenseCategory {
  final int? id;
  final String name;
  final String type;
  final String icon;
  final String? color;
  final double? cap;
  final String capMode;
  final int isArchived;
  final int sortOrder;
  final String createdAt;

  const ExpenseCategory({
    this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.color,
    this.cap,
    this.capMode = 'manual',
    this.isArchived = 0,
    this.sortOrder = 0,
    required this.createdAt,
  });

  bool get archived => isArchived == 1;
  bool get isFixed => type == 'fixed';
  bool get hasCap => cap != null && cap! > 0;

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'cap': cap,
      'cap_mode': capMode,
      'is_archived': isArchived,
      'sort_order': sortOrder,
      'created_at': createdAt,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String,
        icon: map['icon'] as String,
        color: map['color'] as String?,
        cap: (map['cap'] as num?)?.toDouble(),
        capMode: (map['cap_mode'] as String?) ?? 'manual',
        isArchived: (map['is_archived'] as int?) ?? 0,
        sortOrder: (map['sort_order'] as int?) ?? 0,
        createdAt: map['created_at'] as String,
      );

  ExpenseCategory copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    double? cap,
    bool clearCap = false,
    String? capMode,
    int? isArchived,
    int? sortOrder,
    String? createdAt,
  }) =>
      ExpenseCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        cap: clearCap ? null : (cap ?? this.cap),
        capMode: capMode ?? this.capMode,
        isArchived: isArchived ?? this.isArchived,
        sortOrder: sortOrder ?? this.sortOrder,
        createdAt: createdAt ?? this.createdAt,
      );
}
