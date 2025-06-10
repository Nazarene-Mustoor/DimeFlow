class CategoryModel {
  final String name; // Category name (e.g., Food, Shopping)
  final String icon; // Icon name or path

  CategoryModel({
    required this.name,
    required this.icon,
  });

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'icon': icon,
    };
  }

  // Convert from Map
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      name: map['name'],
      icon: map['icon'],
    );
  }
}