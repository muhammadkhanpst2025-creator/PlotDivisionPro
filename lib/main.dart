
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const PlotDivisionApp());

const double eps = 1e-9;

typedef Point = Offset;

double distance(Point a, Point b) => (a - b).distance;

double signedArea(List<Point> p) {
  double s = 0;
  for (int i = 0; i < p.length; i++) {
    final q = p[(i + 1) % p.length];
    s += p[i].dx * q.dy - q.dx * p[i].dy;
  }
  return s / 2;
}

double area(List<Point> p) => p.length < 3 ? 0 : signedArea(p).abs();

double parseMeasure(String raw, String unit) {
  String s = raw.trim().toLowerCase();
  if (s.isEmpty) throw const FormatException('Measurement khali hai.');

  double value;
  if (s.contains("'")) {
    final parts = s.split("'");
    final ft = double.parse(parts[0].trim());
    final inchText = parts.length > 1
        ? parts[1].replaceAll('"', '').replaceAll('in', '').replaceAll('-', '').trim()
        : '';
    final inches = inchText.isEmpty ? 0.0 : double.parse(inchText);
    value = ft + inches / 12;
  } else if (s.contains('ft') || s.contains('in')) {
    final ftMatch = RegExp(r'([\d.]+)\s*ft').firstMatch(s);
    final inMatch = RegExp(r'([\d.]+)\s*in').firstMatch(s);
    value = (ftMatch == null ? 0 : double.parse(ftMatch.group(1)!)) +
        (inMatch == null ? 0 : double.parse(inMatch.group(1)!)) / 12;
  } else {
    value = double.parse(s);
    if (unit == 'Meters') value *= 3.280839895;
  }
  if (!value.isFinite || value <= 0) {
    throw const FormatException('Measurement zero se bara hona chahiye.');
  }
  return value;
}

List<Point> circleIntersections(Point p, double r1, Point q, double r2) {
  final dx = q.dx - p.dx, dy = q.dy - p.dy;
  final d = math.sqrt(dx * dx + dy * dy);
  if (d < eps || d > r1 + r2 + eps || d < (r1 - r2).abs() - eps) {
    return [];
  }
  final a = (r1 * r1 - r2 * r2 + d * d) / (2 * d);
  final h2 = r1 * r1 - a * a;
  if (h2 < -eps) return [];
  final h = math.sqrt(math.max(0, h2));
  final xm = p.dx + a * dx / d;
  final ym = p.dy + a * dy / d;
  final rx = -dy * h / d, ry = dx * h / d;
  return [
    Offset(xm + rx, ym + ry),
    Offset(xm - rx, ym - ry),
  ];
}

List<Point> buildTriangle(double a, double b, double c) {
  if (a + b <= c || a + c <= b || b + c <= a) {
    throw const FormatException('In sides se triangle nahi ban sakta.');
  }
  final x = (a * a + c * c - b * b) / (2 * a);
  final y2 = c * c - x * x;
  if (y2 <= 0) throw const FormatException('Triangle measurements invalid hain.');
  return [const Offset(0, 0), Offset(a, 0), Offset(x, math.sqrt(y2))];
}

List<Point> buildQuadrilateral(double a, double b, double c, double d, double diagonal) {
  final A = const Offset(0, 0);
  final C = Offset(diagonal, 0);
  final bs = circleIntersections(A, a, C, b);
  final ds = circleIntersections(A, d, C, c);
  if (bs.isEmpty || ds.isEmpty) {
    throw const FormatException('Diagonal AC aur sides ki measurements match nahi kartin.');
  }
  final B = bs.reduce((x, y) => x.dy > y.dy ? x : y);
  final D = ds.reduce((x, y) => x.dy < y.dy ? x : y);
  final result = [A, B, C, D];
  if (area(result) < eps) throw const FormatException('Quadrilateral area zero hai.');
  return result;
}

