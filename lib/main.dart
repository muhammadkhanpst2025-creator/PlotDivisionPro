import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';

void main() {
  runApp(const PlotDivisionApp());
}


class SavedDataStore {
  static List<SavedMeasurementModel> items = [];

  static String exportToJson() {
    List<Map<String, dynamic>> rawList = [];

    for (var item in items) {
      rawList.add({
        'id': item.id,
        'name': item.name,
        'dateTime': item.dateTime,
        'shape': item.shape,
        'unit': item.unit,
        'sideA': item.sideA,
        'sideB': item.sideB,
        'sideC': item.sideC,
        'sideD': item.sideD,
        'sideE': item.sideE,
        'diagAC': item.diagAC,
        'diagAD': item.diagAD,
        'direction': item.direction,
        'totalArea': item.totalArea,
      });
    }

    return jsonEncode(rawList);
  }

  static void importFromJson(String jsonString) {
    try {
      List<dynamic> jsonList = jsonDecode(jsonString);
      items.clear();

      for (var map in jsonList) {
        items.add(SavedMeasurementModel(
          id: map['id'] ?? DateTime.now().toString(),
          name: map['name'] ?? 'Plot Record',
          dateTime: map['dateTime'] ?? '',
          shape: map['shape'] ?? 'Quadrilateral',
          unit: map['unit'] ?? 'Meters',
          sideA: map['sideA'] ?? '',
          sideB: map['sideB'] ?? '',
          sideC: map['sideC'] ?? '',
          sideD: map['sideD'] ?? '',
          sideE: map['sideE'] ?? '',
          diagAC: map['diagAC'] ?? '',
          diagAD: map['diagAD'] ?? '',
          direction: map['direction'] ?? 'Vertical',
          totalArea: (map['totalArea'] ?? 0.0).toDouble(),
        ));
      }
    } catch (e) {
      print("Restore error: $e");
    }
  }
}

class SavedMeasurementModel {
  final String id;
  final String name;
  final String dateTime;
  final String shape;
  final String unit;
  final String sideA, sideB, sideC, sideD, sideE, diagAC, diagAD;
  final String direction;
  final double totalArea;

  SavedMeasurementModel({
    required this.id,
    required this.name,
    required this.dateTime,
    required this.shape,
    required this.unit,
    required this.sideA,
    required this.sideB,
    required this.sideC,
    required this.sideD,
    required this.sideE,
    required this.diagAC,
    required this.diagAD,
    required this.direction,
    required this.totalArea,
  });
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
  final TextEditingController diagACController = TextEditingController(text: '45');
  final TextEditingController diagADController = TextEditingController();

  List<Offset> calculatedPoints = [];
  double totalAreaSqFt = 0.0;
  List<double> portionAreas = [];

