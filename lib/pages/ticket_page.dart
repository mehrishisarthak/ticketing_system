import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui'; // Required for BackdropFilter
import 'dart:async';

import 'package:ticketing_system/pages/ticket_service.dart';

class TicketPage extends StatefulWidget {
  final int studentId;
  final String seatNumber;

  const TicketPage({
    super.key,
    required this.studentId,
    required this.seatNumber,
  });

  @override
  State<TicketPage> createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  late final Future<Map<String, dynamic>> _studentDataFuture;
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    _studentDataFuture = _fetchStudentData();
    // Trigger the animation shortly after the page is built
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  Future<Map<String, dynamic>> _fetchStudentData() async {
    try {
      final response = await Supabase.instance.client
          .from('students')
          .select('first_name, enrollment_number, ticket_id')
          .eq('id', widget.studentId)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching ticket details: $e');
      throw Exception('Failed to load your ticket details.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A192F),
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 0),
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.6),
                    const Color(0xFF0A192F),
                  ],
                  radius: 1.0,
                ),
              ),
            ),
          ),
          // Main Content
          Center(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _studentDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator(color: Colors.white);
                }
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                }
                if (!snapshot.hasData || snapshot.data!['ticket_id'] == null) {
                  return const Text('Could not generate ticket data.', style: TextStyle(color: Colors.white));
                }

                final data = snapshot.data!;
                final studentName = data['first_name'];
                final enrollmentNumber = data['enrollment_number'];
                final ticketId = data['ticket_id'];

                // --- RESPONSIVENESS FIX ---
                // SingleChildScrollView allows the content to scroll on smaller screens.
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAnimatedContent(context, studentName, enrollmentNumber, ticketId),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedContent(BuildContext context, String studentName, String enrollmentNumber, String ticketId) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 600),
      opacity: _animate ? 1.0 : 0.0,
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 20),
          Text(
            'Booking Successful!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your seat has been confirmed.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 40),
          _buildTicketInfoCard(studentName, enrollmentNumber),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download Ticket (PDF)'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: Colors.red.withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () async {
              final pdfData = await PdfService.generateTicket(
                studentName: studentName,
                enrollmentNumber: enrollmentNumber,
                seatNumber: widget.seatNumber,
                ticketId: ticketId,
              );
              await Printing.sharePdf(bytes: pdfData, filename: 'AAVEG-Orientation-Ticket.pdf');
            },
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Back to Home', style: TextStyle(color: Colors.white70)),
          )
        ],
      ),
    );
  }

  Widget _buildTicketInfoCard(String name, String enrollment) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(enrollment, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
              const Divider(color: Colors.white24, height: 30),
              Text(
                'SEAT: ${widget.seatNumber}',
                style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

