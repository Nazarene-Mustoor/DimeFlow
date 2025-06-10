class UserModel {
  final String id; // User ID
  final String name; // User Name
  final String email; // User Email

  UserModel({
    required this.id,
    required this.name,
    required this.email,
  });

  // Convert to Map (for Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }

  // Convert from Map (for Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',  // Default to empty string if null
      name: map['name'] ?? '',
      email: map['email'] ?? '',
    );
  }
}