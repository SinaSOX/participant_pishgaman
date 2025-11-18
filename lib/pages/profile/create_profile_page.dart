import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../components/snak_component.dart';

class CreateProfilePage extends StatefulWidget {
  const CreateProfilePage({super.key});

  @override
  State<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends State<CreateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  final TextEditingController _aboutMeController = TextEditingController();
  
  // Social networks
  final TextEditingController _instagramController = TextEditingController();
  final TextEditingController _linkedinController = TextEditingController();
  final TextEditingController _telegramController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();
  
  // Contact info
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  
  // Skills
  final TextEditingController _skillController = TextEditingController();
  List<String> _skills = [];
  
  // Educational credentials
  List<Map<String, String>> _educationalCredentials = [];
  
  // Work experience
  List<Map<String, String>> _workExperience = [];
  
  // Completed projects
  List<Map<String, String>> _completedProjects = [];
  
  // Certifications
  List<Map<String, String>> _certifications = [];
  
  bool _isPublic = true;

  @override
  void dispose() {
    _aboutMeController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    _telegramController.dispose();
    _twitterController.dispose();
    _websiteController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _skillController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final userIdStr = authService.getUserId();
      
      if (userIdStr == null) {
        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: 'خطا: شناسه کاربری یافت نشد',
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = int.tryParse(userIdStr);
      if (userId == null) {
        if (mounted) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: 'خطا: شناسه کاربری نامعتبر است',
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Build profile data
      final profileData = <String, dynamic>{};

      // About me
      if (_aboutMeController.text.isNotEmpty) {
        profileData['about_me'] = _aboutMeController.text.trim();
      }

      // Social networks
      final socialNetworks = <String, String>{};
      if (_instagramController.text.isNotEmpty) {
        socialNetworks['instagram'] = _instagramController.text.trim();
      }
      if (_linkedinController.text.isNotEmpty) {
        socialNetworks['linkedin'] = _linkedinController.text.trim();
      }
      if (_telegramController.text.isNotEmpty) {
        socialNetworks['telegram'] = _telegramController.text.trim();
      }
      if (_twitterController.text.isNotEmpty) {
        socialNetworks['twitter'] = _twitterController.text.trim();
      }
      if (socialNetworks.isNotEmpty) {
        profileData['social_networks'] = socialNetworks;
      }

      // Contact info
      final contactInfo = <String, String>{};
      if (_websiteController.text.isNotEmpty) {
        contactInfo['website'] = _websiteController.text.trim();
      }
      if (_emailController.text.isNotEmpty) {
        contactInfo['email'] = _emailController.text.trim();
      }
      if (_phoneController.text.isNotEmpty) {
        contactInfo['phone'] = _phoneController.text.trim();
      }
      if (contactInfo.isNotEmpty) {
        profileData['contact_info'] = contactInfo;
      }

      // Skills
      if (_skills.isNotEmpty) {
        profileData['skills'] = _skills;
      }

      // Educational credentials
      if (_educationalCredentials.isNotEmpty) {
        profileData['educational_credentials'] = _educationalCredentials;
      }

      // Work experience
      if (_workExperience.isNotEmpty) {
        profileData['work_experience'] = _workExperience;
      }

      // Completed projects
      if (_completedProjects.isNotEmpty) {
        profileData['completed_projects'] = _completedProjects;
      }

      // Certifications
      if (_certifications.isNotEmpty) {
        profileData['certifications'] = _certifications;
      }

      // Is public
      profileData['is_public'] = _isPublic;

      // Call API
      final response = await ApiService.updateProfile(userId, profileData);

      if (mounted) {
        if (response['success'] == true) {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.success,
            text: response['message'] ?? 'پروفایل با موفقیت ایجاد شد',
          );
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          SnackComponent(
            context: context,
            type: SnackbarTypeColor.danger,
            text: response['message'] ?? 'خطا در ایجاد پروفایل',
          );
        }
      }
    } catch (e) {
      print('❌ Error creating profile: $e');
      if (mounted) {
        SnackComponent(
          context: context,
          type: SnackbarTypeColor.danger,
          text: 'خطا در ارتباط با سرور: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _skills.add(_skillController.text.trim());
        _skillController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
  }

  void _addEducationalCredential() {
    showDialog(
      context: context,
      builder: (context) => _EducationalCredentialDialog(
        onSave: (credential) {
          setState(() {
            _educationalCredentials.add(credential);
          });
        },
      ),
    );
  }

  void _editEducationalCredential(int index) {
    showDialog(
      context: context,
      builder: (context) => _EducationalCredentialDialog(
        credential: _educationalCredentials[index],
        onSave: (credential) {
          setState(() {
            _educationalCredentials[index] = credential;
          });
        },
      ),
    );
  }

  void _removeEducationalCredential(int index) {
    setState(() {
      _educationalCredentials.removeAt(index);
    });
  }

  void _addWorkExperience() {
    showDialog(
      context: context,
      builder: (context) => _WorkExperienceDialog(
        onSave: (experience) {
          setState(() {
            _workExperience.add(experience);
          });
        },
      ),
    );
  }

  void _editWorkExperience(int index) {
    showDialog(
      context: context,
      builder: (context) => _WorkExperienceDialog(
        experience: _workExperience[index],
        onSave: (experience) {
          setState(() {
            _workExperience[index] = experience;
          });
        },
      ),
    );
  }

  void _removeWorkExperience(int index) {
    setState(() {
      _workExperience.removeAt(index);
    });
  }

  void _addCompletedProject() {
    showDialog(
      context: context,
      builder: (context) => _CompletedProjectDialog(
        onSave: (project) {
          setState(() {
            _completedProjects.add(project);
          });
        },
      ),
    );
  }

  void _editCompletedProject(int index) {
    showDialog(
      context: context,
      builder: (context) => _CompletedProjectDialog(
        project: _completedProjects[index],
        onSave: (project) {
          setState(() {
            _completedProjects[index] = project;
          });
        },
      ),
    );
  }

  void _removeCompletedProject(int index) {
    setState(() {
      _completedProjects.removeAt(index);
    });
  }

  void _addCertification() {
    showDialog(
      context: context,
      builder: (context) => _CertificationDialog(
        onSave: (certification) {
          setState(() {
            _certifications.add(certification);
          });
        },
      ),
    );
  }

  void _editCertification(int index) {
    showDialog(
      context: context,
      builder: (context) => _CertificationDialog(
        certification: _certifications[index],
        onSave: (certification) {
          setState(() {
            _certifications[index] = certification;
          });
        },
      ),
    );
  }

  void _removeCertification(int index) {
    setState(() {
      _certifications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'ایجاد پروفایل',
            style: TextStyle(
              fontFamily: 'Farhang',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.grey.shade50],
            ),
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Me
                  _buildSection(
                    title: 'درباره من',
                    icon: Icons.info_outline,
                    child: TextFormField(
                      controller: _aboutMeController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'درباره من',
                        hintText: 'توضیحات خود را بنویسید...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Social Networks
                  _buildSection(
                    title: 'شبکه‌های اجتماعی',
                    icon: Icons.share_outlined,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _instagramController,
                          decoration: const InputDecoration(
                            labelText: 'اینستاگرام',
                            hintText: '@username',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.camera_alt),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _linkedinController,
                          decoration: const InputDecoration(
                            labelText: 'لینکدین',
                            hintText: 'username',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telegramController,
                          decoration: const InputDecoration(
                            labelText: 'تلگرام',
                            hintText: '@username',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.send),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _twitterController,
                          decoration: const InputDecoration(
                            labelText: 'توییتر',
                            hintText: '@username',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.alternate_email),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact Info
                  _buildSection(
                    title: 'اطلاعات تماس',
                    icon: Icons.contact_phone_outlined,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _websiteController,
                          decoration: const InputDecoration(
                            labelText: 'وب‌سایت',
                            hintText: 'https://example.com',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.language),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'ایمیل',
                            hintText: 'example@email.com',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'تلفن',
                            hintText: '09123456789',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Skills
                  _buildSection(
                    title: 'مهارت‌ها',
                    icon: Icons.star_outline,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _skillController,
                                decoration: const InputDecoration(
                                  labelText: 'افزودن مهارت',
                                  hintText: 'مثال: PHP',
                                  border: OutlineInputBorder(),
                                ),
                                onFieldSubmitted: (_) => _addSkill(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _addSkill,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        if (_skills.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _skills.asMap().entries.map((entry) {
                              final index = entry.key;
                              final skill = entry.value;
                              return Chip(
                                label: Text(skill),
                                onDeleted: () => _removeSkill(index),
                                deleteIcon: const Icon(Icons.close, size: 18),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Educational Credentials
                  _buildListSection(
                    title: 'مدارک تحصیلی',
                    icon: Icons.school_outlined,
                    items: _educationalCredentials,
                    onAdd: _addEducationalCredential,
                    onEdit: _editEducationalCredential,
                    onRemove: _removeEducationalCredential,
                    itemBuilder: (item) => '${item['degree'] ?? ''} - ${item['field'] ?? ''}',
                  ),
                  const SizedBox(height: 16),

                  // Work Experience
                  _buildListSection(
                    title: 'سوابق کاری',
                    icon: Icons.work_outline,
                    items: _workExperience,
                    onAdd: _addWorkExperience,
                    onEdit: _editWorkExperience,
                    onRemove: _removeWorkExperience,
                    itemBuilder: (item) => '${item['position'] ?? ''} در ${item['company'] ?? ''}',
                  ),
                  const SizedBox(height: 16),

                  // Completed Projects
                  _buildListSection(
                    title: 'پروژه‌های انجام شده',
                    icon: Icons.folder_outlined,
                    items: _completedProjects,
                    onAdd: _addCompletedProject,
                    onEdit: _editCompletedProject,
                    onRemove: _removeCompletedProject,
                    itemBuilder: (item) => item['title'] ?? '',
                  ),
                  const SizedBox(height: 16),

                  // Certifications
                  _buildListSection(
                    title: 'گواهینامه‌ها',
                    icon: Icons.verified_outlined,
                    items: _certifications,
                    onAdd: _addCertification,
                    onEdit: _editCertification,
                    onRemove: _removeCertification,
                    itemBuilder: (item) => item['name'] ?? '',
                  ),
                  const SizedBox(height: 16),

                  // Is Public
                  _buildSection(
                    title: 'تنظیمات حریم خصوصی',
                    icon: Icons.lock_outline,
                    child: SwitchListTile(
                      title: const Text(
                        'پروفایل عمومی',
                        style: TextStyle(fontFamily: 'Farhang'),
                      ),
                      subtitle: const Text(
                        'اگر فعال باشد، پروفایل شما برای همه قابل مشاهده است',
                        style: TextStyle(fontFamily: 'Farhang', fontSize: 12),
                      ),
                      value: _isPublic,
                      onChanged: (value) {
                        setState(() {
                          _isPublic = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'ذخیره پروفایل',
                              style: TextStyle(
                                fontFamily: 'Farhang',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkGray,
                    fontFamily: 'Farhang',
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildListSection({
    required String title,
    required IconData icon,
    required List<Map<String, String>> items,
    required VoidCallback onAdd,
    required Function(int) onEdit,
    required Function(int) onRemove,
    required String Function(Map<String, String>) itemBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                      fontFamily: 'Farhang',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  onPressed: onAdd,
                  tooltip: 'افزودن',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'موردی اضافه نشده است',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontFamily: 'Farhang',
                  ),
                ),
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                title: Text(
                  itemBuilder(item),
                  style: const TextStyle(fontFamily: 'Farhang'),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      color: AppColors.primary,
                      onPressed: () => onEdit(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      color: Colors.red,
                      onPressed: () => onRemove(index),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// Dialog for Educational Credential
class _EducationalCredentialDialog extends StatefulWidget {
  final Map<String, String>? credential;
  final Function(Map<String, String>) onSave;

  const _EducationalCredentialDialog({
    this.credential,
    required this.onSave,
  });

  @override
  State<_EducationalCredentialDialog> createState() => _EducationalCredentialDialogState();
}

class _EducationalCredentialDialogState extends State<_EducationalCredentialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _degreeController = TextEditingController();
  final _fieldController = TextEditingController();
  final _universityController = TextEditingController();
  final _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.credential != null) {
      _degreeController.text = widget.credential!['degree'] ?? '';
      _fieldController.text = widget.credential!['field'] ?? '';
      _universityController.text = widget.credential!['university'] ?? '';
      _yearController.text = widget.credential!['year'] ?? '';
    }
  }

  @override
  void dispose() {
    _degreeController.dispose();
    _fieldController.dispose();
    _universityController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'degree': _degreeController.text.trim(),
        'field': _fieldController.text.trim(),
        'university': _universityController.text.trim(),
        'year': _yearController.text.trim(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('مدرک تحصیلی', style: TextStyle(fontFamily: 'Farhang')),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _degreeController,
                  decoration: const InputDecoration(
                    labelText: 'مدرک',
                    hintText: 'مثال: کارشناسی',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fieldController,
                  decoration: const InputDecoration(
                    labelText: 'رشته',
                    hintText: 'مثال: مهندسی کامپیوتر',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _universityController,
                  decoration: const InputDecoration(
                    labelText: 'دانشگاه',
                    hintText: 'مثال: دانشگاه تهران',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'سال',
                    hintText: 'مثال: 1400',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف', style: TextStyle(fontFamily: 'Farhang')),
          ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ذخیره', style: TextStyle(fontFamily: 'Farhang')),
          ),
        ],
      ),
    );
  }
}

// Dialog for Work Experience
class _WorkExperienceDialog extends StatefulWidget {
  final Map<String, String>? experience;
  final Function(Map<String, String>) onSave;

  const _WorkExperienceDialog({
    this.experience,
    required this.onSave,
  });

  @override
  State<_WorkExperienceDialog> createState() => _WorkExperienceDialogState();
}

class _WorkExperienceDialogState extends State<_WorkExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.experience != null) {
      _companyController.text = widget.experience!['company'] ?? '';
      _positionController.text = widget.experience!['position'] ?? '';
      _startDateController.text = widget.experience!['start_date'] ?? '';
      _endDateController.text = widget.experience!['end_date'] ?? '';
      _descriptionController.text = widget.experience!['description'] ?? '';
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _positionController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'company': _companyController.text.trim(),
        'position': _positionController.text.trim(),
        'start_date': _startDateController.text.trim(),
        'end_date': _endDateController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('سابقه کاری', style: TextStyle(fontFamily: 'Farhang')),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _companyController,
                  decoration: const InputDecoration(
                    labelText: 'شرکت',
                    hintText: 'نام شرکت',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _positionController,
                  decoration: const InputDecoration(
                    labelText: 'سمت',
                    hintText: 'مثال: توسعه‌دهنده بک‌اند',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _startDateController,
                  decoration: const InputDecoration(
                    labelText: 'تاریخ شروع',
                    hintText: 'مثال: 1400',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(
                    labelText: 'تاریخ پایان',
                    hintText: 'مثال: 1402 یا "تا کنون"',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    hintText: 'توضیحات بیشتر...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف', style: TextStyle(fontFamily: 'Farhang')),
          ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ذخیره', style: TextStyle(fontFamily: 'Farhang')),
          ),
        ],
      ),
    );
  }
}

// Dialog for Completed Project
class _CompletedProjectDialog extends StatefulWidget {
  final Map<String, String>? project;
  final Function(Map<String, String>) onSave;

  const _CompletedProjectDialog({
    this.project,
    required this.onSave,
  });

  @override
  State<_CompletedProjectDialog> createState() => _CompletedProjectDialogState();
}

class _CompletedProjectDialogState extends State<_CompletedProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _yearController = TextEditingController();
  final _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _titleController.text = widget.project!['title'] ?? '';
      _descriptionController.text = widget.project!['description'] ?? '';
      _yearController.text = widget.project!['year'] ?? '';
      _linkController.text = widget.project!['link'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _yearController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'year': _yearController.text.trim(),
        'link': _linkController.text.trim(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('پروژه انجام شده', style: TextStyle(fontFamily: 'Farhang')),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'عنوان پروژه',
                    hintText: 'نام پروژه',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'توضیحات',
                    hintText: 'توضیحات پروژه...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'سال',
                    hintText: 'مثال: 1402',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'لینک',
                    hintText: 'آدرس پروژه (اختیاری)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف', style: TextStyle(fontFamily: 'Farhang')),
          ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ذخیره', style: TextStyle(fontFamily: 'Farhang')),
          ),
        ],
      ),
    );
  }
}

// Dialog for Certification
class _CertificationDialog extends StatefulWidget {
  final Map<String, String>? certification;
  final Function(Map<String, String>) onSave;

  const _CertificationDialog({
    this.certification,
    required this.onSave,
  });

  @override
  State<_CertificationDialog> createState() => _CertificationDialogState();
}

class _CertificationDialogState extends State<_CertificationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _yearController = TextEditingController();
  final _linkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.certification != null) {
      _nameController.text = widget.certification!['name'] ?? '';
      _issuerController.text = widget.certification!['issuer'] ?? '';
      _yearController.text = widget.certification!['year'] ?? '';
      _linkController.text = widget.certification!['link'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _yearController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      widget.onSave({
        'name': _nameController.text.trim(),
        'issuer': _issuerController.text.trim(),
        'year': _yearController.text.trim(),
        'link': _linkController.text.trim(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('گواهینامه', style: TextStyle(fontFamily: 'Farhang')),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'نام گواهینامه',
                    hintText: 'مثال: گواهینامه PHP',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _issuerController,
                  decoration: const InputDecoration(
                    labelText: 'صادرکننده',
                    hintText: 'مثال: سازمان فنی و حرفه‌ای',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _yearController,
                  decoration: const InputDecoration(
                    labelText: 'سال',
                    hintText: 'مثال: 1401',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: 'لینک',
                    hintText: 'آدرس گواهینامه (اختیاری)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف', style: TextStyle(fontFamily: 'Farhang')),
          ),
          ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('ذخیره', style: TextStyle(fontFamily: 'Farhang')),
          ),
        ],
      ),
    );
  }
}

