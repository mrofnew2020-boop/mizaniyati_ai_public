class IncomeEntry {
  final int? id;
  final int? sourceId;
  final String sourceNameSnapshot;
  final double amount;
  final String date;
  final String? note;
  final String createdAt;

  const IncomeEntry({
    this.id,
    this.sourceId,
    required this.sourceNameSnapshot,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'source_id': sourceId,
      'source_name_snapshot': sourceNameSnapshot,
      'amount': amount,
      'date': date,
      'note': note,
      'created_at': createdAt,
    };
    if (id != null) m['id'] = id;
    return m;
  }

  factory IncomeEntry.fromMap(Map<String, dynamic> map) => IncomeEntry(
        id: map['id'] as int?,
        sourceId: map['source_id'] as int?,
        sourceNameSnapshot: map['source_name_snapshot'] as String,
        amount: (map['amount'] as num).toDouble(),
        date: map['date'] as String,
        note: map['note'] as String?,
        createdAt: map['created_at'] as String,
      );
}
