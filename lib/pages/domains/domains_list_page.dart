import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/app_colors.dart';
import '../../services/api_service.dart';
import '../../models/domain.dart';
import 'domain_detail_page.dart';

class DomainsListPage extends StatefulWidget {
  const DomainsListPage({super.key});

  @override
  State<DomainsListPage> createState() => _DomainsListPageState();
}

class _DomainsListPageState extends State<DomainsListPage> {
  List<Domain> _domains = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  Future<void> _loadDomains() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getDomains(page: 1, limit: 20, isActive: 1);

      if (response['success'] == true) {
        final data = response['data'];
        List<Domain> domains = [];

        if (data is List) {
          domains = data.map((item) {
            if (item is Domain) {
              return item;
            } else if (item is Map<String, dynamic>) {
              return Domain.fromJson(item);
            } else {
              throw Exception('Invalid data type in domains');
            }
          }).toList();
        }

        setState(() {
          _domains = domains;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'خطا در دریافت حوزه‌ها';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading domains: $e');
      setState(() {
        _errorMessage = 'خطا در ارتباط با سرور: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'معرفی رشته‌ها',
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
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.darkGray,
                fontFamily: 'Farhang',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDomains,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'تلاش مجدد',
                style: TextStyle(fontFamily: 'Farhang', fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    if (_domains.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'حوزه‌ای یافت نشد',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontFamily: 'Farhang',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDomains,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _domains.length,
        itemBuilder: (context, index) {
          return _buildDomainCard(_domains[index]);
        },
      ),
    );
  }

  Widget _buildDomainCard(Domain domain) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DomainDetailPage(domain: domain),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.building,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          domain.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                            fontFamily: 'Farhang',
                          ),
                        ),
                        if (domain.address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.locationDot,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  domain.address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontFamily: 'Farhang',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_left,
                    color: AppColors.primary,
                  ),
                ],
              ),
              if (domain.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  domain.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontFamily: 'Farhang',
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (domain.capacity > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.users,
                      size: 12,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'شرکت کننده: ${domain.capacity} نفر',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'Farhang',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

