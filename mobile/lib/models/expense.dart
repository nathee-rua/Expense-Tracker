class ExpenseItem {
  final String name;
  final double price;
  final int quantity;

  ExpenseItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory ExpenseItem.fromJson(dynamic json) {
    if (json is String) {
      return ExpenseItem(name: json, price: 0.0, quantity: 1);
    } else if (json is Map<String, dynamic>) {
      return ExpenseItem(
        name: json['name']?.toString() ?? json['description']?.toString() ?? 'Item',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
    }
    return ExpenseItem(name: 'Unknown Item', price: 0.0, quantity: 1);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'quantity': quantity,
  };
}

class Expense {
  final String id;
  final DateTime transactionDate;
  final String transactionTime;
  final double amount;
  final String? senderName;
  final String? receiverName;
  final String? bankName;
  final List<ExpenseItem> items;
  final String category;
  final String rawOcrText;
  final String parsedProvider;

  Expense({
    required this.id,
    required this.transactionDate,
    required this.transactionTime,
    required this.amount,
    this.senderName,
    this.receiverName,
    this.bankName,
    required this.items,
    required this.category,
    required this.rawOcrText,
    required this.parsedProvider,
  });

  factory Expense.fromJson(Map<String, dynamic> json, {String id = '', String rawOcr = '', String provider = 'unknown'}) {
    // Parse transaction date safely
    DateTime parsedDate;
    try {
      if (json['transaction_date'] != null) {
        parsedDate = DateTime.parse(json['transaction_date'].toString());
      } else {
        parsedDate = DateTime.now();
      }
    } catch (_) {
      parsedDate = DateTime.now();
    }

    // Parse items safely
    final itemsList = <ExpenseItem>[];
    if (json['items'] is List) {
      for (var item in json['items']) {
        itemsList.add(ExpenseItem.fromJson(item));
      }
    }

    return Expense(
      id: id.isNotEmpty ? id : DateTime.now().millisecondsSinceEpoch.toString(),
      transactionDate: parsedDate,
      transactionTime: json['transaction_time']?.toString() ?? '00:00',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      senderName: json['sender_name']?.toString(),
      receiverName: json['receiver_name']?.toString(),
      bankName: json['bank_name']?.toString(),
      items: itemsList,
      category: json['category']?.toString() ?? 'Other',
      rawOcrText: rawOcr,
      parsedProvider: provider,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_date': transactionDate.toIso8601String().substring(0, 10),
    'transaction_time': transactionTime,
    'amount': amount,
    'sender_name': senderName,
    'receiver_name': receiverName,
    'bank_name': bankName,
    'items': items.map((e) => e.toJson()).toList(),
    'category': category,
    'rawOcrText': rawOcrText,
    'parsedProvider': parsedProvider,
  };
}
