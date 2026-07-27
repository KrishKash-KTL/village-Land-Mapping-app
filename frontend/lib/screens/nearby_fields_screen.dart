import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class NearbyFieldsScreen extends StatefulWidget {
  const NearbyFieldsScreen({super.key});

  @override
  State<NearbyFieldsScreen> createState() => _NearbyFieldsScreenState();
}

class _NearbyFieldsScreenState extends State<NearbyFieldsScreen> {
  bool _loading = true;
  Position? _pos;
  List<Map<String, dynamic>> _nearby = [];
  Map<String, dynamic>? _standing;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { _loading = true; _errorMsg = ''; });
    try {
      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() => _pos = pos);

      final nearby = await ApiService.getNearbyFields(
          pos.latitude, pos.longitude, radiusM: 1000);
      final standing = await ApiService.getFieldAtLocation(
          pos.latitude, pos.longitude);

      setState(() {
        _nearby = nearby;
        _standing = standing;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📡 Aas-paas ke Khet'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
          : _errorMsg.isNotEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.wifi_off, size: 60, color: Colors.white24),
                    const SizedBox(height: 12),
                    Text('Server se connect nahi ho paya\n\n$_errorMsg',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                        onPressed: _fetchData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Dobara Try Karo')),
                  ]),
                )
              : ListView(
                  padding: const EdgeInsets.all(14),
                  children: [
                    // Current location info
                    if (_pos != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_pos!.latitude.toStringAsFixed(5)}, ${_pos!.longitude.toStringAsFixed(5)}  ±${_pos!.accuracy.toStringAsFixed(0)}m',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),

                    // Standing on banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _standing?['found'] == true
                              ? [const Color(0xFF1B5E20), const Color(0xFF2D6A4F)]
                              : [Colors.orange.shade900, Colors.orange.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('आप किस खेत पर खड़े हैं?',
                              style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 6),
                          Text(
                            _standing?['message'] ?? 'Pata nahi chala',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (_standing?['found'] == true && _standing!['field'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Area: ${(_standing!['field']['area_bigha'] as num?)?.toStringAsFixed(3) ?? '?'} Bigha',
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 13),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Nearby list header
                    Text('1 KM ke andar ${_nearby.length} khet mile:',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),

                    // Nearby fields
                    if (_nearby.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('Aas-paas koi registered khet nahi mila.',
                              style: TextStyle(color: Colors.white38)),
                        ),
                      )
                    else
                      ..._nearby.map((f) => Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.agriculture, color: Colors.greenAccent),
                          ),
                          title: Text(f['name'] ?? '',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('👤 ${f['owner_name'] ?? ''}',
                                  style: const TextStyle(color: Colors.white70)),
                              Text('🌾 ${(f['area_bigha'] as num?)?.toStringAsFixed(3) ?? '?'} Bigha',
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.near_me, color: Colors.blue, size: 16),
                              Text('${(f['distance_m'] as num?)?.toStringAsFixed(0) ?? '?'} m',
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          isThreeLine: true,
                        ),
                      )),
                  ],
                ),
    );
  }
}