List<Point> buildPentagon(
    double a, double b, double c, double d, double e,
    double ac, double ad) {
  final A = const Offset(0, 0);
  final C = Offset(ac, 0);
  final bs = circleIntersections(A, a, C, b);
  final ds = circleIntersections(A, ad, C, c);
  if (bs.isEmpty || ds.isEmpty) {
    throw const FormatException('Pentagon ki diagonal measurements invalid hain.');
  }
  final B = bs.reduce((x, y) => x.dy > y.dy ? x : y);
  final D = ds.reduce((x, y) => x.dy < y.dy ? x : y);
  final es = circleIntersections(A, e, D, d);
  if (es.isEmpty) {
    throw const FormatException('Side D, Side E aur diagonal AD match nahi karte.');
  }
  final E = es.reduce((x, y) => x.dx < y.dx ? x : y);
  final result = [A, B, C, D, E];
  if (area(result) < eps) throw const FormatException('Pentagon area zero hai.');
  return result;
}

List<Point> clipPolygon(List<Point> points, double nx, double ny, double c) {
  if (points.isEmpty) return [];
  final out = <Point>[];
  for (int i = 0; i < points.length; i++) {
    final cur = points[i], prev = points[(i - 1 + points.length) % points.length];
    final cv = nx * cur.dx + ny * cur.dy - c;
    final pv = nx * prev.dx + ny * prev.dy - c;
    final ci = cv <= eps, pi = pv <= eps;
    if (ci && pi) {
      out.add(cur);
    } else if (pi != ci) {
      final den = pv - cv;
      if (den.abs() > eps) {
        final t = pv / den;
        out.add(Offset(
          prev.dx + t * (cur.dx - prev.dx),
          prev.dy + t * (cur.dy - prev.dy),
        ));
      }
      if (ci) out.add(cur);
    }
  }
  return out;
}

double areaForCut(List<Point> p, double nx, double ny, double c) =>
    area(clipPolygon(p, nx, ny, c));

double findCut(List<Point> p, double fraction, double nx, double ny) {
  final values = p.map((v) => nx * v.dx + ny * v.dy).toList();
  double lo = values.reduce(math.min), hi = values.reduce(math.max);
  final target = area(p) * fraction;
  for (int i = 0; i < 100; i++) {
    final mid = (lo + hi) / 2;
    if (areaForCut(p, nx, ny, mid) < target) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return (lo + hi) / 2;
}

Point? cutSegment(List<Point> p, double nx, double ny, double c) {
  final hits = <Point>[];
  for (int i = 0; i < p.length; i++) {
    final a = p[i], b = p[(i + 1) % p.length];
    final fa = nx * a.dx + ny * a.dy - c;
    final fb = nx * b.dx + ny * b.dy - c;
    if (fa.abs() < eps) hits.add(a);
    if (fa * fb < -eps) {
      final t = fa / (fa - fb);
      hits.add(Offset(
        a.dx + t * (b.dx - a.dx),
        a.dy + t * (b.dy - a.dy),
      ));
    }
    if (fb.abs() < eps) hits.add(b);
  }
  final unique = <Point>[];
  for (final p1 in hits) {
    if (!unique.any((p2) => distance(p1, p2) < 1e-6)) unique.add(p1);
  }
  if (unique.length < 2) return null;
  Point? first, second;
  double best = -1;
  for (int i = 0; i < unique.length; i++) {
    for (int j = i + 1; j < unique.length; j++) {
      final d = distance(unique[i], unique[j]);
      if (d > best) {
        best = d;
        first = unique[i];
        second = unique[j];
      }
    }
  }
  if (first == null || second == null) return null;
  return first;
}

List<Point> divisionLine(List<Point> p, double nx, double ny, double c) {
  final hits = <Point>[];
  for (int i = 0; i < p.length; i++) {
    final a = p[i], b = p[(i + 1) % p.length];
    final fa = nx * a.dx + ny * a.dy - c;
    final fb = nx * b.dx + ny * b.dy - c;
    if (fa.abs() < eps) hits.add(a);
    if (fa * fb < -eps) {
      final t = fa / (fa - fb);
      hits.add(Offset(a.dx + t * (b.dx - a.dx), a.dy + t * (b.dy - a.dy)));
    }
    if (fb.abs() < eps) hits.add(b);
  }
  final unique = <Point>[];
  for (final x in hits) {
    if (!unique.any((y) => distance(x, y) < 1e-6)) unique.add(x);
  }
  if (unique.length < 2) return [];
  unique.sort((a, b) => distance(a, unique.first).compareTo(distance(b, unique.first)));
  return [unique.first, unique.last];
}

List<double> divisionNormal(List<Point> p, String direction) {
  if (direction == 'Horizontal') return [0, 1];
  if (direction == 'Vertical') return [1, 0];
  final index = int.tryParse(direction.substring(direction.length - 1)) ?? 0;
  final a = p[index % p.length], b = p[(index + 1) % p.length];
  final dx = b.dx - a.dx, dy = b.dy - a.dy;
  final len = math.sqrt(dx * dx + dy * dy);
  return [-dy / len, dx / len];
}

class DivisionResult {
  final List<List<Point>> lines;
  final List<double> areas;
  DivisionResult(this.lines, this.areas);
}

DivisionResult calculateDivisions(List<Point> p, List<double> percentages, String direction) {
  final n = divisionNormal(p, direction);
  final nx = n[0], ny = n[1];
  double cumulative = 0;
  final offsets = <double>[];
  final lines = <List<Point>>[];
  for (final pct in percentages.take(percentages.length - 1)) {
    cumulative += pct;
    final c = findCut(p, cumulative / 100, nx, ny);
    final line = divisionLine(p, nx, ny, c);
    if (line.length != 2) throw const FormatException('Division line calculate nahi hui.');
    offsets.add(c);
    lines.add(line);
  }
  return DivisionResult(lines, percentages.map((v) => area(p) * v / 100).toList());
}

class PlotDivisionApp extends StatelessWidget {
  const PlotDivisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plot Division Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF124A82)),
        useMaterial3: true,
      ),
      home: const PlotHome(),
    );
  }
}

