import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// --- 1. SYSTEM INITIALIZATION ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Cloud Connection using your provided credentials
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBx5jCqrrVapntJ_efmxTu-OVKyjz4JPKs",
      appId: "1:529342212984:web:16d29212ddace39bfe368d",
      messagingSenderId: "529342212984",
      projectId: "studentanalytics-b0a5f",
    ),
  );

  runApp(const EngageIQApp());
}

// --- 2. DATA ARCHITECTURE ---
class Student {
  String id;
  String name;
  Map<String, double> scores;
  String docId;

  Student({
    required this.id,
    required this.name,
    required this.scores,
    this.docId = '',
  });

  factory Student.empty(String id, String name) {
    return Student(
      id: id,
      name: name,
      scores: {
        'Attendance': 0,
        'Assessments Attended': 0,
        'Quiz Scores': 0,
        'Internal Marks': 0,
        'Doubts Clarification': 0,
        'Poll Response Rate': 0,
        'Questions Answered': 0,
      },
    );
  }

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'scores': scores,
  };

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Student(
      docId: doc.id,
      id: data['id'],
      name: data['name'],
      scores: Map<String, double>.from(
        data['scores'].map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
    );
  }
}

class FirestoreService {
  final CollectionReference _studentsCollection = FirebaseFirestore.instance
      .collection('students');

  Future<void> saveStudent(Student student) async {
    if (student.docId.isEmpty) {
      DocumentReference docRef = await _studentsCollection.add(
        student.toFirestore(),
      );
      student.docId = docRef.id;
    } else {
      await _studentsCollection
          .doc(student.docId)
          .update(student.toFirestore());
    }
  }

  Future<void> deleteStudent(String docId) async {
    await _studentsCollection.doc(docId).delete();
  }

  Stream<List<Student>> getStudentsStream() {
    return _studentsCollection.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
    );
  }

  Stream<Student?> getSingleStudentStream(String rollNumber) {
    return _studentsCollection
        .where('id', isEqualTo: rollNumber)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Student.fromFirestore(snapshot.docs.first);
        });
  }
}

// --- 3. ANALYTICS ENGINE ---
final Map<String, double> coreWeights = {
  'Attendance': 0.15,
  'Assessments Attended': 0.10,
  'Quiz Scores': 0.20,
  'Internal Marks': 0.20,
  'Doubts Clarification': 0.10,
  'Poll Response Rate': 0.10,
  'Questions Answered': 0.15,
};

double calculateWPI(Map<String, double> scores) {
  double total = 0;
  scores.forEach((key, value) {
    total += value * coreWeights[key]!;
  });
  return total;
}

Map<String, dynamic> getClassification(double score) {
  if (score >= 85)
    return {"label": "Highly Engaged", "color": Colors.greenAccent};
  if (score >= 70) return {"label": "Active", "color": Colors.blueAccent};
  if (score >= 55) return {"label": "Moderate", "color": Colors.amberAccent};
  if (score >= 40) return {"label": "Low", "color": Colors.orangeAccent};
  return {"label": "Disengaged", "color": Colors.redAccent};
}

class ModernBackground extends StatelessWidget {
  final Widget child;
  const ModernBackground({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF020617), Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: child,
    );
  }
}

class ModernScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final Widget? trailing;
  const ModernScaffold({
    super.key,
    required this.body,
    this.title = '',
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white70,
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
    );
  }
}

