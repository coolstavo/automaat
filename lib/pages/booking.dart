import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'payment.dart';

class BookingPage extends StatefulWidget {
  final int id;
  final String title;
  final String body;
  final String pricePerDay;
  final Uint8List? imageBytes;

  const BookingPage({
    super.key,
    required this.id,
    required this.title,
    required this.body,
    required this.pricePerDay,
    this.imageBytes,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late DateTime _pickupDate;
  late DateTime _dropoffDate;
  late int _durationDays;
  TimeOfDay _pickupTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();

    _pickupDate = DateTime(today.year, today.month, today.day + 1);
    _dropoffDate = _pickupDate.add(const Duration(days: 2));
    _durationDays = _dropoffDate.difference(_pickupDate).inDays;
  }

  double get _pricePerDayDouble =>
      double.tryParse(widget.pricePerDay) ?? 0.0;

  double get _totalPrice => _durationDays * _pricePerDayDouble;

  Future<void> _selectPickupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _pickupDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Color(0xFF1C1C1C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _pickupDate = picked;

        if (_dropoffDate.isBefore(_pickupDate)) {
          _dropoffDate = _pickupDate.add(const Duration(days: 1));
        }

        _durationDays = _dropoffDate.difference(_pickupDate).inDays;
      });
    }
  }

  Future<void> _selectDropoffDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dropoffDate,
      firstDate: _pickupDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Color(0xFF1C1C1C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dropoffDate = picked;
        _durationDays = _dropoffDate.difference(_pickupDate).inDays;
      });
    }
  }

  Future<void> _selectPickupTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickupTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Color(0xFF1C1C1C),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _pickupTime = picked);
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[date.month - 1];
    return '$m ${date.day}, ${date.year}';
  }

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
                    'Book Your Ride',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car card
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: widget.imageBytes != null &&
                                widget.imageBytes!.isNotEmpty
                                ? Image.memory(
                              widget.imageBytes!,
                              width: 90,
                              height: 70,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              width: 90,
                              height: 70,
                              color: const Color(0xFF444444),
                              child: const Icon(
                                Icons.directions_car,
                                color: Colors.white70,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.body,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${widget.pricePerDay}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'per day',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Rental Period
                    const Text(
                      'Rental Period',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _bookingTile(
                      label: 'Pick-up Date',
                      value: _formatDate(_pickupDate),
                      icon: Icons.calendar_today_outlined,
                      onTap: _selectPickupDate,
                    ),

                    const SizedBox(height: 10),

                    _bookingTile(
                      label: 'Drop-off Date',
                      value: _formatDate(_dropoffDate),
                      icon: Icons.calendar_today_outlined,
                      onTap: _selectDropoffDate,
                    ),

                    const SizedBox(height: 20),

                    // Duration
                    const Text(
                      'Duration',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _durationDays > 1
                                ? () {
                              setState(() {
                                _durationDays--;
                                _dropoffDate = _pickupDate
                                    .add(Duration(days: _durationDays));
                              });
                            }
                                : null,
                            icon: const Icon(Icons.remove, color: Colors.white),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '$_durationDays',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Text(
                                  'Days',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _durationDays++;
                                _dropoffDate = _pickupDate
                                    .add(Duration(days: _durationDays));
                              });
                            },
                            icon: const Icon(Icons.add, color: Colors.white),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Pick-up Time
                    const Text(
                      'Pick-up Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _bookingTile(
                      label: 'Time',
                      value: _pickupTime.format(context),
                      icon: Icons.access_time,
                      onTap: _selectPickupTime,
                    ),

                    const SizedBox(height: 24),

                    // Price Summary
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        children: [
                          _priceRow(
                            label: 'Rental ($_durationDays days)',
                            value: '\$${_totalPrice.toStringAsFixed(0)}',
                          ),
                          const SizedBox(height: 8),
                          _priceRow(
                            label: 'Service fee',
                            value: '\$0',
                          ),
                          const Divider(color: Colors.white12, height: 24),
                          _priceRow(
                            label: 'Total',
                            value: '\$${_totalPrice.toStringAsFixed(0)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Confirm button → PaymentPage
            Container(
              color: const Color(0xFF111111),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () {
                    final periodLabel =
                        '${_formatDate(_pickupDate)} - ${_formatDate(_dropoffDate)}';

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentPage(
                          carId: widget.id,
                          fromDate: _pickupDate,
                          toDate: _dropoffDate,
                          carTitle: widget.title,
                          rentalPeriodLabel: periodLabel,
                          durationDays: _durationDays,
                          totalPrice: _totalPrice,
                          imageBytes: widget.imageBytes,
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _bookingTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  const _bookingTile({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right,
                  color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }
}

class _priceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _priceRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: Colors.white,
      fontSize: isBold ? 15 : 13,
      fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}