class PlotHome extends StatefulWidget {
  const PlotHome({super.key});
  @override
  State<PlotHome> createState() => _PlotHomeState();
}

class _PlotHomeState extends State<PlotHome> {
  String shape = 'Quadrilateral';
  String unit = 'Feet';
  String direction = 'Vertical';
  final fields = <String, TextEditingController>{
    'A': TextEditingController(text: '35'),
    'B': TextEditingController(text: '40'),
    'C': TextEditingController(text: '55'),
    'D': TextEditingController(text: '60'),
    'E': TextEditingController(text: '30'),
    'AC': TextEditingController(text: '45'),
    'AD': TextEditingController(text: '50'),
    'P': TextEditingController(text: '50,50'),
  };
  List<Point> points = [];
  List<List<Point>> lines = [];
  List<double> portions = [];
  double total = 0;
  String message = 'Measurements enter karein aur Calculate dabayein.';

  @override
  void dispose() {
    for (final c in fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  double read(String key) => parseMeasure(fields[key]!.text, unit);

  void calculate() {
    try {
      final a = read('A'), b = read('B'), c = read('C');
      late List<Point> p;
      if (shape == 'Triangle') {
        p = buildTriangle(a, b, c);
      } else if (shape == 'Quadrilateral') {
        p = buildQuadrilateral(a, b, c, read('D'), read('AC'));
      } else {
        p = buildPentagon(a, b, c, read('D'), read('E'), read('AC'), read('AD'));
      }
      final percentages = fields['P']!.text.split(',').map((v) => double.parse(v.trim())).toList();
      if (percentages.length < 2 || percentages.any((v) => v <= 0) ||
          (percentages.fold<double>(0, (s, v) => s + v) - 100).abs() > 0.001) {
        throw const FormatException('Percentages kam az kam 2 hon aur total 100 hon. Misal: 50,30,20');
      }
      final result = calculateDivisions(p, percentages, direction);
      setState(() {
        points = p;
        lines = result.lines;
        portions = result.areas;
        total = area(p);
        message = 'Calculation successful';
      });
    } catch (e) {
      setState(() {
        points = [];
        lines = [];
        portions = [];
        total = 0;
        message = e.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  Widget input(String key, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: fields[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          hintText: 'Misal: 44.5 ya 44\\'-6"',
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showD = shape != 'Triangle';
    final showE = shape == 'Pentagon';
    return Scaffold(
      appBar: AppBar(
        title: const Text('PLOT DIVISION PRO'),
        backgroundColor: const Color(0xFF124A82),
        foregroundColor: Colors.white,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(25),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Developed by Sahil Janwery', style: TextStyle(color: Colors.white70)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: shape,
                      decoration: const InputDecoration(labelText: 'Plot Shape'),
                      items: ['Triangle', 'Quadrilateral', 'Pentagon']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => shape = v!),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: unit,
                      decoration: const InputDecoration(labelText: 'Measurement Unit'),
                      items: ['Feet', 'Meters']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => unit = v!),
                    ),
                    const SizedBox(height: 14),
                    input('A', 'Side A'),
                    input('B', 'Side B'),
                    input('C', 'Side C'),
                    if (showD) input('D', 'Side D'),
                    if (showE) input('E', 'Side E'),
                    if (showD) input('AC', 'Diagonal AC'),
                    if (showE) input('AD', 'Diagonal AD'),
                    input('P', 'Division percentages (e.g. 50,30,20)'),
                    DropdownButtonFormField<String>(
                      value: direction,
                      decoration: const InputDecoration(labelText: 'Division Direction'),
                      items: [
                        'Horizontal', 'Vertical',
                        'Parallel to Side 1', 'Parallel to Side 2',
                        'Parallel to Side 3', 'Parallel to Side 4',
                        'Parallel to Side 5'
                      ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) => setState(() => direction = v!),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: calculate,
                        icon: const Icon(Icons.calculate),
                        label: const Text('CALCULATE + DRAW'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Plot Drawing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: PlotPainter(points: points, lines: lines),
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const Divider(),
                    Text(message, style: TextStyle(
                      color: points.isEmpty ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 12),
                    Text('Total Area: ${total.toStringAsFixed(2)} sq.ft',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Total Area: ${(total / 9).toStringAsFixed(2)} sq.yd'),
                    const SizedBox(height: 10),
                    for (int i = 0; i < portions.length; i++)
                      ListTile(
                        dense: true,
                        leading: CircleAvatar(child: Text('${i + 1}')),
                        title: Text('Portion ${i + 1}'),
                        trailing: Text('${portions[i].toStringAsFixed(2)} sq.ft',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlotPainter extends CustomPainter {
  final List<Point> points;
  final List<List<Point>> lines;
  PlotPainter({required this.points, required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawColor(const Color(0xFFF7FAFE), BlendMode.src);
    if (points.length < 3) {
      final tp = TextPainter(
        text: const TextSpan(text: 'Plot drawing yahan nazar aayegi', style: TextStyle(color: Colors.grey)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, size.height / 2));
      return;
    }

    final minX = points.map((p) => p.dx).reduce(math.min);
    final maxX = points.map((p) => p.dx).reduce(math.max);
    final minY = points.map((p) => p.dy).reduce(math.min);
    final maxY = points.map((p) => p.dy).reduce(math.max);
    final spanX = math.max(maxX - minX, 0.001);
    final spanY = math.max(maxY - minY, 0.001);
    final scale = math.min((size.width - 70) / spanX, (size.height - 70) / spanY);
    final usedW = spanX * scale, usedH = spanY * scale;
    final ox = (size.width - usedW) / 2, oy = (size.height - usedH) / 2;

    Point mapPoint(Point p) => Offset(
      ox + (p.dx - minX) * scale,
      size.height - oy - (p.dy - minY) * scale,
    );

    final path = Path()..moveTo(mapPoint(points.first).dx, mapPoint(points.first).dy);
    for (final p in points.skip(1)) {
      final q = mapPoint(p);
      path.lineTo(q.dx, q.dy);
    }
    path.close();

    canvas.drawPath(path, Paint()..color = const Color(0xFFDCEBFA));
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF124A82)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke);

    for (final line in lines) {
      if (line.length != 2) continue;
      canvas.drawLine(mapPoint(line[0]), mapPoint(line[1]),
        Paint()..color = Colors.red..strokeWidth = 2.2);
    }

    for (int i = 0; i < points.length; i++) {
      final p = mapPoint(points[i]);
      canvas.drawCircle(p, 4, Paint()..color = Colors.blue.shade900);
      final tp = TextPainter(
        text: TextSpan(text: String.fromCharCode(65 + i),
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p + const Offset(5, -18));
    }
  }

  @override
  bool shouldRepaint(covariant PlotPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lines != lines;
}
