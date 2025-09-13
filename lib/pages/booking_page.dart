import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticketing_system/pages/seat_selection_page.dart';
import 'package:ticketing_system/pages/ticket_page.dart';
import 'dart:async';

// --- Enhanced Database Logic for Open Registration ---

enum EnrollmentStatus { taken, notTaken, nameMismatch }

/// A result class to hold the status and existing ticket details if found.
class EnrollmentCheckResult {
  final EnrollmentStatus status;
  final int? studentId;
  final String? seatNumber;

  EnrollmentCheckResult(this.status, {this.studentId, this.seatNumber});
}

class DatabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Checks enrollment status and verifies name if a booking exists.
  Future<EnrollmentCheckResult> checkEnrollmentStatus({
    required String enrollmentNumber,
    required String firstName,
  }) async {
    try {
      // Find the student record based on the unique enrollment number.
      final studentResponse = await _client
          .from('students')
          .select('id, first_name') // Select name for verification
          .eq('enrollment_number', enrollmentNumber)
          .maybeSingle();

      if (studentResponse == null) {
        return EnrollmentCheckResult(EnrollmentStatus.notTaken);
      }

      // --- NEW VALIDATION STEP ---
      // Student exists, now verify the name matches the existing booking.
      final existingFirstName = studentResponse['first_name'] as String;
      if (existingFirstName != firstName) {
        return EnrollmentCheckResult(EnrollmentStatus.nameMismatch);
      }

      // If names match, fetch their seat number for the redirect.
      final studentId = studentResponse['id'] as int;
      final seatResponse = await _client
          .from('seats')
          .select('seat_number')
          .eq('booked_by_student_id', studentId)
          .single();
      
      final seatNumber = seatResponse['seat_number'] as String;
      
      return EnrollmentCheckResult(
        EnrollmentStatus.taken,
        studentId: studentId,
        seatNumber: seatNumber,
      );

    } catch (e) {
      debugPrint('Database error during enrollment check: $e');
      throw 'Database error: Could not verify enrollment number.';
    }
  }
}

// --- Custom Input Formatter ---
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

// --- Booking Page Widget ---

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _enrollmentController = TextEditingController();
  bool _isLoading = false;
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  Future<void> _validateAndProceed() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() { _isLoading = true; });

    try {
      final fullName = _nameController.text.trim();
      final firstName = fullName.split(' ')[0].toUpperCase();
      final enrollmentNumber = _enrollmentController.text.trim().toUpperCase();

      final result = await _dbService.checkEnrollmentStatus(
        enrollmentNumber: enrollmentNumber,
        firstName: firstName, // Pass the name for validation
      );

      if (!mounted) return;

      // Use a switch statement to handle all possible outcomes cleanly.
      switch (result.status) {
        case EnrollmentStatus.taken:
          _handleRedirectToTicket(result.studentId!, result.seatNumber!);
          break;
        case EnrollmentStatus.notTaken:
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => SeatSelectionPage(
              firstName: firstName,
              enrollmentNumber: enrollmentNumber,
            ),
          ));
          break;
        case EnrollmentStatus.nameMismatch:
          throw 'This enrollment number is already booked, but the name does not match.';
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _handleRedirectToTicket(int studentId, String seatNumber) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You have already booked a ticket. Redirecting...'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 1),
      ),
    );
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TicketPage(studentId: studentId, seatNumber: seatNumber),
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _enrollmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -0.6),
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.5),
                    const Color(0xFF0A192F),
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedForm(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedForm() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: _animate ? 1.0 : 0.0,
      child: Column(
        children: [
          Image.asset('assets/logo.png', height: 80),
          const SizedBox(height: 20),
          const Text(
            'Enter Your Details',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildTextFormField(
            controller: _nameController,
            labelText: 'First Name',
            icon: Icons.person,
            validator: (value) => value!.trim().isEmpty ? 'Please enter your name' : null,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextFormField(
            controller: _enrollmentController,
            labelText: 'Enrollment Number',
            icon: Icons.confirmation_number,
            validator: (value) => value!.trim().isEmpty ? 'Please enter your enrollment number' : null,
            inputFormatters: [
              UpperCaseTextFormatter(),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _validateAndProceed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: Colors.red.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'VERIFY & PROCEED',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      inputFormatters: inputFormatters,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white.withAlpha(150)),
        prefixIcon: Icon(icon, color: Colors.white.withAlpha(150)),
        filled: true,
        fillColor: Colors.blue.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}

