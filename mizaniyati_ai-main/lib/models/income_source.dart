class IncomeSource {
  final int? id;
  final String name;
  final String type;
  final double? defaultAmount;
  final int? payDay;
  final int isArchived;
  final String createdAt;

  const IncomeSource({
    this.id,
    required this.name,
    required this.type,
    this.defaultAmount,
    this.payDay,
    this.isArchived = 0,
    required this.createdAt,
  });

  bool get archived => isArchived == 1;

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'name': name,
      'type': type,
      'default_amount': defaultAmount,
      'pay_day': payDay,
      'is_archived': isArchived,
      'created_at': createdAt,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  factory IncomeSource.fromMap(Map<String, dynamic> map) => IncomeSource(
        id: map['id'] as int?,
        name: map['name'] as String,
        type: map['type'] as String,
        defaultAmount: (map['default_amount'] as num?)?.toDouble(),
        payDay: map['pay_day'] as int?,
        isArchived: (map['is_archived'] as int?) ?? 0,
        createdAt: map['created_at'] as String,
      );

  IncomeSource copyWith({
    int? id,
    String? name,
    String? type,
    double? defaultAmount,
    int? payDay,
    int? isArchived,
    String? createdAt,
  }) =>
      IncomeSource(
        id: id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        defaultAmount: defaultAmount ?? this.defaultAmount,
        payDay: payDay ?? this.payDay,
        isArchived: isArchived ?? this.isArchived,
        createdAt: createdAt ?? this.createdAt,
      );
}
