import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';
import '../../models/domain.dart';

class DomainDetailPage extends StatelessWidget {
  final Domain domain;

  const DomainDetailPage({super.key, required this.domain});

  void _openMapService(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  void _openGoogleMaps() async {
    final lat = domain.latitude;
    final lng = domain.longitude;
    if (lat != null && lng != null) {
      // Try Google Maps app first, fallback to web
      final appUrl = 'comgooglemaps://?q=$lat,$lng&center=$lat,$lng&zoom=14';
      final webUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
      
      final appUri = Uri.parse(appUrl);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        _openMapService(webUrl);
      }
    }
  }

  void _openBalad() async {
    final lat = domain.latitude;
    final lng = domain.longitude;
    if (lat != null && lng != null) {
      // Try Balad app first, fallback to web
      // Format: balad://navigate?location=LATITUDE,LONGITUDE
      final appUrl = 'balad://navigate?location=$lat,$lng';
      final webUrl = 'https://balad.ir/map/@$lat,$lng,14.0z';
      
      final appUri = Uri.parse(appUrl);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        // If Balad app is not installed, try web
        _openMapService(webUrl);
      }
    }
  }

  void _openNeshan() async {
    final lat = domain.latitude;
    final lng = domain.longitude;
    if (lat != null && lng != null) {
      // Try Neshan app first, fallback to web
      // Format: neshan://navigate?lat=LATITUDE&lng=LONGITUDE
      final appUrl = 'neshan://navigate?lat=$lat&lng=$lng';
      final webUrl = 'https://neshan.org/maps/@$lat,$lng,14.0z';
      
      final appUri = Uri.parse(appUrl);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else {
        _openMapService(webUrl);
      }
    }
  }

  void _callPhone() async {
    final uri = Uri.parse('tel:${domain.contactPhone}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _sendEmail() async {
    final uri = Uri.parse('mailto:${domain.contactEmail}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = domain.latitude;
    final lng = domain.longitude;
    final hasLocation = lat != null && lng != null;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            domain.name,
            style: const TextStyle(
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Map Section
                if (hasLocation)
                  Container(
                    height: 300,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(lat, lng),
                        initialZoom: 15.0,
                        minZoom: 5.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.pishgaman.app',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 80,
                              height: 80,
                              child: Icon(
                                FontAwesomeIcons.locationPin,
                                color: AppColors.primary,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    height: 200,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 48,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'موقعیت جغرافیایی در دسترس نیست',
                            style: TextStyle(
                              fontFamily: 'Farhang',
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Map Service Links
                if (hasLocation) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'باز کردن در نقشه',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                            fontFamily: 'Farhang',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMapServiceButton(
                              'Google Maps',
                              FontAwesomeIcons.map,
                              _openGoogleMaps,
                              Colors.blue,
                            ),
                            _buildMapServiceButton(
                              'بلد',
                              FontAwesomeIcons.mapLocationDot,
                              _openBalad,
                              const Color(0xFF00A8FF),
                            ),
                            _buildMapServiceButton(
                              'نشان',
                              FontAwesomeIcons.map,
                              _openNeshan,
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Description
                if (domain.description.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'توضیحات',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                            fontFamily: 'Farhang',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          domain.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontFamily: 'Farhang',
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Address
                if (domain.address.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInfoCard(
                      icon: FontAwesomeIcons.locationDot,
                      title: 'آدرس',
                      content: domain.address,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Contact Information
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (domain.contactPhone.isNotEmpty)
                        _buildInfoCard(
                          icon: FontAwesomeIcons.phone,
                          title: 'تلفن تماس',
                          content: domain.contactPhone,
                          color: Colors.green,
                          onTap: _callPhone,
                        ),
                      if (domain.contactPhone.isNotEmpty &&
                          domain.contactEmail.isNotEmpty)
                        const SizedBox(height: 12),
                      if (domain.contactEmail.isNotEmpty)
                        _buildInfoCard(
                          icon: FontAwesomeIcons.envelope,
                          title: 'ایمیل',
                          content: domain.contactEmail,
                          color: Colors.blue,
                          onTap: _sendEmail,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Capacity
                if (domain.capacity > 0) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildInfoCard(
                      icon: FontAwesomeIcons.users,
                      title: 'شرکت کننده',
                      content: '${domain.capacity} نفر',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Instructors
                if (domain.instructors.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'اساتید',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                            fontFamily: 'Farhang',
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...domain.instructors.map((instructor) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Icon(
                                    FontAwesomeIcons.userGraduate,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  instructor.name,
                                  style: const TextStyle(
                                    fontFamily: 'Farhang',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (instructor.title.isNotEmpty)
                                      Text(
                                        instructor.title,
                                        style: const TextStyle(
                                          fontFamily: 'Farhang',
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (instructor.expertise.isNotEmpty)
                                      Text(
                                        'تخصص: ${instructor.expertise}',
                                        style: TextStyle(
                                          fontFamily: 'Farhang',
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Course Outlines
                if (domain.courseOutlines.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'سرفصل‌های دوره',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGray,
                            fontFamily: 'Farhang',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: domain.courseOutlines.map((outline) {
                            return Chip(
                              label: Text(
                                outline,
                                style: const TextStyle(
                                  fontFamily: 'Farhang',
                                  fontSize: 12,
                                ),
                              ),
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              labelStyle: const TextStyle(
                                color: AppColors.primary,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Notes
                if (domain.notes != null && domain.notes!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.circleInfo,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'یادداشت',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                    fontFamily: 'Farhang',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              domain.notes!,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                                fontFamily: 'Farhang',
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapServiceButton(
    String label,
    IconData icon,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Farhang',
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontFamily: 'Farhang',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGray,
                        fontFamily: 'Farhang',
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_left,
                  color: AppColors.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

