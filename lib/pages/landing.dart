import 'package:flutter/material.dart';
import 'package:ticketing_system/pages/booking_page.dart';
import 'dart:async';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    // Trigger the animation shortly after the page is built
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _animate = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFF0A192F), // Darker, more modern navy blue
      body: Stack(
        children: [
          // Background Gradient decoration
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, 0.6),
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.4),
                    const Color(0xFF0A192F),
                  ],
                  radius: 1.0,
                ),
              ),
            ),
          ),
          // Main Content
          Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: screenHeight),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 80,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAnimatedHeader(isMobile),
                    SizedBox(height: isMobile ? 50 : 70),
                    _buildAnimatedInfoCard(isMobile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader(bool isMobile) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800),
      opacity: _animate ? 1.0 : 0.0,
      child: Column(
        children: [
          Container(
            width: isMobile ? 100 : 120,
            height: isMobile ? 100 : 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(77), width: 1),
            ),
            child: Image.asset('assets/logo.png'),
          ),
          const SizedBox(height: 30),
          Text(
            'AAVEG ORIENTATION',
            style: TextStyle(
              fontSize: isMobile ? 32 : 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 2,
              shadows: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.5),
                  blurRadius: 15,
                  spreadRadius: 5,
                )
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'NIT Agartala Auditorium',
            style: TextStyle(
              fontSize: isMobile ? 16 : 20,
              color: Colors.white.withAlpha(204),
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedInfoCard(bool isMobile) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeIn,
      opacity: _animate ? 1.0 : 0.0,
      child: Container(
        constraints: BoxConstraints(maxWidth: isMobile ? 400 : 550),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Text(
                    'Welcome, Freshers!',
                    style: TextStyle(
                      fontSize: isMobile ? 24 : 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Secure your seat for the upcoming orientation. Choose your preferred spot from our interactive map and get your QR ticket instantly.',
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
                      color: Colors.white.withAlpha(230),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFeature(Icons.app_registration_rounded, 'Open for All', isMobile),
                      _buildFeature(Icons.qr_code_2_rounded, 'Instant QR Ticket', isMobile),
                      _buildFeature(Icons.event_seat_rounded, 'Seat Selection', isMobile),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: isMobile ? 30 : 40),
            _buildCtaButton(context, isMobile),
            const SizedBox(height: 20),
            Text(
              'Booking closes 24 hours before the event.',
              style: TextStyle(
                fontSize: isMobile ? 12 : 14,
                color: Colors.white.withAlpha(179),
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtaButton(BuildContext context, bool isMobile) {
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 50 : 60,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const BookingPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: Colors.red.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          'BOOK YOUR SEAT NOW',
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String label, bool isMobile) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isMobile ? 24 : 30,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: Colors.white.withAlpha(230),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
