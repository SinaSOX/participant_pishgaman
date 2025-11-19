class DomainInstructor {
  final String name;
  final String title;
  final String expertise;

  DomainInstructor({
    required this.name,
    required this.title,
    required this.expertise,
  });

  factory DomainInstructor.fromJson(Map<String, dynamic> json) {
    return DomainInstructor(
      name: json['name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      expertise: json['expertise'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'expertise': expertise,
    };
  }
}

class Domain {
  final int id;
  final String name;
  final String location; // Format: "lat,lng"
  final String description;
  final List<DomainInstructor> instructors;
  final List<String> courseOutlines;
  final String contactPhone;
  final String contactEmail;
  final String address;
  final int capacity;
  final int isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;

  Domain({
    required this.id,
    required this.name,
    required this.location,
    required this.description,
    required this.instructors,
    required this.courseOutlines,
    required this.contactPhone,
    required this.contactEmail,
    required this.address,
    required this.capacity,
    required this.isActive,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });

  // Helper method to parse location string to lat/lng
  double? get latitude {
    try {
      final parts = location.split(',');
      if (parts.length >= 1) {
        return double.tryParse(parts[0].trim());
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  double? get longitude {
    try {
      final parts = location.split(',');
      if (parts.length >= 2) {
        return double.tryParse(parts[1].trim());
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  factory Domain.fromJson(Map<String, dynamic> json) {
    // Parse instructors
    List<DomainInstructor> instructors = [];
    if (json['instructors'] != null && json['instructors'] is List) {
      instructors = (json['instructors'] as List)
          .map((item) => DomainInstructor.fromJson(
              item as Map<String, dynamic>))
          .toList();
    }

    // Parse course outlines
    List<String> courseOutlines = [];
    if (json['course_outlines'] != null &&
        json['course_outlines'] is List) {
      courseOutlines = (json['course_outlines'] as List)
          .map((item) => item.toString())
          .toList();
    }

    return Domain(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      location: json['location'] as String? ?? '',
      description: json['description'] as String? ?? '',
      instructors: instructors,
      courseOutlines: courseOutlines,
      contactPhone: json['contact_phone'] as String? ?? '',
      contactEmail: json['contact_email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 0,
      isActive: json['is_active'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      deletedAt: json['deleted_at'] != null
          ? DateTime.tryParse(json['deleted_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'description': description,
      'instructors': instructors.map((i) => i.toJson()).toList(),
      'course_outlines': courseOutlines,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'address': address,
      'capacity': capacity,
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }
}



