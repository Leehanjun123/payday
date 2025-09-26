class Income {
  final int? id;
  final String type;
  final String name;
  final double amount;
  final DateTime date;
  final String? description;

  Income({
    this.id,
    required this.type,
    required this.name,
    required this.amount,
    required this.date,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      type: map['type'],
      name: map['name'],
      amount: map['amount'] is double ? map['amount'] : (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date']),
      description: map['description'],
    );
  }
}