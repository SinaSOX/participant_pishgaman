class GalleryPost {
  final int id;
  final String title;
  final String imageUrl;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GalleryPost({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory GalleryPost.fromJson(Map<String, dynamic> json) {
    return GalleryPost(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      imageUrl: json['image'] as String? ?? 
                json['image_url'] as String? ?? 
                json['imageUrl'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': imageUrl,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}





