class Client {
  final int? id;
  final String name;
  final String? company;
  final String? address;
  final String? phoneNumber;
  final String? email;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ClientCategory category;
  final bool isActive;

  Client({
    this.id,
    required this.name,
    this.company,
    this.address,
    this.phoneNumber,
    this.email,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.category = ClientCategory.standard,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'address': address,
      'phoneNumber': phoneNumber,
      'email': email,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category.toString(),
      'isActive': isActive ? 1 : 0,
    };
  }

  static Client fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      company: map['company'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      userId: map['userId'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      category: ClientCategory.values.firstWhere(
        (e) => e.toString() == map['category'],
        orElse: () => ClientCategory.standard,
      ),
      isActive: map['isActive'] == 1,
    );
  }
}

enum ClientCategory {
  vip,
  standard,
  inactive
}