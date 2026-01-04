class Property {
  final String id;
  final String title;
  final String? description;
  final double price;
  final String currency;
  final String propertyType; // house, apartment, plot, villa
  final String location;
  final String? district;
  final String? province;
  final int? bedrooms;
  final int? bathrooms;
  final double? squareMeters;
  final String? listingId;
  final String status; // for sale, for rent, sold
  final bool isPopular;
  final bool isExclusive;
  final bool isNew;
  final String? imageUrl;
  final String? videoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? contactPhone;
  final String? contactEmail;
  final String? agentName;

  Property({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'Fr',
    required this.propertyType,
    required this.location,
    this.district,
    this.province,
    this.bedrooms,
    this.bathrooms,
    this.squareMeters,
    this.listingId,
    required this.status,
    this.isPopular = false,
    this.isExclusive = false,
    this.isNew = false,
    this.imageUrl,
    this.videoUrl,
    this.createdAt,
    this.updatedAt,
    this.contactPhone,
    this.contactEmail,
    this.agentName,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'Fr',
      propertyType: json['property_type'] as String,
      location: json['location'] as String,
      district: json['district'] as String?,
      province: json['province'] as String?,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      squareMeters: json['square_meters'] != null 
          ? (json['square_meters'] as num).toDouble() 
          : null,
      listingId: json['listing_id'] as String?,
      status: json['status'] as String,
      isPopular: json['is_popular'] as bool? ?? false,
      isExclusive: json['is_exclusive'] as bool? ?? false,
      isNew: json['is_new'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      videoUrl: json['video_url'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      agentName: json['agent_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'property_type': propertyType,
      'location': location,
      'district': district,
      'province': province,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'square_meters': squareMeters,
      'listing_id': listingId,
      'status': status,
      'is_popular': isPopular,
      'is_exclusive': isExclusive,
      'is_new': isNew,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'agent_name': agentName,
    };
  }

  @override
  String toString() {
    return 'Property(id: $id, title: $title, price: $price $currency, location: $location)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Property && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class PropertyFilter {
  final String? propertyType;
  final String? location;
  final String? status;
  final double? minPrice;
  final double? maxPrice;
  final int? minBedrooms;
  final int? minBathrooms;
  final double? minSquareMeters;
  final bool? isPopular;
  final bool? isExclusive;
  final bool? isNew;

  PropertyFilter({
    this.propertyType,
    this.location,
    this.status,
    this.minPrice,
    this.maxPrice,
    this.minBedrooms,
    this.minBathrooms,
    this.minSquareMeters,
    this.isPopular,
    this.isExclusive,
    this.isNew,
  });

  Map<String, dynamic> toJson() {
    return {
      'property_type': propertyType,
      'location': location,
      'status': status,
      'min_price': minPrice,
      'max_price': maxPrice,
      'min_bedrooms': minBedrooms,
      'min_bathrooms': minBathrooms,
      'min_square_meters': minSquareMeters,
      'is_popular': isPopular,
      'is_exclusive': isExclusive,
      'is_new': isNew,
    };
  }
}

