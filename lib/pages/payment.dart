import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/car_service.dart';
import '../services/user_service.dart';
import 'rentals.dart';

class PaymentPage extends StatefulWidget {
  final int carId;
  final DateTime fromDate;
  final DateTime toDate;

  final String carTitle;
  final String rentalPeriodLabel;
  final int durationDays;
  final double totalPrice;
  final Uint8List? imageBytes;

  const PaymentPage({
    super.key,
    required this.carId,
    required this.fromDate,
    required this.toDate,
    required this.carTitle,
    required this.rentalPeriodLabel,
    required this.durationDays,
    required this.totalPrice,
    this.imageBytes,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  int _selectedCardIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white10,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Payment',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Secure Payment banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064C25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.lock, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Secure Payment',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Your payment information is encrypted',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Saved Cards',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _cardTile(
                      index: 0,
                      brand: 'Visa',
                      last4: '4242',
                      expiry: '12/25',
                      isDefault: true,
                    ),
                    const SizedBox(height: 10),

                    _cardTile(
                      index: 1,
                      brand: 'Mastercard',
                      last4: '8888',
                      expiry: '09/26',
                      isDefault: false,
                    ),

                    const SizedBox(height: 14),
                    const Center(
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add new card flow komt hier.'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1C),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.credit_card,
                                color: Colors.white70, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Add New Card',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Booking Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: widget.imageBytes != null &&
                                    widget.imageBytes!.isNotEmpty
                                    ? Image.memory(
                                  widget.imageBytes!,
                                  width: 80,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                                    : Container(
                                  width: 80,
                                  height: 60,
                                  color: const Color(0xFF444444),
                                  child: const Icon(
                                    Icons.directions_car,
                                    color: Colors.white70,
                                    size: 28,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.carTitle,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.rentalPeriodLabel,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(color: Colors.white12, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Rental (${widget.durationDays} days)',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '\$${widget.totalPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // PAY BUTTON (AANGEPAST)
            Container(
              color: const Color(0xFF111111),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton.icon(
                  onPressed: () async {
                    try {
                      // Haal customerId via fallback
                      final customerId = await UserService.getCustomerId();

                      if (customerId == null) {
                        throw Exception("Customer ID not found");
                      }

                      // Maak rental aan
                      await CarService().createRental(
                        carId: widget.carId,
                        customerId: customerId,
                        fromDate: widget.fromDate,
                        toDate: widget.toDate,
                        longitude: 0.0,
                        latitude: 0.0,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Payment of \$${widget.totalPrice.toStringAsFixed(0)} successful. Booking saved.',
                          ),
                        ),
                      );

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const MyBookingsPage()),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  },

                  icon: const Icon(Icons.lock, size: 18),
                  label: Text(
                    'Pay \$${widget.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 2),
          ],
        ),
      ),
    );
  }

  Widget _cardTile({
    required int index,
    required String brand,
    required String last4,
    required String expiry,
    required bool isDefault,
  }) {
    final selected = _selectedCardIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCardIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.credit_card, color: Colors.white70, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$brand •••• $last4',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expiry,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            if (isDefault)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: Colors.white70,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
