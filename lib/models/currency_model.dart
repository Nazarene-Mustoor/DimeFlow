class CurrencyModel {
  final String userId; // Unique user ID (to associate currency with a user)
  final String code;   // e.g., USD, EUR, INR
  final String symbol; // e.g., $, €
  final String name;   // e.g., US Dollar, Euro, Indian Rupees

  CurrencyModel({
    required this.userId,
    required this.code,
    required this.symbol,
    required this.name,
  });

  // Convert to Map (for Firebase)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'code': code,
      'symbol': symbol,
      'name': name,
    };
  }

  // Convert from Map (for Firebase)
  factory CurrencyModel.fromMap(Map<String, dynamic> map) {
    return CurrencyModel(
      userId: map['userId'],
      code: map['code'],
      symbol: map['symbol'],
      name: map['name'],
    );
  }
}