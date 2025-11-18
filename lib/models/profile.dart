import 'dart:convert';

class Profile {
  final int id;
  final int userId;
  final String? profileImage;
  final String? aboutMe;
  final Map<String, dynamic>? socialNetworks;
  final List<dynamic>? educationalCredentials;
  final List<dynamic>? completedProjects;
  final List<dynamic>? skills;
  final List<dynamic>? certifications;
  final List<dynamic>? workExperience;
  final Map<String, dynamic>? contactInfo;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    required this.userId,
    this.profileImage,
    this.aboutMe,
    this.socialNetworks,
    this.educationalCredentials,
    this.completedProjects,
    this.skills,
    this.certifications,
    this.workExperience,
    this.contactInfo,
    required this.isPublic,
    this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      profileImage: json['profile_image'] as String?,
      aboutMe: json['about_me'] as String?,
      socialNetworks: json['social_networks'] != null
          ? (json['social_networks'] is Map
              ? Map<String, dynamic>.from(json['social_networks'] as Map)
              : json['social_networks'] is String
                  ? (() {
                      try {
                        return Map<String, dynamic>.from(
                            jsonDecode(json['social_networks'] as String) as Map);
                      } catch (e) {
                        return null;
                      }
                    })()
                  : null)
          : null,
      educationalCredentials: json['educational_credentials'] != null
          ? (json['educational_credentials'] is List
              ? json['educational_credentials'] as List
              : json['educational_credentials'] is String
                  ? (() {
                      try {
                        return jsonDecode(json['educational_credentials'] as String) as List;
                      } catch (e) {
                        return null;
                      }
                    })()
                  : null)
          : null,
      completedProjects: json['completed_projects'] != null
          ? (json['completed_projects'] is List
              ? json['completed_projects'] as List
              : json['completed_projects'] is String
                  ? (() {
                      try {
                        return jsonDecode(json['completed_projects'] as String) as List;
                      } catch (e) {
                        return null;
                      }
                    })()
                  : null)
          : null,
      skills: json['skills'] != null
          ? (json['skills'] is List
              ? json['skills'] as List
              : json['skills'] is String
                  ? (() {
                      try {
                        return jsonDecode(json['skills'] as String) as List;
                      } catch (e) {
                        return null;
                      }
                    })()
                  : null)
          : null,
      certifications: json['certifications'] != null
          ? (json['certifications'] is List
              ? json['certifications'] as List
              : json['certifications'] is String
                  ? (() {
                      try {
                        return jsonDecode(json['certifications'] as String) as List;
                      } catch (e) {
                        return null;
                      }
                    })()
                  : null)
          : null,
      workExperience: json['work_experience'] != null
          ? (json['work_experience'] is List
              ? json['work_experience'] as List
              : json['work_experience'] is String
                  ? (() {
                      try {
                        return jsonDecode(json['work_experience'] as String) as List;
                      } catch (e) {
                        return null;
                      }
                    })()
                  : null)
          : null,
      contactInfo: json['contact_info'] != null
          ? (json['contact_info'] is Map
              ? Map<String, dynamic>.from(json['contact_info'] as Map)
              : json['contact_info'] is String
                  ? (() {
                      try {
                        return Map<String, dynamic>.from(
                            jsonDecode(json['contact_info'] as String) as Map);
                      } catch (e) {
                        return null;
                      }
                    })()
                  : null)
          : null,
      isPublic: json['is_public'] != null
          ? (json['is_public'] is bool
              ? json['is_public'] as bool
              : json['is_public'] == 1 ||
                  json['is_public'] == '1' ||
                  json['is_public'].toString().toLowerCase() == 'true')
          : false,
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
      'user_id': userId,
      'profile_image': profileImage,
      'about_me': aboutMe,
      'social_networks': socialNetworks,
      'educational_credentials': educationalCredentials,
      'completed_projects': completedProjects,
      'skills': skills,
      'certifications': certifications,
      'work_experience': workExperience,
      'contact_info': contactInfo,
      'is_public': isPublic,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

