import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? _currentPosition;
  String _locationStatus = 'GPS dhundh rahe hain...';
  String _fieldStatus = '';
  bool _onRegisteredField = false;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _locationStatus = 'GPS service band hai');
      return;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      setState(() => _locationStatus = 'GPS permission nahi mili');
      return;
    }
    _startTracking();
  }

  void _startTracking() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _currentPosition = pos;
          _locationStatus =
              '📍 ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
        });
        _checkCurrentField(pos.latitude, pos.longitude);
      } catch (_) {}
    });
    // Trigger immediately
    Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((pos) {
      setState(() {
        _currentPosition = pos;
        _locationStatus =
            '📍 ${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      });
      _checkCurrentField(pos.latitude, pos.longitude);
    }).catchError((_) {});
  }

  Future<void> _checkCurrentField(double lat, double lon) async {
    try {
      final result = await ApiService.getFieldAtLocation(lat, lon);
      setState(() {
        _onRegisteredField = result['found'] == true;
        _fieldStatus = result['message'] ?? '';
      });
    } catch (_) {
      setState(() => _fieldStatus = 'Server se connect nahi ho pa raha');
    }
  }

  Widget _buildNavCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: Colors.white),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D6A4F),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.landscape, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ज़मीन नक्शा',
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        Text('Village Land Mapping',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.6))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Field Status Banner
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _onRegisteredField
                        ? const Color(0xFF2D6A4F).withOpacity(0.3)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _onRegisteredField
                          ? const Color(0xFF2D6A4F)
                          : Colors.orange.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _onRegisteredField ? Icons.check_circle : Icons.location_searching,
                        color: _onRegisteredField ? Colors.greenAccent : Colors.orange,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _fieldStatus.isEmpty ? 'Aapki location check ho rahi hai...' : _fieldStatus,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Navigation Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    children: [
                      _buildNavCard(
                        title: 'मेरे खेत',
                        subtitle: 'Registered plots dekho',
                        icon: Icons.agriculture,
                        color: const Color(0xFF2D6A4F),
                        route: '/fields',
                      ),
                      _buildNavCard(
                        title: 'नक्शा',
                        subtitle: 'Map par sabhi khet dekho',
                        icon: Icons.map,
                        color: const Color(0xFF1565C0),
                        route: '/map',
                      ),
                      _buildNavCard(
                        title: 'नई ज़मीन जोड़ें',
                        subtitle: 'GPS se boundary record karo',
                        icon: Icons.add_location_alt,
                        color: const Color(0xFFE65100),
                        route: '/add-field',
                      ),
                      _buildNavCard(
                        title: 'आस-पास के खेत',
                        subtitle: 'Nearby plots aur location check',
                        icon: Icons.near_me,
                        color: const Color(0xFF6A1B9A),
                        route: '/nearby',
                      ),
                    ],
                  ),
                ),

                // GPS Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_locationStatus,
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ),
                      if (_currentPosition != null)
                        Text(
                          '±${_currentPosition!.accuracy.toStringAsFixed(0)}m',
                          style: const TextStyle(color: Colors.amber, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
