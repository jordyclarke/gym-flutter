import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'screens/register.dart';
import 'screens/home.dart';
import 'screens/qr_code.dart';
import 'screens/book.dart';
import 'screens/workouts.dart';
import 'screens/details.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'L4C Fitness - Gym Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthWrapper(),
      routes: {
        '/auth': (context) => const AuthTestScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/qr': (context) => const QRCodeScreen(),
        '/book': (context) => const BookScreen(),
        '/workouts': (context) => const WorkoutsScreen(),
        '/details': (context) => const DetailsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  late StreamSubscription<User?> _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  void _setupAuthListener() {
    // Listen to auth state changes
    _authStateSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (mounted) {
        _handleAuthStateChange(user);
      }
    });
  }

  Future<void> _handleAuthStateChange(User? user) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // If no user is signed in, sign in anonymously
      if (user == null) {
        print('No user signed in, signing in anonymously...');
        final userCredential = await FirebaseAuth.instance.signInAnonymously();
        user = userCredential.user;
        print('Anonymous sign-in successful: ${user?.uid}');
      }

      if (user != null) {
        // Check if user has a profile in Firestore
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        // Add a small delay before navigation
        await Future.delayed(const Duration(milliseconds: 300));

        if (doc.exists && doc.data() != null) {
          // User is registered, navigate to home
          print('User profile found, navigating to home');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          // User is authenticated but not registered, navigate to registration
          print('No user profile found, navigating to registration');
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/register');
          }
        }
      } else {
        // This should not happen, but handle error case
        throw Exception('Failed to authenticate user');
      }
    } catch (e) {
      print('Error handling auth state change: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message and navigate to registration as fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to registration as fallback
        Navigator.pushReplacementNamed(context, '/register');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF2F2F2F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00BFFF), Color(0xFF0080FF)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00BFFF).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Checking registration...',
                style: TextStyle(
                  color: Color(0xFF00BFFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please wait while we set up your experience',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // This should never be reached as we navigate away, but just in case
    return const Scaffold(
      backgroundColor: Color(0xFF2F2F2F),
      body: Center(child: CircularProgressIndicator(color: Color(0xFF00BFFF))),
    );
  }
}

class AuthTestScreen extends StatefulWidget {
  const AuthTestScreen({super.key});

  @override
  State<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends State<AuthTestScreen> {
  String _status = 'Not signed in';
  bool _isLoading = false;

  Future<void> _signInAnonymously() async {
    setState(() {
      _isLoading = true;
      _status = 'Signing in...';
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInAnonymously();
      setState(() {
        _status = 'Signed in! User ID: ${userCredential.user?.uid}';
        _isLoading = false;
      });
      print("Signed in!");
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
      print("Error: $e");
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _status = 'Signing out...';
    });

    try {
      await FirebaseAuth.instance.signOut();
      setState(() {
        _status = 'Signed out successfully';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error signing out: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Firebase Auth Demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _signInAnonymously,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Sign in anonymously'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Sign out'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('Go to Registration'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
