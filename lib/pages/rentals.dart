import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../services/user_service.dart';
import 'damage_report.dart';
import 'home.dart';
import 'navigation.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _rentals = [];
  int? _customerId;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final customerId = await UserService.getCustomerId();
      if (customerId == null) throw Exception("Customer ID not found");

      _customerId = customerId;

      // Alleen rentals ophalen, geen car-matching hier
      final rentals = await CarService().getRentalsForCustomer(customerId);

      // Eventueel nog steeds per car groeperen op laatste rental
      final unique = <int, Map<String, dynamic>>{};
      for (final rental in rentals) {
        final carId = rental['car']?['id'];
        if (carId != null) {
          unique[carId] = rental;
        }
      }

      setState(() {
        _rentals = unique.values.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading bookings: $e")),
      );
    }
  }

  Future<void> _returnCar(int rentalId) async {
    try {
      await CarService().updateRentalStatus(
        rentalId: rentalId,
        newState: "RETURNED",
      );

      await _loadBookings();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Car returned successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        appBar: AppBar(
          title: const Text("My Bookings"),
          backgroundColor: const Color(0xFF111111),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
              );
            },
          ),
        ),
        body: _loading
            ? const Center(
          child: CircularProgressIndicator(color: Colors.white),
        )
            : _rentals.isEmpty
            ? const Center(
          child: Text(
            "You have no bookings yet",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _rentals.length,
          itemBuilder: (context, index) {
            final rental = _rentals[index];
            final rentalCar = rental['car'];
            final carId = rentalCar?['id'];

            final state = rental['state'];
            final isReturned = state == "RETURNED";
            final statusColor =
            isReturned ? Colors.grey : Colors.greenAccent;

            if (carId == null) {
              // Geen carId → toon basic info, geen navigatie
              return _buildBookingCardBasic(
                context: context,
                rental: rental,
                isReturned: isReturned,
                statusColor: statusColor,
              );
            }

            // Per booking de echte car ophalen via carId
            return FutureBuilder<Map<String, dynamic>>(
              future: CarService.getCarById(carId),
              builder: (context, snapshot) {
                final car = snapshot.data ?? rentalCar;

                // Foto decoderen
                Uint8List? imageBytes;
                if (car?['picture'] != null &&
                    car['picture'].toString().isNotEmpty) {
                  try {
                    imageBytes = base64Decode(car['picture']);
                  } catch (_) {}
                }

                final double? carLat =
                (car?['latitude'])?.toDouble();
                final double? carLng =
                (car?['longitude'])?.toDouble();

                final carTitle = ((car?['brand'] ?? "") +
                    " " +
                    (car?['model'] ?? ""))
                    .trim();
                final displayTitle =
                carTitle.isEmpty ? (car?['title'] ?? "Car") : carTitle;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1C),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FOTO
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageBytes != null
                            ? Image.memory(
                          imageBytes,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          height: 160,
                          width: double.infinity,
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.directions_car,
                            color: Colors.white54,
                            size: 48,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // TITEL
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // DATUM
                      Text(
                        "${rental['fromDate']} → ${rental['toDate']}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // STATUS
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isReturned ? "Returned" : "Active",
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // RETURN BUTTON
                      if (!isReturned)
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () =>
                                _returnCar(rental['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              "Return Car",
                              style:
                              TextStyle(letterSpacing: 1),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // DAMAGE REPORT BUTTON
                      if (!isReturned)
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DamageReportPage(
                                        rentalId: rental['id'],
                                        carId: carId,
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              "Report Damage",
                              style:
                              TextStyle(letterSpacing: 1),
                            ),
                          ),
                        ),

                      const SizedBox(height: 8),

                      // NAVIGATE BUTTON
                      if (!isReturned &&
                          carLat != null &&
                          carLng != null)
                        SizedBox(
                          width: double.infinity,
                          height: 42,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookingNavigationPage(
                                        carLat: carLat,
                                        carLng: carLng,
                                        carTitle: displayTitle,
                                        carPictureBase64: car?['picture'],
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              "Navigate to Car",
                              style:
                              TextStyle(letterSpacing: 1),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Fallback kaart als er geen carId is
  Widget _buildBookingCardBasic({
    required BuildContext context,
    required Map<String, dynamic> rental,
    required bool isReturned,
    required Color statusColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Car",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${rental['fromDate']} → ${rental['toDate']}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isReturned ? "Returned" : "Active",
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!isReturned)
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () => _returnCar(rental['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: const Text(
                  "Return Car",
                  style: TextStyle(letterSpacing: 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
