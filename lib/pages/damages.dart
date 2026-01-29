import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../services/user_service.dart';

class DamagesPage extends StatefulWidget {
  const DamagesPage({super.key});

  @override
  State<DamagesPage> createState() => _DamagesPageState();
}

class _DamagesPageState extends State<DamagesPage> {
  bool _loading = true;
  Map<String, dynamic>? _me;
  List<Map<String, dynamic>> _inspections = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final me = await UserService.getMe();

      // 👉 AANNAME: backend geeft inspections van ingelogde user
      final inspections = await CarService.getInspectionsForUser();

      setState(() {
        _me = me;
        _inspections = inspections;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fout bij laden: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------
  String _resultLabel(String? result) {
    switch (result) {
      case 'OK':
        return 'Geen schade';
      case 'DAMAGE':
        return 'Schade vastgesteld';
      case 'REJECTED':
        return 'Afgekeurd';
      default:
        return '';
    }
  }

  Widget _statusChip(Map<String, dynamic> inspection) {
    final completed = inspection['completed'];

    if (completed == null) {
      return const Chip(
        label: Text("In behandeling"),
        backgroundColor: Colors.orange,
      );
    }

    return const Chip(
      label: Text("Afgehandeld"),
      backgroundColor: Colors.green,
    );
  }

  Widget _completedDate(Map<String, dynamic> inspection) {
    if (inspection['completed'] == null) return const SizedBox();

    final date = DateTime.parse(inspection['completed']).toLocal();

    return Text(
      "Afgehandeld op: "
          "${date.day}-${date.month}-${date.year} "
          "${date.hour}:${date.minute.toString().padLeft(2, '0')}",
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    );
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mijn schades")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ------------------------------------------------------------
            // USER INFO
            // ------------------------------------------------------------
            if (_me != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text(
                  "${_me!['firstName']} ${_me!['lastName']}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text("Gemelde schades"),
              ),

            const SizedBox(height: 16),

            // ------------------------------------------------------------
            // INSPECTIONS
            // ------------------------------------------------------------
            if (_inspections.isEmpty)
              const Center(
                child: Text("Nog geen schades gemeld"),
              ),

            ..._inspections.map(_buildInspectionCard),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectionCard(Map<String, dynamic> inspection) {
    final car = inspection['car'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ------------------------------------------------------------
            // AUTO INFO + STATUS
            // ------------------------------------------------------------
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: car?['picture'] != null
                  ? Image.memory(
                base64Decode(car['picture']),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.directions_car),
              title: Text(
                "${car?['brand'] ?? ''} ${car?['model'] ?? ''}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: _statusChip(inspection),
            ),

            const SizedBox(height: 6),
            Text("Odometer: ${inspection['odometer']} km"),
            const SizedBox(height: 6),
            Text("Schade: ${inspection['description']}"),

            const SizedBox(height: 8),

            // ------------------------------------------------------------
            // RESULT + DATUM
            // ------------------------------------------------------------
            if (inspection['completed'] != null) ...[
              Text(
                "Resultaat: ${_resultLabel(inspection['result'])}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              _completedDate(inspection),
            ],

            const SizedBox(height: 8),

            // ------------------------------------------------------------
            // FOTO
            // ------------------------------------------------------------
            if (inspection['photo'] != null &&
                inspection['photo'].toString().isNotEmpty)
              Image.memory(
                base64Decode(inspection['photo']),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
          ],
        ),
      ),
    );
  }
}