// Interactive card that supports hover and tap animations (works on web & desktop)
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const InteractiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final scale = _hover ? 1.02 : 1.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()..scale(scale, scale),
          padding: widget.padding,
          decoration: BoxDecoration(
            gradient: _hover
                ? LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.02),
                      Colors.white.withOpacity(0.03),
                    ],
                  )
                : null,
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// Animated circular progress ring with percentage tween
class AnimatedProgressRing extends StatelessWidget {
  final double value; // 0..100
  final Color color;
  final double size;
  const AnimatedProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: value / 100),
      duration: const Duration(milliseconds: 900),
      builder: (context, animatedValue, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: animatedValue,
                  strokeWidth: 12,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  backgroundColor: Colors.white10,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(animatedValue * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'WPI',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- 4. MAIN APP ---
class EngageIQApp extends StatelessWidget {
  const EngageIQApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EngageIQ',
      navigatorKey: navigatorKey,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF22D3EE),
          secondary: Color(0xFF7C3AED),
          background: Color(0xFF071027),
          surface: Color(0xFF0F172A),
        ),
        primaryColor: const Color(0xFF22D3EE),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          ThemeData.dark().textTheme,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white10,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.white54),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF22D3EE),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
        // cardTheme omitted to maintain compatibility across Flutter versions
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- 5. LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isTeacherLogin = true;
  bool _isLoading = false;
  String _error = '';
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();

  void _handleLogin() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      if (isTeacherLogin) {
        if (_user.text == 'admin' && _pass.text == 'admin123') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherDashboard()),
          );
        } else {
          setState(() => _error = 'Invalid faculty credentials.');
        }
      } else {
        String roll = _user.text.trim();
        if (_pass.text != 'student123') {
          setState(() => _error = 'Invalid password.');
          return;
        }
        var snap = await FirebaseFirestore.instance
            .collection('students')
            .where('id', isEqualTo: roll)
            .get();
        if (snap.docs.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentViewDashboard(rollNumber: roll),
            ),
          );
        } else {
          setState(() => _error = 'Roll number not found.');
        }
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 450),
            width: 460,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22D3EE).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 36,
                        color: Color(0xFF22D3EE),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EngageIQ',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Student Insight Portal',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const SizedBox(height: 48),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Faculty')),
                        selected: isTeacherLogin,
                        onSelected: (v) =>
                            setState(() => isTeacherLogin = true),
                        selectedColor: const Color(
                          0xFF22D3EE,
                        ).withOpacity(0.22),
                        backgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Student')),
                        selected: !isTeacherLogin,
                        onSelected: (v) =>
                            setState(() => isTeacherLogin = false),
                        selectedColor: const Color(
                          0xFF22D3EE,
                        ).withOpacity(0.22),
                        backgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _user,
                  decoration: InputDecoration(
                    labelText: isTeacherLogin ? 'Faculty ID' : 'Roll Number',
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      color: Colors.white54,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 32),
                if (_error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'AUTHENTICATE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 6. STUDENT DASHBOARD ---
class StudentViewDashboard extends StatelessWidget {
  final String rollNumber;
  final FirestoreService _dbService = FirestoreService();
  StudentViewDashboard({super.key, required this.rollNumber});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: StreamBuilder<Student?>(
          stream: _dbService.getSingleStudentStream(rollNumber),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data == null)
              return const Center(
                child: Text(
                  'Student data not found.',
                  style: TextStyle(color: Colors.white54),
                ),
              );
            final student = snapshot.data!;
            double wpi = calculateWPI(student.scores);
            var status = getClassification(wpi);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STUDENT INSIGHT PORTAL',
                        style: GoogleFonts.spaceGrotesk(
                          letterSpacing: 2,
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white54),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${student.name}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          student.id,
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricRing(context, wpi, status),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: _buildBarChart(student.scores),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        _buildBottomAnalytics(student.scores),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricRing(BuildContext context, double wpi, Map status) {
    return InteractiveCard(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.black87,
            content: Text(
              'WPI: ${wpi.toStringAsFixed(1)} - ${status["label"]}',
            ),
          ),
        );
      },
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          AnimatedProgressRing(value: wpi, color: status["color"]),
          const SizedBox(height: 18),
          Text(
            status["label"].toUpperCase(),
            style: TextStyle(
              color: status["color"],
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap for details',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // FIXED: ADDED PARAMETER WORDINGS BELOW THE GRAPH
  Widget _buildBarChart(Map scores) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)}%',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const titles = [
                    'Att',
                    'Asses',
                    'Quiz',
                    'Marks',
                    'Doubts',
                    'Poll',
                    'Ans',
                  ];
                  if (value.toInt() >= 0 && value.toInt() < titles.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        titles[value.toInt()],
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            scores.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: scores.values.elementAt(i),
                  color: const Color(0xFF22D3EE),
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
              showingTooltipIndicators: [0],
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  Widget _buildBottomAnalytics(Map scores) {
    return Row(
      children: [
        Expanded(
          child: InteractiveCard(
            padding: const EdgeInsets.all(20),
            child: const Column(
              children: [
                Icon(Icons.auto_awesome, color: Colors.cyanAccent),
                SizedBox(height: 12),
                Text(
                  'AI GROWTH INSIGHT',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                ),
                SizedBox(height: 8),
                Text(
                  'Maintain consistent attendance to ensure WPI stability.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: InteractiveCard(
            padding: const EdgeInsets.all(20),
            child: const Column(
              children: [
                Icon(Icons.trending_up, color: Colors.greenAccent),
                SizedBox(height: 12),
                Text(
                  'PERFORMANCE TREND',
                  style: TextStyle(fontSize: 10, letterSpacing: 1.5),
                ),
                SizedBox(height: 8),
                Text(
                  'Your interactive engagement is currently increasing.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- 7. TEACHER DASHBOARD ---
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final FirestoreService _dbService = FirestoreService();
  Student? _selectedStudent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ModernBackground(
        child: StreamBuilder<List<Student>>(
          stream: _dbService.getStudentsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            final students = snapshot.data ?? [];

            double avg = students.isEmpty
                ? 0
                : students
                          .map((s) => calculateWPI(s.scores))
                          .reduce((a, b) => a + b) /
                      students.length;
            int risk = students
                .where((s) => calculateWPI(s.scores) < 40)
                .length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'FACULTY COMMAND CENTER',
                        style: GoogleFonts.spaceGrotesk(
                          letterSpacing: 2,
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.white54),
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 360,
                        child: InteractiveCard(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    _buildStatTile(
                                      'Class Average WPI',
                                      '${avg.toStringAsFixed(1)}%',
                                      Colors.cyanAccent,
                                    ),
                                    const SizedBox(height: 12),
                                    _buildStatTile(
                                      'At-Risk Students',
                                      '$risk',
                                      Colors.orangeAccent,
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      height: 120,
                                      child: _buildDistributionChart(students),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'CLASS DISTRIBUTION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        letterSpacing: 2,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(color: Colors.white10, height: 1),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: students.length,
                                  itemBuilder: (context, index) {
                                    final s = students[index];
                                    double sWpi = calculateWPI(s.scores);
                                    bool isSel =
                                        _selectedStudent?.docId == s.docId;
                                    String initials = s.name.isNotEmpty
                                        ? s.name
                                              .trim()
                                              .split(' ')
                                              .map(
                                                (p) => p.isNotEmpty ? p[0] : '',
                                              )
                                              .take(2)
                                              .join()
                                        : '?';
                                    return ListTile(
                                      selected: isSel,
                                      selectedTileColor: Colors.white
                                          .withOpacity(0.04),
                                      onTap: () =>
                                          setState(() => _selectedStudent = s),
                                      leading: CircleAvatar(
                                        backgroundColor: getClassification(
                                          sWpi,
                                        )["color"].withOpacity(0.15),
                                        child: Text(
                                          initials.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        s.name,
                                        style: TextStyle(
                                          fontWeight: isSel
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      subtitle: Text(
                                        s.id,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white38,
                                        ),
                                      ),
                                      trailing: Text(
                                        '${sWpi.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          color: getClassification(
                                            sWpi,
                                          )["color"],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _addStudent(context),
                                    child: const Text('Add New Student'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: _selectedStudent == null
                            ? const Center(
                                child: Text(
                                  'Select a student record to begin normalization.',
                                ),
                              )
                            : ListView(
                                padding: const EdgeInsets.all(48),
                                children: [
                                  Text(
                                    'Metric Normalization: ${_selectedStudent!.name}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 40),
                                  ..._selectedStudent!.scores.keys
                                      .map(
                                        (k) => InteractiveCard(
                                          padding: const EdgeInsets.all(18),
                                          child: Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(k),
                                                  Text(
                                                    '${_selectedStudent!.scores[k]!.toInt()}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.cyanAccent,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Slider(
                                                value: _selectedStudent!
                                                    .scores[k]!,
                                                min: 0,
                                                max: 100,
                                                divisions: 100,
                                                onChangeEnd: (v) =>
                                                    _dbService.saveStudent(
                                                      _selectedStudent!,
                                                    ),
                                                onChanged: (v) => setState(
                                                  () =>
                                                      _selectedStudent!
                                                              .scores[k] =
                                                          v,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(List<Student> students) {
    if (students.isEmpty) return PieChart(PieChartData(sections: []));
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 30,
        sections: [
          PieChartSectionData(
            value: students
                .where((s) => calculateWPI(s.scores) >= 70)
                .length
                .toDouble(),
            color: Colors.cyanAccent,
            radius: 20,
            showTitle: false,
          ),
          PieChartSectionData(
            value: students
                .where((s) => calculateWPI(s.scores) < 40)
                .length
                .toDouble(),
            color: Colors.orangeAccent,
            radius: 20,
            showTitle: false,
          ),
          PieChartSectionData(
            value: students
                .where(
                  (s) =>
                      calculateWPI(s.scores) >= 40 &&
                      calculateWPI(s.scores) < 70,
                )
                .length
                .toDouble(),
            color: Colors.white10,
            radius: 20,
            showTitle: false,
          ),
        ],
      ),
    );
  }

  void _addStudent(BuildContext context) {
    TextEditingController n = TextEditingController();
    TextEditingController i = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Register Student'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: n,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: i,
              decoration: const InputDecoration(labelText: 'Roll No'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _dbService.saveStudent(Student.empty(i.text, n.text));
              Navigator.pop(c);
            },
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }
}
