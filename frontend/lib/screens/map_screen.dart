import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/field_model.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<FieldModel> _fields = [];
  bool _loading = true;
  bool _satelliteMode = false;
  final MapController _mapController = MapController();

  // Default center - India
  static const _defaultCenter = LatLng(25.5, 85.1);

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final fields = await ApiService.fetchAllFields();
      setState(() {
        _fields = fields;
        _loading = false;
      });
      // Zoom to first field if available
      if (fields.isNotEmpty) {
        final c = fields.first.centroid;
        if (c != null) {
          _mapController.move(LatLng(c[0], c[1]), 15);
        }
      }
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFieldBottomSheet(FieldModel field) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16213E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(field.name,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('👤 ${field.ownerName}',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            if (field.khasraNumber != null)
              Text('📋 Khasra: ${field.khasraNumber}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoChip('🌾 Area', '${field.areaBigha?.toStringAsFixed(2)} Bigha', Colors.green),
                _infoChip('📐 Perimeter', field.formattedPerimeter, Colors.blue),
                _infoChip('🏞 Sqm', '${field.areaSqm?.toStringAsFixed(0)} m²', Colors.amber),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  final c = field.centroid;
                  if (c != null) {
                    _mapController.move(LatLng(c[0], c[1]), 17);
                  }
                },
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Map par Dekho'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final tileUrl = _satelliteMode
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ ज़मीन नक्शा - Map'),
        actions: [
          IconButton(
            icon: Icon(_satelliteMode ? Icons.map : Icons.satellite),
            tooltip: _satelliteMode ? 'Normal Map' : 'Satellite View',
            onPressed: () => setState(() => _satelliteMode = !_satelliteMode),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loading = true);
              _loadFields();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
          : FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: 14,
                minZoom: 5,
                maxZoom: 19,
              ),
              children: [
                // Base tile layer
                TileLayer(
                  urlTemplate: tileUrl,
                  userAgentPackageName: 'com.villagemapping.app',
                ),

                // Field polygons
                PolygonLayer(
                  polygons: _fields.map((field) {
                    final pts = field.latLonCoordinates
                        .map((p) => LatLng(p[0], p[1]))
                        .toList();
                    return Polygon(
                      points: pts,
                      color: Colors.green.withOpacity(0.25),
                      borderColor: Colors.greenAccent,
                      borderStrokeWidth: 2.5,
                    );
                  }).toList(),
                ),

                // Field labels (markers at centroid)
                MarkerLayer(
                  markers: _fields.map((field) {
                    final c = field.centroid;
                    if (c == null) return null;
                    return Marker(
                      point: LatLng(c[0], c[1]),
                      width: 120,
                      height: 60,
                      child: GestureDetector(
                        onTap: () => _showFieldBottomSheet(field),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF16213E).withOpacity(0.85),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.greenAccent, width: 1),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    field.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                  Text(
                                    '${field.areaBigha?.toStringAsFixed(2)} B',
                                    style: const TextStyle(color: Colors.greenAccent, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).whereType<Marker>().toList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-field').then((_) => _loadFields()),
        backgroundColor: const Color(0xFF2D6A4F),
        icon: const Icon(Icons.add_location),
        label: const Text('Naya Khet'),
      ),
    );
  }
}
