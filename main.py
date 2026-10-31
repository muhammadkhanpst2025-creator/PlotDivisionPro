import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const PlotDivisionApp());
}

class PlotDivisionApp extends StatelessWidget {
  const PlotDivisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plot Division Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String selectedShape = 'Quadrilateral';
  String selectedUnit = 'Meters';
  String selectedDirection = 'Vertical';

  final TextEditingController sideAController = TextEditingController(text: '35');
  final TextEditingController sideBController = TextEditingController(text: '40');
  final TextEditingController sideCController = TextEditingController(text: '55');
  final TextEditingController sideDController = TextEditingController(text: '60');
  final TextEditingController sideEController = TextEditingController();
  final TextEditingController diagACController = TextEditingController();
  final TextEditingController diagADController = TextEditingController();
  final TextEditingController divisionPercentagesController = TextEditingController(text: '50,50');

  List<Offset> calculatedPoints = [];
  double totalAreaSqFt = 0.0;
  List<double> portionAreas = [];
  bool isCalculated = false;

  void calculatePlot() {
    try {
      double a = double.tryParse(sideAController.text) ?? 0;
      double b = double.tryParse(sideBController.text) ?? 0;
      double c = double.tryParse(sideCController.text) ?? 0;
      double d = double.tryParse(sideDController.text) ?? 0;

      if (a <= 0 || b <= 0 || c <= 0) {
        throw Exception("Please enter valid side dimensions.");
      }

      // Simple shape point layout simulation for AutoCAD draft preview
      List<Offset> pts = [];
      if (selectedShape == 'Triangle') {
        pts = [const Offset(50, 200), const Offset(200, 200), const Offset(120, 50)];
      } else if (selectedShape == 'Quadrilateral') {
        pts = [const Offset(40, 200), const Offset(250, 180), const Offset(220, 50), const Offset(60, 60)];
      } else {
        pts = [const Offset(40, 200), const Offset(250, 200), const Offset(270, 100), const Offset(150, 40), const Offset(30, 100)];
      }

      // Calculate area simulation
      double area = (a * b);
      if (selectedUnit == 'Meters') {
        area = area * 10.7639; // Convert sq.m to sq.ft
      }

      setState(() {
        calculatedPoints = pts;
        totalAreaSqFt = area;
        portionAreas = [area * 0.5, area * 0.5];
        isCalculated = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plot calculated successfully!'), backgroundColor: Colors.teal),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF00695C),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Area Calculator",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 2),
            Text(
              "Developed by Sahil Janwery",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.white), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TOP DROPDOWNS ROW
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Shape Type", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        DropdownButton<String>(
                          value: selectedShape,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['Triangle', 'Quadrilateral', 'Pentagon']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => selectedShape = val!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Measurement Unit:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        DropdownButton<String>(
                          value: selectedUnit,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['Meters', 'Feet']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => selectedUnit = val!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // INPUTS & SHAPE PREVIEW CARD
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small Shape Diagram Icon
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.teal, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        selectedShape == 'Triangle'
                            ? Icons.change_history
                            : selectedShape == 'Pentagon'
                                ? Icons.pentagon
                                : Icons.crop_square,
                        size: 48,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Dynamic Side Inputs
                  Expanded(
                    child: Column(
                      children: [
                        _buildSideInputField("Side AB", sideAController),
                        _buildSideInputField("Side BC", sideBController),
                        if (selectedShape != 'Triangle') _buildSideInputField("Side CD", sideCController),
                        if (selectedShape != 'Triangle') _buildSideInputField("Side DA", sideDController),
                        if (selectedShape == 'Pentagon') _buildSideInputField("Side EA", sideEController),
                        _buildSideInputField("Diagonal AC", diagACController),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // DIVISION DIRECTION DROPDOWN
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: selectedDirection,
                  underline: const SizedBox(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  items: ['Vertical', 'Horizontal', 'Parallel']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedDirection = val!),
                ),
                const Text("Division Direction", style: TextStyle(decoration: TextDecoration.underline, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),

            // ROUNDED CAPSULE CALCULATE BUTTON
            Center(
              child: ElevatedButton(
                onPressed: calculatePlot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00695C),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  "Calculate",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TOTAL AREA HEADER BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFB2DFDB),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Total Area",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),

            // AUTOCAD DRAFT PREVIEW CARD (NEON GRADIENT BORDER)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFFCE9FFC), Color(0xFF7367F0)],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Canvas Draft Map Box
                    Container(
                      height: 240,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomPaint(
                        painter: AutoCADDraftPainter(points: calculatedPoints),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Export Buttons inside Card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton(
                          onPressed: () {},
                          child: const Text("EXPORT PDF", style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text("EXPORT PNG", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // SCROLLABLE DETAILS SECTION
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Details & Breakdown", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00695C))),
                  const Divider(),
                  _buildDetailRow("Total Area (Sq.Ft):", "${totalAreaSqFt.toStringAsFixed(2)} sq.ft"),
                  _buildDetailRow("Total Area (Sq.Yd):", "${(totalAreaSqFt / 9).toStringAsFixed(2)} sq.yd"),
                  const SizedBox(height: 8),
                  const Text("Portions:", style: TextStyle(fontWeight: FontWeight.bold)),
                  ...portionAreas.asMap().entries.map((entry) {
                    return _buildDetailRow("Portion ${entry.key + 1}:", "${entry.value.toStringAsFixed(2)} sq.ft");
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSideInputField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 35,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(selectedUnit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          const Icon(Icons.calculate_outlined, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.black87)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }
}

// Custom Painter for AutoCAD Map Draft inside Card
class AutoCADDraftPainter extends CustomPainter {
  final List<Offset> points;
  AutoCADDraftPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF9FBFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    if (points.isEmpty) return;

    final fillPaint = Paint()
      ..color = const Color(0xFFD6E4F0)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = const Color(0xFF1565C0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, outlinePaint);

    // Draw Corner Dots & Text Labels
    final dotPaint = Paint()..color = Colors.blue.shade900;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