  void calculatePlot() {
    try {
      double a = double.tryParse(sideAController.text) ?? 0;
      double b = double.tryParse(sideBController.text) ?? 0;

      if (a <= 0 || b <= 0) {
        throw Exception("Please enter valid side dimensions.");
      }

      List<Offset> pts = [];
      if (selectedShape == 'Triangle') {
        pts = [const Offset(60, 200), const Offset(240, 200), const Offset(150, 50)];
      } else if (selectedShape == 'Quadrilateral') {
        pts = [const Offset(40, 200), const Offset(260, 180), const Offset(220, 50), const Offset(60, 70)];
      } else {
        pts = [const Offset(40, 200), const Offset(260, 200), const Offset(280, 100), const Offset(150, 40), const Offset(20, 100)];
      }

      double area = (a * b);
      if (selectedUnit == 'Meters') {
        area = area * 10.7639;
      }

      setState(() {
        calculatedPoints = pts;
        totalAreaSqFt = area;
        portionAreas = [area * 0.5, area * 0.5];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plot calculated & drafted successfully!'), backgroundColor: Colors.teal),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  void promptSaveMeasurement() {
    TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Measurement"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter Name (e.g. Plot # 12 - Ahmed)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00695C)),
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              String dateTimeNow = "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute}";
              
              SavedDataStore.items.add(SavedMeasurementModel(
                id: DateTime.now().toString(),
                name: nameController.text.trim(),
                dateTime: dateTimeNow,
                shape: selectedShape,
                unit: selectedUnit,
                sideA: sideAController.text,
                sideB: sideBController.text,
                sideC: sideCController.text,
                sideD: sideDController.text,
                sideE: sideEController.text,
                diagAC: diagACController.text,
                diagAD: diagADController.text,
                direction: selectedDirection,
                totalArea: totalAreaSqFt,
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Measurement saved successfully with Date/Time!"), backgroundColor: Colors.green),
              );
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void loadMeasurement(SavedMeasurementModel item) {
    setState(() {
      selectedShape = item.shape;
      selectedUnit = item.unit;
      sideAController.text = item.sideA;
      sideBController.text = item.sideB;
      sideCController.text = item.sideC;
      sideDController.text = item.sideD;
      sideEController.text = item.sideE;
      diagACController.text = item.diagAC;
      diagADController.text = item.diagAD;
      selectedDirection = item.direction;
    });
    calculatePlot();
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
          IconButton(
            icon: const Icon(Icons.chat, color: Colors.greenAccent),
            tooltip: "WhatsApp: 03443157928",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("WhatsApp Contact: Sahil Janwery - 03443157928")),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_added, color: Colors.white),
            tooltip: "Saved Measurements",
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedMeasurementsScreen()),
              );
              if (result != null && result is SavedMeasurementModel) {
                loadMeasurement(result);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  Expanded(
                    child: Column(
                      children: [
                        _buildSideInputField("Side A", sideAController),
                        _buildSideInputField("Side B", sideBController),
                        if (selectedShape != 'Triangle') _buildSideInputField("Side C", sideCController),
                        if (selectedShape != 'Triangle') _buildSideInputField("Side D", sideDController),
                        if (selectedShape == 'Pentagon') _buildSideInputField("Side E", sideEController),
                        _buildSideInputField("Side AC", diagACController),
                        if (selectedShape == 'Pentagon') _buildSideInputField("Side AE", diagADController),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: calculatePlot,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00695C),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Calculate", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Text("Direction: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<String>(
                        value: selectedDirection,
                        underline: const SizedBox(),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        items: ['Vertical', 'Horizontal', 'Parallel']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) => setState(() => selectedDirection = val!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFB2DFDB),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Total Area & AutoCAD Drafting",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: AutoCADDraftPainter(points: calculatedPoints, shape: selectedShape),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo.shade50,
                          foregroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.picture_as_pdf, size: 18),
                        label: const Text("EXPORT PDF", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade50,
                          foregroundColor: Colors.teal.shade900,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.image, size: 18),
                        label: const Text("EXPORT PNG", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: promptSaveMeasurement,
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text("Save Measurement Record", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
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

class SavedMeasurementsScreen extends StatefulWidget {
  const SavedMeasurementsScreen({super.key});

  @override
  State<SavedMeasurementsScreen> createState() => _SavedMeasurementsScreenState();
}

class _SavedMeasurementsScreenState extends State<SavedMeasurementsScreen> {
  String searchQuery = "";

  void exportBackupDialog() {
    String jsonOutput = SavedDataStore.exportToJson();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Local Backup (JSON)"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(jsonOutput, style: const TextStyle(fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void importRestoreDialog() {
    TextEditingController restoreController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Restore Backup"),
        content: TextField(
          controller: restoreController,
          maxLines: 5,
          decoration: const InputDecoration(hintText: "Paste backup JSON data here..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              if (restoreController.text.trim().isEmpty) return;
              SavedDataStore.importFromJson(restoreController.text.trim());
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Data restored successfully!"), backgroundColor: Colors.green),
              );
            },
            child: const Text("Restore", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = SavedDataStore.items
        .where((item) => item.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
                         item.shape.toLowerCase().contains(searchQuery.toLowerCase()) ||
                         item.dateTime.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Saved Records & Backup"),
        backgroundColor: const Color(0xFF00695C),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: "Export Backup",
            onPressed: exportBackupDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Restore Backup",
            onPressed: importRestoreDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search by name, date or shape...",
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(child: Text("No saved measurements found.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE0F2F1),
                            child: Icon(Icons.architecture, color: Colors.teal),
                          ),
                          title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Shape: ${item.shape} | Date: ${item.dateTime}\nArea: ${item.totalArea.toStringAsFixed(0)} sq.ft"),
                          isThreeLine: true,
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.teal),
                          onTap: () {
                            Navigator.pop(context, item);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class AutoCADDraftPainter extends CustomPainter {
  final List<Offset> points;
  final String shape;

  AutoCADDraftPainter({required this.points, required this.shape});

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

    final dottedPaint = Paint()
      ..color = Colors.red.shade700
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    if (points.length >= 3) {
      _drawDottedLine(canvas, points[0], points[2], dottedPaint);
    }

    List<String> labels = ['A', 'B', 'C', 'D', 'E'];
    TextStyle textStyle = const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.bold);

    for (int i = 0; i < points.length && i < labels.length; i++) {
      final dotPaint = Paint()..color = Colors.blue.shade900;
      canvas.drawCircle(points[i], 4, dotPaint);

      TextSpan span = TextSpan(text: labels[i], style: textStyle);
      TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, points[i] + const Offset(-5, -15));
    }
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    double dashWidth = 5, dashSpace = 3, distance = 0;
    final vector = p2 - p1;
    final length = vector.distance;
    final unitVector = vector / length;
    while (distance < length) {
      var start = p1 + unitVector * distance;
      var end = p1 + unitVector * min(distance + dashWidth, length);
      canvas.drawLine(start, end, paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
