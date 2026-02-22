class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String location;
  final String? gpsCoordinates;
  final String businessType;
  final String customerType; // Individual, Restaurant, Shop, etc.
  final double buyingPricePerLiter;
  final String paymentMethod;
  final String? bankAccount;
  final String? mobileMoneyNumber;
  final String? idNumber;
  final String? notes;
  final String? profilePhoto;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.location,
    this.gpsCoordinates,
    required this.businessType,
    required this.customerType,
    required this.buyingPricePerLiter,
    required this.paymentMethod,
    this.bankAccount,
    this.mobileMoneyNumber,
    this.idNumber,
    this.notes,
    this.profilePhoto,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? location,
    String? gpsCoordinates,
    String? businessType,
    String? customerType,
    double? buyingPricePerLiter,
    String? paymentMethod,
    String? bankAccount,
    String? mobileMoneyNumber,
    String? idNumber,
    String? notes,
    String? profilePhoto,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      gpsCoordinates: gpsCoordinates ?? this.gpsCoordinates,
      businessType: businessType ?? this.businessType,
      customerType: customerType ?? this.customerType,
      buyingPricePerLiter: buyingPricePerLiter ?? this.buyingPricePerLiter,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      bankAccount: bankAccount ?? this.bankAccount,
      mobileMoneyNumber: mobileMoneyNumber ?? this.mobileMoneyNumber,
      idNumber: idNumber ?? this.idNumber,
      notes: notes ?? this.notes,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'gpsCoordinates': gpsCoordinates,
      'businessType': businessType,
      'customerType': customerType,
      'buyingPricePerLiter': buyingPricePerLiter,
      'paymentMethod': paymentMethod,
      'bankAccount': bankAccount,
      'mobileMoneyNumber': mobileMoneyNumber,
      'idNumber': idNumber,
      'notes': notes,
      'profilePhoto': profilePhoto,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      location: json['location'] as String,
      gpsCoordinates: json['gpsCoordinates'] as String?,
      businessType: json['businessType'] as String,
      customerType: json['customerType'] as String,
      buyingPricePerLiter: (json['buyingPricePerLiter'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      bankAccount: json['bankAccount'] as String?,
      mobileMoneyNumber: json['mobileMoneyNumber'] as String?,
      idNumber: json['idNumber'] as String?,
      notes: json['notes'] as String?,
      profilePhoto: json['profilePhoto'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }
} 