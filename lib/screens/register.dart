import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accessCodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _studentNumberController = TextEditingController();

  String _selectedGrade = '8';
  String _scholarType = 'Day Scholar';
  String _hostelName = '';
  File? _selfieImage;
  bool _isLoading = false;
  bool _accessCodeVerified = false;
  String? _verifiedAccessCode;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Check if user is already registered before showing access code verification
    _checkExistingRegistration();
  }

  Future<void> _checkExistingRegistration() async {
    try {
      // Sign in anonymously if not already signed in
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
        print('Signed in anonymously for registration');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('Current user ID: ${user.uid}');

        // Check if user already has a profile in Firestore
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        print('User document exists: ${doc.exists}');
        if (doc.exists) {
          print('User document data: ${doc.data()}');
        }

        if (doc.exists && doc.data() != null) {
          // User is already registered, navigate to home
          print('User already registered, navigating to home');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
          return;
        }
      }

      // User is not registered, continue with normal registration flow
      print('User not registered, showing access code verification');
    } catch (e) {
      print('Error checking existing registration: $e');
      _showErrorDialog('Failed to initialize registration. Please try again.');
    }
  }

  Future<void> _verifyAccessCode() async {
    if (_accessCodeController.text.trim().length != 4) {
      _showErrorDialog('Please enter a 4-digit access code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final enteredCode = _accessCodeController.text.trim();
      print('Verifying access code: $enteredCode');

      // Query Firestore for valid access codes
      final codeQuery =
          await FirebaseFirestore.instance
              .collection('accessCodes')
              .where('code', isEqualTo: enteredCode)
              .where('status', isEqualTo: 'valid')
              .where('used', isEqualTo: false)
              .get();

      print('Query returned ${codeQuery.docs.length} documents');

      if (codeQuery.docs.isEmpty) {
        // Try alternative query without status filter
        print('Trying query without status filter...');
        final altQuery =
            await FirebaseFirestore.instance
                .collection('accessCodes')
                .where('code', isEqualTo: enteredCode)
                .get();

        print('Alternative query returned ${altQuery.docs.length} documents');

        if (altQuery.docs.isNotEmpty) {
          final doc = altQuery.docs.first;
          final data = doc.data();
          print('Found code but with different criteria:');
          print('- Code: ${data['code']}');
          print('- Status: ${data['status']}');
          print('- Used: ${data['used']}');

          // Check if it's actually valid but doesn't match our exact query
          if (data['used'] == true) {
            _showErrorDialog('This access code has already been used');
            return;
          } else if (data['status'] != 'valid') {
            _showErrorDialog(
              'This access code is not valid (status: ${data['status']})',
            );
            return;
          }
        }

        _showErrorDialog('Invalid or expired access code');
        return;
      }

      print('Access code verified successfully!');
      // Code is valid, mark it as verified
      setState(() {
        _accessCodeVerified = true;
        _verifiedAccessCode = enteredCode;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Access code verified! Please complete your registration.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error verifying access code: $e');
      _showErrorDialog('Error verifying access code. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2F2F2F),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Profile Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceButton(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      source: ImageSource.camera,
                    ),
                    _buildImageSourceButton(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      source: ImageSource.gallery,
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required ImageSource source,
  }) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        final pickedFile = await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxHeight: 800,
          maxWidth: 800,
        );

        if (pickedFile != null) {
          setState(() {
            _selfieImage = File(pickedFile.path);
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.blue, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.blue, size: 40),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Future<String> _uploadSelfie() async {
    if (_selfieImage == null) throw Exception('No image selected');

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('selfies')
          .child('$uid.jpg');

      // Create metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploaded-by': uid},
      );

      // Upload file with metadata
      final uploadTask = storageRef.putFile(_selfieImage!, metadata);

      // Wait for upload to complete and get the result
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      print('Upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_accessCodeVerified) {
      _showErrorDialog('Please verify your access code first');
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    if (_selfieImage == null) {
      _showErrorDialog('Please select a selfie photo');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      print('Starting image upload...');
      // Upload selfie to Firebase Storage
      final selfieUrl = await _uploadSelfie();
      print('Image uploaded successfully: $selfieUrl');

      // Prepare user data for gym system
      final userData = {
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'grade': _selectedGrade,
        'scholarType': _scholarType == 'Hostel' ? _hostelName : _scholarType,
        'studentNumber': _studentNumberController.text.trim(),
        'profileImageUrl': selfieUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      print('Saving to Firestore...');
      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      // Mark access code as used
      await _markAccessCodeAsUsed(uid);

      print('Registration completed successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Welcome to L4C Fitness!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Navigate to home after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        });
      }
    } catch (e) {
      print('Error in _submitForm: $e');
      if (mounted) {
        _showErrorDialog('Failed to complete registration: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAccessCodeAsUsed(String studentUID) async {
    try {
      // Find the access code document
      final codeQuery =
          await FirebaseFirestore.instance
              .collection('accessCodes')
              .where('code', isEqualTo: _verifiedAccessCode)
              .where('used', isEqualTo: false)
              .get();

      if (codeQuery.docs.isNotEmpty) {
        // Mark the first matching code as used
        await codeQuery.docs.first.reference.update({
          'used': true,
          'usedAt': FieldValue.serverTimestamp(),
          'usedBy': studentUID,
          'status': 'used',
        });
        print('Access code marked as used');
      }
    } catch (e) {
      print('Error marking access code as used: $e');
      // Don't throw error here, registration was successful
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF2F2F2F),
            title: const Text('Error', style: TextStyle(color: Colors.red)),
            content: Text(message, style: const TextStyle(color: Colors.white)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2F2F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F2F2F),
        elevation: 0,
        title: const Text(
          'L4C Fitness - Student Registration',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning message
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange, width: 1),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'These details will be saved permanently and cannot be changed later. Please ensure all info is correct before submitting.',
                          style: TextStyle(color: Colors.orange, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Access code section
                if (!_accessCodeVerified) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.security, color: Colors.blue, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Access Code Required',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Enter the 4-digit access code provided by gym staff to begin registration.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _accessCodeController,
                                maxLength: 4,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 8,
                                ),
                                decoration: InputDecoration(
                                  hintText: '• • • •',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 24,
                                    letterSpacing: 8,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[800],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _verifyAccessCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Text('Verify'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // Show registration form only after access code is verified
                if (_accessCodeVerified) ...[
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Access code verified! Please complete your registration below.',
                            style: TextStyle(color: Colors.green, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Selfie section
                  _buildSelfieSection(),
                  const SizedBox(height: 25),

                  // Name field
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Surname field
                  _buildTextField(
                    controller: _surnameController,
                    label: 'Surname',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Surname is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Grade dropdown
                  _buildGradeDropdown(),
                  const SizedBox(height: 20),

                  // Scholar type radio buttons
                  _buildScholarTypeSection(),
                  const SizedBox(height: 20),

                  // Hostel name field (conditional)
                  if (_scholarType == 'Hostel') ...[
                    _buildTextField(
                      controller: TextEditingController(text: _hostelName),
                      label: 'Hostel Name',
                      onChanged: (value) => _hostelName = value,
                      validator: (value) {
                        if (_scholarType == 'Hostel' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'Hostel name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Student number field
                  _buildTextField(
                    controller: _studentNumberController,
                    label: 'Student Number',
                    maxLength: 15,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Student number is required';
                      }
                      if (value.length > 15) {
                        return 'Student number must be 15 characters or less';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
                        return 'Student number must be alphanumeric';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text(
                                'Submit Registration',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ], // Close the if (_accessCodeVerified) condition
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelfieSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Photo *',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(75),
              border: Border.all(color: Colors.blue, width: 2),
            ),
            child:
                _selfieImage != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(73),
                      child: Image.file(_selfieImage!, fit: BoxFit.cover),
                    )
                    : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.blue, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Add Photo',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label *',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLength: maxLength,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            counterStyle: const TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Grade *',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGrade,
          style: const TextStyle(color: Colors.white),
          dropdownColor: Colors.grey[800],
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[800],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          items:
              ['8', '9', '10', '11', '12'].map((grade) {
                return DropdownMenuItem(
                  value: grade,
                  child: Text('Grade $grade'),
                );
              }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGrade = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildScholarTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Scholar Type *',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  'Day Scholar',
                  style: TextStyle(color: Colors.white),
                ),
                value: 'Day Scholar',
                groupValue: _scholarType,
                activeColor: Colors.blue,
                onChanged: (value) {
                  setState(() {
                    _scholarType = value!;
                    _hostelName = '';
                  });
                },
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text(
                  'Hostel',
                  style: TextStyle(color: Colors.white),
                ),
                value: 'Hostel',
                groupValue: _scholarType,
                activeColor: Colors.blue,
                onChanged: (value) {
                  setState(() {
                    _scholarType = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _studentNumberController.dispose();
    super.dispose();
  }
}
