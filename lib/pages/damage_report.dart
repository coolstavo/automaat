import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/car_service.dart';
import '../services/user_service.dart';

class DamageReportPage extends StatefulWidget {
  final int carId;
  final int rentalId;

  const DamageReportPage({
    super.key,
    required this.carId,
    required this.rentalId,
  });

  @override
  State<DamageReportPage> createState() => _DamageReportPageState();
}

class _DamageReportPageState extends State<DamageReportPage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _odometerController = TextEditingController();
  final TextEditingController _resultController =
  TextEditingController(text: "damage");

  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _loading = false;

  String? _userName;
  Map<String, dynamic>? _car;
  Uint8List? _carImageBytes;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadCar();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _odometerController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  // Huurder info
  Future<void> _loadUser() async {
    final me = await UserService.getMe();
    setState(() {
      _userName = "${me['firstName']} ${me['lastName']}";
    });
  }

  // Auto info (alleen UI)
  Future<void> _loadCar() async {
    final cars = await CarService.getCars();
    final car = cars.firstWhere(
          (c) => c['id'] == widget.carId,
      orElse: () => {}, // lege map als fallback
    );

    setState(() {
      _car = car.isNotEmpty ? car : null;

      // decode foto voor UI
      if (_car != null &&
          _car!['picture'] != null &&
          _car!['picture'].toString().isNotEmpty) {
        try {
          _carImageBytes = base64Decode(_car!['picture']);
        } catch (_) {
          _carImageBytes = null;
        }
      }
    });
  }

  // Schadefoto picker
  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(source: source);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  // Schade rapport submit
  Future<void> _submitDamageReport() async {
    if (_descriptionController.text.isEmpty ||
        _odometerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Beschrijving en kilometerstand verplicht")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final String? photoBase64 =
      _imageBytes != null ? base64Encode(_imageBytes!) : null;

      await CarService().createInspection(
        carId: widget.carId,
        rentalId: widget.rentalId,
        description: _descriptionController.text,
        result: _resultController.text,
        odometer: int.parse(_odometerController.text),
        photoBase64: photoBase64,
        photoContentType: _imageBytes != null ? "image/jpeg" : null,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Schade succesvol gemeld")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fout bij melden schade: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Damage")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            // Auto info + foto bovenaan (UI only)
            if (_car != null)
              Row(
                children: [
                  _carImageBytes != null
                      ? Image.memory(
                    _carImageBytes!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  )
                      : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child:
                    const Icon(Icons.directions_car, size: 40),
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

            const SizedBox(height: 16),
            Text(
              "Reported by: ${_userName ?? '...'}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 16),
            // Kilometerstand
            TextField(
              controller: _odometerController,
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Current odometer (km)",
                labelStyle: const TextStyle(color: Colors.black87),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),

            const SizedBox(height: 16),
            // Beschrijving
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.black),
              maxLines: 4,
              decoration: InputDecoration(
                labelText: "Damage description",
                labelStyle: const TextStyle(color: Colors.black87),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),

            const SizedBox(height: 16),
            // Schadefoto preview
            _imageBytes != null
                ? Image.memory(_imageBytes!, height: 180)
                : Container(
              height: 180,
              color: Colors.grey[200],
              alignment: Alignment.center,
              child: const Text("No photo selected"),
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _loading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitDamageReport,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Submit Damage Report",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
