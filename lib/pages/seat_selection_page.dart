import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticketing_system/pages/ticket_page.dart';
import 'dart:ui'; // Required for BackdropFilter
import 'dart:async';

// A simple data model to represent a single seat from the database.
class Seat {
  final int id;
  final String seatNumber;
  final String status; // 'AVAILABLE' or 'BOOKED'

  Seat({required this.id, required this.seatNumber, required this.status});

  factory Seat.fromMap(Map<String, dynamic> map) {
    return Seat(
      id: map['id'],
      seatNumber: map['seat_number'],
      status: map['status'],
    );
  }
}

class SeatSelectionPage extends StatefulWidget {
  final String firstName;
  final String enrollmentNumber;

  const SeatSelectionPage({
    super.key,
    required this.firstName,
    required this.enrollmentNumber,
  });

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  late Future<List<Seat>> _seatsFuture;
  Seat? _selectedSeat;
  bool _isLoading = false;
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    _seatsFuture = _fetchSeats();
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _animate = true);
    });
  }

  Future<List<Seat>> _fetchSeats() async {
    try {
      final response = await Supabase.instance.client
          .from('seats')
          .select()
          .order('id', ascending: true);
      return response.map((map) => Seat.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to load seats. Please check your connection.');
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedSeat == null) {
      _showErrorSnackBar('Please select a seat first.');
      return;
    }
    
    setState(() { _isLoading = true; });

    try {
      final newStudentId = await Supabase.instance.client.rpc('book_seat', params: {
        'selected_seat_id': _selectedSeat!.id,
        'student_enrollment_number': widget.enrollmentNumber,
        'student_first_name': widget.firstName,
      });
        
      if (!mounted) return;

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => TicketPage(
          studentId: newStudentId as int,
          seatNumber: _selectedSeat!.seatNumber,
        ),
      ));

    } catch(e) {
      if (e is PostgrestException && e.message.contains('duplicate key value violates unique constraint')) {
         _showErrorSnackBar('This enrollment number has just been used. Please go back and try again.');
      } else {
        _showErrorSnackBar('Booking failed. The seat might have just been taken. Please select another.');
      }

      setState(() {
        _seatsFuture = _fetchSeats();
        _selectedSeat = null;
      });
    } finally {
       if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
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
                  center: const Alignment(0, -1),
                  colors: [
                    const Color(0xFF1E3A8A).withOpacity(0.6),
                    const Color(0xFF0A192F),
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: FutureBuilder<List<Seat>>(
                    future: _seatsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text(snapshot.error.toString(), style: const TextStyle(color: Colors.white)));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Auditorium map is not available.', style: TextStyle(color: Colors.white)));
                      }

                      final allSeats = snapshot.data!;
                      final rows = <String, List<Seat>>{};
                      for (var seat in allSeats) {
                        final rowChar = seat.seatNumber[0];
                        rows.putIfAbsent(rowChar, () => []).add(seat);
                      }

                      return Column(
                        children: [
                          _buildScreen(),
                          const SizedBox(height: 16),
                          _buildLegend(),
                          const SizedBox(height: 16),
                          Expanded(child: _buildSeatMap(rows)),
                        ],
                      );
                    },
                  ),
                ),
                _buildBookingSummary(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          const Text('Select Your Seat', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  
  Widget _buildScreen() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _animate ? 1.0 : 0.0,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 20),
        width: 300,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 500),
      opacity: _animate ? 1.0 : 0.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(Colors.white, 'Available'),
          _buildLegendItem(const Color(0xFFEF4444), 'Selected'),
          _buildLegendItem(Colors.grey.shade700, 'Booked'),
          _buildLegendItem(Colors.blueGrey.shade800, 'Reserved'),
        ],
      ),
    );
  }
  
  Widget _buildSeatMap(Map<String, List<Seat>> rows) {
    // ---- RESPONSIVENESS FIX ----
    // InteractiveViewer allows pinch-to-zoom and pan, perfect for small screens.
    return InteractiveViewer(
      panEnabled: true,
      minScale: 0.8,
      maxScale: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _animate ? 1.0 : 0.0,
          child: Column(
            children: [
              _buildReservedRow('A', 4, 10, 4),
              _buildReservedRow('B', 4, 10, 4),
              _buildReservedRow('C', 4, 10, 4),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(color: Colors.white24),
              ),
              ...rows.entries.map((entry) {
                return _buildAuditoriumRow(entry.key, entry.value);
              }).toList(),
               const SizedBox(height: 20),
               Text(
                'Note: Upper level seats (Rows R to V) are not available for booking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 15,
          height: 15,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _buildAuditoriumRow(String rowChar, List<Seat> seats) {
    final leftWing = seats.where((s) => int.parse(s.seatNumber.substring(1)) <= 6).toList();
    final middleWing = seats.where((s) => int.parse(s.seatNumber.substring(1)) > 6 && int.parse(s.seatNumber.substring(1)) <= 18).toList();
    final rightWing = seats.where((s) => int.parse(s.seatNumber.substring(1)) > 18).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 20, child: Text(rowChar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Row(children: leftWing.map((seat) => _buildSeatIcon(seat)).toList()),
          const SizedBox(width: 24), // Aisle
          Row(children: middleWing.map((seat) => _buildSeatIcon(seat)).toList()),
          const SizedBox(width: 24), // Aisle
          Row(children: rightWing.map((seat) => _buildSeatIcon(seat)).toList()),
        ],
      ),
    );
  }

  Widget _buildReservedRow(String rowChar, int left, int middle, int right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           SizedBox(width: 20, child: Text(rowChar, style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Row(children: List.generate(left, (index) => _buildSeatIcon(null, isReserved: true))),
          const SizedBox(width: 24), // Aisle
          Row(children: List.generate(middle, (index) => _buildSeatIcon(null, isReserved: true))),
          const SizedBox(width: 24), // Aisle
          Row(children: List.generate(right, (index) => _buildSeatIcon(null, isReserved: true))),
        ],
      ),
    );
  }

  Widget _buildSeatIcon(Seat? seat, {bool isReserved = false}) {
    final isSelected = !isReserved && _selectedSeat?.id == seat!.id;
    final isBooked = !isReserved && seat!.status == 'BOOKED';

    Color color;
    if (isReserved) {
      color = Colors.blueGrey.shade800;
    } else if (isBooked) {
      color = Colors.grey.shade700;
    } else if (isSelected) {
      color = const Color(0xFFEF4444);
    } else {
      color = Colors.white;
    }
    
    final textColor = (isSelected || isBooked || isReserved) ? Colors.white : Colors.black;
    
    return GestureDetector(
      onTap: (isBooked || isReserved) ? null : () {
        setState(() {
          _selectedSeat = seat;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
          border: isSelected ? Border.all(color: Colors.amber, width: 2) : null,
        ),
        child: isReserved ? null : Center(
          child: Text(
            seat!.seatNumber.substring(1),
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2)))
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedSeat == null ? 'Select a seat' : 'Selected: ${_selectedSeat!.seatNumber}',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: (_selectedSeat == null || _isLoading) ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 8,
                  shadowColor: Colors.red.withOpacity(0.5)
                ),
                child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('CONFIRM'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
