import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WorkoutsScreen extends StatefulWidget {
  const WorkoutsScreen({super.key});

  @override
  State<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends State<WorkoutsScreen> {
  String? _selectedGender;
  String? _selectedDay;
  Map<String, dynamic>? _workoutData;
  bool _isLoading = false;

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  Future<void> _fetchWorkout() async {
    if (_selectedGender == null || _selectedDay == null) return;

    setState(() {
      _isLoading = true;
      _workoutData = null;
    });

    try {
      print(
        'Fetching workout for: ${_selectedGender!.toLowerCase()} - ${_selectedDay!.toLowerCase()}',
      );

      // Method 1: Try flat structure - workouts/{gender-day}
      final flatDocId =
          '${_selectedGender!.toLowerCase()}-${_selectedDay!.toLowerCase()}';
      print('Trying flat structure: workouts/$flatDocId');

      final flatDocRef = FirebaseFirestore.instance
          .collection('workouts')
          .doc(flatDocId);

      final flatSnapshot = await flatDocRef.get();

      if (flatSnapshot.exists) {
        print('Found workout in flat structure!');
        setState(() {
          _workoutData = flatSnapshot.data() as Map<String, dynamic>;
        });
        return;
      }

      // Method 2: Try query approach - search for documents with matching fields
      print('Trying query approach...');
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('workouts')
              .where('gender', isEqualTo: _selectedGender!.toLowerCase())
              .where('day', isEqualTo: _selectedDay!.toLowerCase())
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('Found workout via query!');
        setState(() {
          _workoutData = querySnapshot.docs.first.data();
        });
        return;
      }

      // Method 3: Try nested subcollection approach
      print(
        'Trying nested structure: workouts/${_selectedGender!.toLowerCase()}/days/${_selectedDay!.toLowerCase()}',
      );
      final nestedDocRef = FirebaseFirestore.instance
          .collection('workouts')
          .doc(_selectedGender!.toLowerCase())
          .collection('days')
          .doc(_selectedDay!.toLowerCase());

      final nestedSnapshot = await nestedDocRef.get();

      if (nestedSnapshot.exists) {
        print('Found workout in nested structure!');
        setState(() {
          _workoutData = nestedSnapshot.data() as Map<String, dynamic>;
        });
        return;
      }

      // Method 4: List all documents to debug
      print('Listing all workout documents...');
      final allDocs =
          await FirebaseFirestore.instance.collection('workouts').get();
      print('Found ${allDocs.docs.length} workout documents:');
      for (var doc in allDocs.docs) {
        print('- Document ID: ${doc.id}');
        final data = doc.data();
        print('- Document data keys: ${data.keys.toList()}');
        if (data.containsKey('gender')) print('  - gender: ${data['gender']}');
        if (data.containsKey('day')) print('  - day: ${data['day']}');
        if (data.containsKey('title')) print('  - title: ${data['title']}');
      }

      // No workout found
      print('No workout found for ${_selectedGender} - ${_selectedDay}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No workout plan found for ${_selectedGender} - ${_selectedDay}',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      print('Error fetching workout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading workout plan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Gender',
          style: TextStyle(
            color: Color(0xFF00BFFF),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Ladies';
                    _workoutData = null; // Reset workout data
                  });
                  if (_selectedDay != null) _fetchWorkout();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color:
                        _selectedGender == 'Ladies'
                            ? const Color(0xFF00BFFF)
                            : Colors.grey[800],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF00BFFF),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.woman,
                        size: 40,
                        color:
                            _selectedGender == 'Ladies'
                                ? Colors.white
                                : const Color(0xFF00BFFF),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ladies',
                        style: TextStyle(
                          color:
                              _selectedGender == 'Ladies'
                                  ? Colors.white
                                  : const Color(0xFF00BFFF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Men';
                    _workoutData = null; // Reset workout data
                  });
                  if (_selectedDay != null) _fetchWorkout();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color:
                        _selectedGender == 'Men'
                            ? const Color(0xFF00BFFF)
                            : Colors.grey[800],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF00BFFF),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.man,
                        size: 40,
                        color:
                            _selectedGender == 'Men'
                                ? Colors.white
                                : const Color(0xFF00BFFF),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Men',
                        style: TextStyle(
                          color:
                              _selectedGender == 'Men'
                                  ? Colors.white
                                  : const Color(0xFF00BFFF),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 10),
        Center(
          child: Text(
            'Select Day',
            style: TextStyle(
              color: Color(0xFF00BFFF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
              _days.map((day) {
                final isSelected = _selectedDay == day;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                        _workoutData = null; // Reset workout data
                      });
                      if (_selectedGender != null) _fetchWorkout();
                    },
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? const Color(0xFF00BFFF)
                                : Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF00BFFF),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            color:
                                isSelected
                                    ? Colors.white
                                    : const Color(0xFF00BFFF),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildWorkoutDisplay() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
      );
    }

    if (_workoutData == null) {
      if (_selectedGender != null && _selectedDay != null) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange),
          ),
          child: const Column(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 40),
              SizedBox(height: 10),
              Text(
                'No workout plan available',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Please contact gym staff to add workout plans',
                style: TextStyle(color: Colors.orange, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      return const SizedBox();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF00BFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _selectedGender == 'Ladies' ? Icons.woman : Icons.man,
                color: const Color(0xFF00BFFF),
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                '$_selectedGender - $_selectedDay Workout',
                style: const TextStyle(
                  color: Color(0xFF00BFFF),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_workoutData!['title'] != null) ...[
            Text(
              _workoutData!['title'],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
          ],

          if (_workoutData!['description'] != null) ...[
            Text(
              _workoutData!['description'],
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
          ],

          if (_workoutData!['exercises'] != null) ...[
            const Text(
              'Exercises:',
              style: TextStyle(
                color: Color(0xFF00BFFF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ...(_workoutData!['exercises'] as List).asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final exercise = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00BFFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00BFFF).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00BFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise['name'] ?? 'Exercise ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (exercise['sets'] != null ||
                              exercise['reps'] != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                if (exercise['sets'] != null) ...[
                                  Text(
                                    'Sets: ',
                                    style: const TextStyle(
                                      color: Color(0xFF00BFFF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${exercise['sets']}',
                                    style: const TextStyle(
                                      color: Color(0xFF00BFFF),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (exercise['reps'] != null) ...[
                                  Text(
                                    'Reps: ',
                                    style: const TextStyle(
                                      color: Color(0xFF00BFFF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${exercise['reps']}',
                                    style: const TextStyle(
                                      color: Color(0xFF00BFFF),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                          if (exercise['description'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              exercise['description'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],

          if (_workoutData!['notes'] != null) ...[
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notes:',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _workoutData!['notes'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showWorkoutOnly =
        _selectedGender != null && _selectedDay != null && _workoutData != null;
    return Scaffold(
      backgroundColor: const Color(0xFF2F2F2F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F2F2F),
        elevation: 0,
        title: const Text(
          'Workout Plans',
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
        child:
            showWorkoutOnly
                ? _buildWorkoutDisplay()
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select your gender and day to view workout plans',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    _buildGenderSelector(),
                    const SizedBox(height: 30),
                    if (_selectedGender != null) ...[
                      _buildDaySelector(),
                      const SizedBox(height: 30),
                    ],
                    if (_selectedGender != null && _selectedDay != null) ...[
                      _buildWorkoutDisplay(),
                    ],
                  ],
                ),
      ),
    );
  }
}
