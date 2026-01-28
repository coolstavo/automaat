// damages.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/car_service.dart';
import 'damage_report.dart';

class DamagesPage extends StatefulWidget {
  final int rentalId;
  final int carId;

  const DamagesPage({super.key, required this.rentalId, required this.carId});

  @override
  State<DamagesPage> createState() => _DamagesPageState();
}

class _DamagesPageState extends State<DamagesPage> {
  bool _loading = true;
  Map<String, dynamic>? _car;
  List<Map<String, dynamic>> _damages = [];

  @override
  void initState() {
    super.initState();
    _loadCarAndDamages();
  }

  Future<void> _loadCarAndDamages() async {
    setState(() => _loading = true);
    try {
      // Auto ophalen
      final car = await CarService.getCarById(widget.carId);
      // Schades ophalen voor deze rental
      final inspections = await CarService.getInspectionsForRental(widget.rentalId);

      setState(() {
        _car = car;
        _damages = inspections;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fout bij laden: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Damages")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DamageReportPage(
                rentalId: widget.rentalId,
                carId: widget.carId,
              ),
            ),
          ).then((_) => _loadCarAndDamages());
        },
        child: const Icon(Icons.add),
        tooltip: "Report New Damage",
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------------------------
          // AUTO INFO BOVENAAN
          if (_car != null)
            Row(
              children: [
                _car!['picture'] != null
                    ? Image.memory(
                  base64Decode(_car!['picture']),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Icon(Icons.directions_car, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "${_car!['brand']} ${_car!['model']}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          if (_car != null) const SizedBox(height: 16),

          // ------------------------------------------------------------
          // GEMELDE SCHADES
          _damages.isEmpty
              ? const Center(child: Text("No damages reported yet"))
              : Column(
            children: _damages.map((damage) {
              Uint8List? imageBytes;
              if (damage['photo'] != null &&
                  damage['photo'].toString().isNotEmpty) {
                try {
                  imageBytes = base64Decode(damage['photo']);
                } catch (_) {}
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "ID: ${damage['id']}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text("Result: ${damage['result'] ?? ''}"),
                      const SizedBox(height: 6),
                      Text("Odometer: ${damage['odometer'] ?? ''} km"),
                      const SizedBox(height: 6),
                      Text("Description: ${damage['description'] ?? ''}"),
                      const SizedBox(height: 6),
                      if (imageBytes != null)
                        Image.memory(imageBytes, height: 180, fit: BoxFit.cover),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
