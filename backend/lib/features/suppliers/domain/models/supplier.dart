class Supplier {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String location;
  final String? gpsCoordinates;
  final String businessType;
  final int cattleCount;
  final double dailyProduction;
  final String farmType;
  final String collectionSchedule;
  final double sellingPricePerLiter;
  final String qualityGrades;
  final String paymentMethod;
  final String? bankAccount;
  final String? mobileMoneyNumber;
  final String? idNumber;
  final String? notes;
  final String? profilePhoto;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Supplier({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.location,
    this.gpsCoordinates,
    required this.businessType,
    required this.cattleCount,
    required this.dailyProduction,
    required this.farmType,
    required this.collectionSchedule,
    required this.sellingPricePerLiter,
    required this.qualityGrades,
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

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? location,
    String? gpsCoordinates,
    String? businessType,
    int? cattleCount,
    double? dailyProduction,
    String? farmType,
    String? collectionSchedule,
    double? sellingPricePerLiter,
    String? qualityGrades,
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
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      gpsCoordinates: gpsCoordinates ?? this.gpsCoordinates,
      businessType: businessType ?? this.businessType,
      cattleCount: cattleCount ?? this.cattleCount,
      dailyProduction: dailyProduction ?? this.dailyProduction,
      farmType: farmType ?? this.farmType,
      collectionSchedule: collectionSchedule ?? this.collectionSchedule,
      sellingPricePerLiter: sellingPricePerLiter ?? this.sellingPricePerLiter,
      qualityGrades: qualityGrades ?? this.qualityGrades,
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
      'cattleCount': cattleCount,
      'dailyProduction': dailyProduction,
      'farmType': farmType,
      'collectionSchedule': collectionSchedule,
      'sellingPricePerLiter': sellingPricePerLiter,
      'qualityGrades': qualityGrades,
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

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      location: json['location'],
      gpsCoordinates: json['gpsCoordinates'],
      businessType: json['businessType'],
      cattleCount: json['cattleCount'],
      dailyProduction: json['dailyProduction'].toDouble(),
      farmType: json['farmType'],
      collectionSchedule: json['collectionSchedule'],
      sellingPricePerLiter: json['sellingPricePerLiter'].toDouble(),
      qualityGrades: json['qualityGrades'],
      paymentMethod: json['paymentMethod'],
      bankAccount: json['bankAccount'],
      mobileMoneyNumber: json['mobileMoneyNumber'],
      idNumber: json['idNumber'],
      notes: json['notes'],
      profilePhoto: json['profilePhoto'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'],
    );
  }
} 