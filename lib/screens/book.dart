import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  bool _isLoading = true;
  bool _isBooked = false;
  bool _isBooking = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _checkBookingStatus();
  }

  String get _selectedDateString {
    return '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
  }

  String _getFormattedDate(DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  Future<void> _checkBookingStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('bookings')
                .doc(_selectedDateString)
                .collection('students')
                .doc(uid)
                .get();

        setState(() {
          _isBooked = doc.exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking booking status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _bookForTonight() async {
    if (_isBooked || _isBooking) return;

    setState(() {
      _isBooking = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(_selectedDateString)
            .collection('students')
            .doc(uid)
            .set({
              'bookedAt': FieldValue.serverTimestamp(),
              'studentUID': uid,
              'status': 'active',
            });

        setState(() {
          _isBooked = true;
          _isBooking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gym session booked successfully! 💪'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isBooking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book session: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F2F2F),
        elevation: 0,
        title: const Text(
          'Book Gym Session',
          style: TextStyle(
            color: Color(0xFF00BFFF),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF00BFFF)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isBooked ? Icons.check_circle : Icons.fitness_center,
                size: 120,
                color: _isBooked ? Colors.green : const Color(0xFF00BFFF),
              ),
              const SizedBox(height: 30),
              Text(
                _isBooked ? 'Session Booked!' : 'Book Gym Session',
                style: TextStyle(
                  color: _isBooked ? Colors.green : const Color(0xFF00BFFF),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                _isBooked
                    ? 'You have booked your gym session for ${_getFormattedDate(_selectedDate)} 💪'
                    : 'Book your gym session for ${_getFormattedDate(_selectedDate)}',
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFF00BFFF))
              else if (_isBooked)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 40),
                      SizedBox(height: 10),
                      Text(
                        'Booking Confirmed',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _bookForTonight,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BFFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child:
                        _isBooking
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'Book for Tonight',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
