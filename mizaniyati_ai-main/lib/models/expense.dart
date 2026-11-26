class Expense {
  final int? id;
  final int? categoryId;
  final String categoryNameSnapshot;
  final double amount;
  final String date;
  final String? note;
  final String uuid;
  final String? memberName;
  final String createdAt;
  final String? modifiedAt;

  const Expense({
    this.id,
    this.categoryId,
    required this.categoryNameSnapshot,
    required this.amount,
    required this.date,
    this.note,
    required this.uuid,
    this.memberName,
    required this.createdAt,
    this.modifiedAt,
  });

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'category_id': categoryId,
      'category_name_snapshot': categoryNameSnapshot,
      'amount': amount,
      'date': date,
      'note': note,
      'uuid': uuid,
      'member_name': memberName,
      'created_at': createdAt,
      'modified_at': modifiedAt,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
        id: map['id'] as int?,
        categoryId: map['category_id'] as int?,
        categoryNameSnapshot: map['category_name_snapshot'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: map['date'] as String,
        note: map['note'] as String?,
        uuid: map['uuid'] as String,
        memberName: map['member_name'] as String?,
        createdAt: map['created_at'] as String,
        modifiedAt: map['modified_at'] as String?,
      );

  Map<String, dynamic> toExportJson() => {
        'uuid': uuid,
        'amount': amount,
        'category': categoryNameSnapshot,
        'date': date,
        'note': note,
        'createdAt': createdAt,
        'modifiedAt': modifiedAt,
      };
}
