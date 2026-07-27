import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';

class AddFieldScreen extends StatefulWidget {
  const AddFieldScreen({super.key});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ownerCtrl = TextEditingController();
  final _khasraCtrl = TextEditingController();

  // [lat, lon]
  final List<List<double>> _points = [];
  bool _walkMode = false;
  bool _recording = false;
  Timer? _recordTimer;
  bool _submitting = false;
  Position? _currentPos;

  @override
  void dispose() {
    _recordTimer?.cancel();
    _nameCtrl.dispose();
    _ownerCtrl.dispose();
    _khasraCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentPosition() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _currentPos = pos);
    } catch (_) {}
  }

  void _startRecording() {
    setState(() => _recording = true);
    _recordTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentPos = pos;
          _points.add([pos.latitude, pos.longitude]);
        });
      } catch (_) {}
    });
  }

  void _stopRecording() {
    _recordTimer?.cancel();
    setState(() => _recording = false);
  }

  void _addPointManually() async {
    await _getCurrentPosition();
    if (_currentPos != null) {
      setState(() => _points.add([_currentPos!.latitude, _currentPos!.longitude]));
    }
  }

  void _undoLastPoint() {
    if (_points.isNotEmpty) setState(() => _points.removeLast());
  }

  /// Approximate area in sqm using Shoelace formula on flat earth (rough estimate for display)
  double _calculateApproxAreaSqm() {
    if (_points.length < 3) return 0;
    const double R = 6371000; // Earth radius in meters
    double area = 0;
    int n = _points.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      final lat1 = _points[i][0] * pi / 180;
      final lat2 = _points[j][0] * pi / 180;
      final lon1 = _points[i][1] * pi / 180;
      final lon2 = _points[j][1] * pi / 180;
      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }
    area = (area * R * R / 2).abs();
    return area;
  }

  double get _approxBigha => _calculateApproxAreaSqm() / 2529.3;
  double get _approxAcre => _calculateApproxAreaSqm() / 4046.86;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_points.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kam se kam 3 GPS points record karo boundary ke liye!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final field = await ApiService.createField(
        name: _nameCtrl.text.trim(),
        ownerName: _ownerCtrl.text.trim(),
        khasraNumber: _khasraCtrl.text.trim().isEmpty ? null : _khasraCtrl.text.trim(),
        coordinates: _points,
      );
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: const Text('✅ Khet Registered!', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.name, style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Area: ${field.formattedArea}', style: const TextStyle(color: Colors.white70)),
                Text('Perimeter: ${field.formattedPerimeter}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Done', style: TextStyle(color: Colors.greenAccent)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sqm = _calculateApproxAreaSqm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ नई ज़मीन जोड़ें'),
        actions: [
          TextButton.icon(
            onPressed: _points.isEmpty ? null : _undoLastPoint,
            icon: const Icon(Icons.undo, color: Colors.orange),
            label: const Text('Undo', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Live area display
          if (_points.isNotEmpty)
            Container(
              color: const Color(0xFF0F3460),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('📍 ${_points.length} Points',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('🌾 ${_approxBigha.toStringAsFixed(3)} Bigha',
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  Text('📐 ${_approxAcre.toStringAsFixed(3)} Acre',
                      style: const TextStyle(color: Colors.amber)),
                  Text('📏 ${sqm.toStringAsFixed(0)} m²',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),

          // Mini Map
          SizedBox(
            height: 240,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _currentPos != null
                    ? LatLng(_currentPos!.latitude, _currentPos!.longitude)
                    : const LatLng(25.5, 85.1),
                initialZoom: 17,
                onLongPress: _walkMode
                    ? null
                    : (_, latlng) {
                        setState(() => _points.add([latlng.latitude, latlng.longitude]));
                      },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.villagemapping.app',
                ),
                if (_points.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _points.map((p) => LatLng(p[0], p[1])).toList(),
                        color: Colors.redAccent,
                        strokeWidth: 2.5,
                      ),
                    ],
                  ),
                if (_points.length >= 3)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: _points.map((p) => LatLng(p[0], p[1])).toList(),
                        color: Colors.green.withOpacity(0.2),
                        borderColor: Colors.greenAccent,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: _points.asMap().entries.map((e) {
                    return Marker(
                      point: LatLng(e.value[0], e.value[1]),
                      width: 24, height: 24,
                      child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: Center(
                          child: Text('${e.key + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Controls + Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Mode Switcher
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() { _walkMode = false; _stopRecording(); }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: !_walkMode ? const Color(0xFF2D6A4F) : Colors.white12,
                                borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                              ),
                              child: const Text('🖱️ Manual (Long Press)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _walkMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _walkMode ? const Color(0xFF2D6A4F) : Colors.white12,
                                borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                              ),
                              child: const Text('🚶 Walk Mode (Auto GPS)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Walk Mode Controls
                    if (_walkMode) ...[
                      _recording
                          ? ElevatedButton.icon(
                              onPressed: _stopRecording,
                              icon: const Icon(Icons.stop_circle),
                              label: const Text('Recording Band Karo'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            )
                          : ElevatedButton.icon(
                              onPressed: _startRecording,
                              icon: const Icon(Icons.play_circle),
                              label: const Text('Chalna Shuru Karo (Auto GPS)'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                      const SizedBox(height: 4),
                      const Text('Har 3 second mein GPS point record hoga',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 12),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: _addPointManually,
                        icon: const Icon(Icons.add_location),
                        label: const Text('Current Location Add Karo'),
                      ),
                      const SizedBox(height: 4),
                      const Text('Ya map par long-press karke point daalo',
                          style: TextStyle(color: Colors.white54, fontSize: 11)),
                      const SizedBox(height: 12),
                    ],

                    // Form Fields
                    TextFormField(
                      controller: _nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Khet ka Naam *', Icons.landscape),
                      validator: (v) => v!.isEmpty ? 'Naam zaroori hai' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ownerCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Malik ka Naam *', Icons.person),
                      validator: (v) => v!.isEmpty ? 'Malik ka naam zaroori hai' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _khasraCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Khasra Number (Optional)', Icons.numbers),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('✅ Khet Register Karo', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white38),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white24),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF2D6A4F)),
        borderRadius: BorderRadius.circular(10),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
