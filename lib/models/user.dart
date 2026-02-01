class User {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final String? region;
  final String? nearestPoint;
  final bool isAdmin;
  final String? password; // للأدمن فقط
  final String? imagePath; // مسار صورة الملف الشخصي
  final bool isBlocked; // هل المستخدم محظور؟
  final String? deviceId; // رقم آيدي الجهاز

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    this.region,
    this.nearestPoint,
    this.isAdmin = false,
    this.password,
    this.imagePath,
    this.isBlocked = false,
    this.deviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'region': region,
      'nearestPoint': nearestPoint,
      'isAdmin': isAdmin,
      'password': password,
      'imagePath': imagePath,
      'isBlocked': isBlocked,
      'deviceId': deviceId,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      region: json['region'],
      nearestPoint: json['nearestPoint'],
      isAdmin: json['isAdmin'] ?? false,
      password: json['password'],
      imagePath: json['imagePath'],
      isBlocked: json['isBlocked'] ?? false,
      deviceId: json['deviceId'],
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? region,
    String? nearestPoint,
    bool? isAdmin,
    String? password,
    String? imagePath,
    bool? isBlocked,
    String? deviceId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      region: region ?? this.region,
      nearestPoint: nearestPoint ?? this.nearestPoint,
      isAdmin: isAdmin ?? this.isAdmin,
      password: password ?? this.password,
      imagePath: imagePath ?? this.imagePath,
      isBlocked: isBlocked ?? this.isBlocked,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}
