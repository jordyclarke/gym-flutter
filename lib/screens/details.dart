import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00BFFF).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF00BFFF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    final selfieUrl = _userData?['selfieUrl'] as String?;

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF00BFFF), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child:
            selfieUrl != null && selfieUrl.isNotEmpty
                ? Image.network(
                  selfieUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00BFFF),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.person,
                      size: 80,
                      color: Color(0xFF00BFFF),
                    );
                  },
                )
                : const Icon(Icons.person, size: 80, color: Color(0xFF00BFFF)),
      ),
    );
  }

  String _formatScholarType(String? scholarType) {
    if (scholarType == null) return 'Not specified';
    return scholarType == 'hostel' ? 'Hostel Scholar' : 'Day Scholar';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF2F2F2F),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
        ),
      );
    }

    if (_userData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF2F2F2F),
        appBar: AppBar(
          backgroundColor: const Color(0xFF2F2F2F),
          elevation: 0,
          title: const Text(
            'My Details',
            style: TextStyle(
              color: Color(0xFF00BFFF),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Color(0xFF00BFFF)),
        ),
        body: const Center(
          child: Text(
            'No profile data found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF2F2F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F2F2F),
        elevation: 0,
        title: const Text(
          'My Details',
          style: TextStyle(
            color: Color(0xFF00BFFF),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF00BFFF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Image
            _buildProfileImage(),
            const SizedBox(height: 30),

            // User Details
            _buildDetailRow('Name', _userData!['name'] ?? 'Not specified'),
            _buildDetailRow(
              'Surname',
              _userData!['surname'] ?? 'Not specified',
            ),
            _buildDetailRow('Grade', _userData!['grade'] ?? 'Not specified'),
            _buildDetailRow(
              'Scholar Type',
              _formatScholarType(_userData!['scholarType']),
            ),

            // Show hostel name only if it's a hostel scholar
            if (_userData!['scholarType'] == 'hostel' &&
                _userData!['hostelName'] != null &&
                _userData!['hostelName'].toString().isNotEmpty)
              _buildDetailRow('Hostel Name', _userData!['hostelName']),

            _buildDetailRow(
              'Student Number',
              _userData!['studentNumber'] ?? 'Not specified',
            ),

            // Profile Status
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.green),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Profile is locked and cannot be modified',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
