import 'package:flutter/material.dart';
import '../models/field_model.dart';
import '../services/api_service.dart';

class FieldsListScreen extends StatefulWidget {
  const FieldsListScreen({super.key});

  @override
  State<FieldsListScreen> createState() => _FieldsListScreenState();
}

class _FieldsListScreenState extends State<FieldsListScreen> {
  List<FieldModel> _fields = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fields = await ApiService.fetchAllFields();
      setState(() { _fields = fields; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteField(FieldModel field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Delete Karo?', style: TextStyle(color: Colors.white)),
        content: Text('"${field.name}" permanently delete ho jaayega.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.deleteField(field.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌾 Mere Khet'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
          : _fields.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.agriculture, size: 80, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text('Koi khet registered nahi hai',
                          style: TextStyle(color: Colors.white54, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/add-field').then((_) => _load()),
                        icon: const Icon(Icons.add),
                        label: const Text('Pehla Khet Jodo'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _fields.length,
                  itemBuilder: (ctx, i) {
                    final f = _fields[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(f.name,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteField(f),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('👤 ${f.ownerName}',
                                style: const TextStyle(color: Colors.white70)),
                            if (f.khasraNumber != null)
                              Text('📋 Khasra: ${f.khasraNumber}',
                                  style: const TextStyle(color: Colors.white54, fontSize: 13)),
                            const SizedBox(height: 12),
                            // Stats row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _statBadge('🌾 Bigha',
                                    f.areaBigha?.toStringAsFixed(3) ?? '?', Colors.green),
                                _statBadge('🏞 Acre',
                                    f.areaAcre?.toStringAsFixed(3) ?? '?', Colors.amber),
                                _statBadge('📏 Perimeter',
                                    f.formattedPerimeter, Colors.blue),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/map'),
                                icon: const Icon(Icons.map_outlined, size: 16),
                                label: const Text('Map par Dekho'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF2D6A4F),
                                  side: const BorderSide(color: Color(0xFF2D6A4F)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-field').then((_) => _load()),
        backgroundColor: const Color(0xFF2D6A4F),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
