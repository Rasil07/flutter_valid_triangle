// components/triangle_result_modal.dart
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;

// ------------ Types & classifier ------------
enum TriangleType { invalid, degenerate, equilateral, isosceles, scalene }

enum AngleType { acute, right, obtuse }

class TriangleResult {
  final TriangleType type;
  final AngleType angle; // acute/right/obtuse
  final String title;
  final String definition;
  final String? rightAtVertex; // "A" | "B" | "C" when right-angled
  const TriangleResult(
    this.type,
    this.angle,
    this.title,
    this.definition, {
    this.rightAtVertex,
  });
}

class TriangleClassifier {
  static const double _eps = 1e-9;

  static TriangleResult classify(num a, num b, num c) {
    final A = a.toDouble(), B = b.toDouble(), C = c.toDouble();
    if (!_finite(A) ||
        !_finite(B) ||
        !_finite(C) ||
        A <= 0 ||
        B <= 0 ||
        C <= 0) {
      return const TriangleResult(
        TriangleType.invalid,
        AngleType.acute,
        'Invalid',
        'Sides must be finite positive numbers.',
      );
    }

    final sorted = [A, B, C]..sort();
    final x = sorted[0], y = sorted[1], z = sorted[2];

    // Degenerate: x + y ≈ z
    if ((x + y - z).abs() <= _eps * math.max(1.0, z)) {
      return const TriangleResult(
        TriangleType.degenerate,
        AngleType.acute,
        'Degenerate Triangle',
        'The sum of two sides equals the third. Points are collinear.',
      );
    }
    if (x + y < z - _eps) {
      return const TriangleResult(
        TriangleType.invalid,
        AngleType.acute,
        'Invalid',
        'Violates the triangle inequality: the two shorter sides must exceed the longest.',
      );
    }

    // Side-type
    final eqAB = _eq(A, B), eqBC = _eq(B, C), eqCA = _eq(C, A);
    final sideType = (eqAB && eqBC && eqCA)
        ? TriangleType.equilateral
        : (eqAB || eqBC || eqCA)
        ? TriangleType.isosceles
        : TriangleType.scalene;

    // Angle-type via Pythag on sorted sides
    final s1 = x * x + y * y;
    final s2 = z * z;
    AngleType angleType;
    if (_relEq(s1, s2)) {
      angleType = AngleType.right;
    } else if (s1 > s2 + _eps * math.max(1.0, s1.abs())) {
      angleType = AngleType.acute;
    } else {
      angleType = AngleType.obtuse;
    }

    // Which vertex is right? Opposite the hypotenuse (longest side)
    String? rightAt;
    if (angleType == AngleType.right) {
      final hyp = z;
      if (_eq(hyp, A)) {
        rightAt = 'A';
      } else if (_eq(hyp, B)) {
        rightAt = 'B';
      } else {
        rightAt = 'C';
      }
    }

    final title = _composeTitle(sideType, angleType);
    final def = _composeDefinition(sideType, angleType, rightAt);
    return TriangleResult(
      sideType,
      angleType,
      title,
      def,
      rightAtVertex: rightAt,
    );
  }

  static String _composeTitle(TriangleType t, AngleType a) {
    if (t == TriangleType.invalid || t == TriangleType.degenerate)
      return _titleFor(t);
    final angleWord = a == AngleType.right
        ? 'Right-angled '
        : a == AngleType.obtuse
        ? 'Obtuse '
        : '';
    return '$angleWord${_titleFor(t)}';
  }

  static String _composeDefinition(
    TriangleType t,
    AngleType a,
    String? rightAt,
  ) {
    if (t == TriangleType.invalid) {
      return 'Sides must be finite positive numbers and satisfy triangle inequality.';
    }
    if (t == TriangleType.degenerate) {
      return 'The sum of two sides equals the third; points are collinear.';
    }
    final sideDef = switch (t) {
      TriangleType.equilateral => 'All three sides equal; all angles are 60°.',
      TriangleType.isosceles => 'At least two equal sides; base angles equal.',
      TriangleType.scalene => 'All sides (and angles) are different.',
      _ => '',
    };
    final angleDef = switch (a) {
      AngleType.right =>
        'Contains a 90° angle${rightAt != null ? ' at vertex $rightAt' : ''}.',
      AngleType.obtuse => 'Contains an angle > 90°.',
      AngleType.acute => 'All angles are < 90°.',
    };
    return '$sideDef $angleDef';
  }

  static String _titleFor(TriangleType t) => switch (t) {
    TriangleType.invalid => 'Invalid',
    TriangleType.degenerate => 'Degenerate Triangle',
    TriangleType.equilateral => 'Equilateral Triangle',
    TriangleType.isosceles => 'Isosceles Triangle',
    TriangleType.scalene => 'Scalene Triangle',
  };

  static bool _finite(double x) => !x.isNaN && !x.isInfinite;
  static bool _eq(double p, double q) {
    final diff = (p - q).abs();
    final scale = math.max(1.0, math.max(p.abs(), q.abs()));
    return diff <= _eps * scale;
  }

  static bool _relEq(double p, double q) {
    final diff = (p - q).abs();
    final scale = math.max(1.0, math.max(p.abs(), q.abs()));
    return diff <= 1e-9 * scale;
  }
}

// ------------ Public API ------------
Future<void> showTriangleResultModal(
  BuildContext context, {
  required num a,
  required num b,
  required num c,
}) async {
  final res = TriangleClassifier.classify(a, b, c);

  await showCupertinoModalPopup(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return _FrostedBottomSheet(
        child: _TriangleResultCard(
          a: a.toDouble(),
          b: b.toDouble(),
          c: c.toDouble(),
          result: res,
        ),
      );
    },
  );
}

// ------------ UI ------------
class _FrostedBottomSheet extends StatelessWidget {
  final Widget child;
  const _FrostedBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    final brightness = CupertinoTheme.of(context).brightness;
    final bg = brightness == Brightness.dark
        ? CupertinoColors.black
        : CupertinoColors.systemGrey6;

    return SafeArea(
      top: false,
      child: CupertinoPopupSurface(
        isSurfacePainted: true,
        child: Container(
          decoration: BoxDecoration(
            color: bg.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: child,
        ),
      ),
    );
  }
}

class _TriangleResultCard extends StatelessWidget {
  final double a, b, c;
  final TriangleResult result;

  const _TriangleResultCard({
    required this.a,
    required this.b,
    required this.c,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    final accent = theme.primaryColor;
    final muted = theme.textTheme.textStyle.color!.withAlpha(150);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // drag handle
        Center(
          child: Container(
            height: 5,
            width: 40,
            decoration: BoxDecoration(
              color: muted,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Icon(CupertinoIcons.triangle, size: 20, color: accent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                result.title,
                style: theme.textTheme.navTitleTextStyle.copyWith(fontSize: 20),
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Icon(
                CupertinoIcons.xmark,
                size: 18,
                color: Colors.black54,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                CupertinoColors.systemGrey5.withOpacity(0.35),
                CupertinoColors.systemGrey5.withOpacity(0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: CustomPaint(
              painter: _TrianglePainter(
                a: a,
                b: b,
                c: c,
                angle: result.angle,
                rightAt: result.rightAtVertex,
              ),
              isComplex: true,
            ),
          ),
        ),

        const SizedBox(height: 12),
        _KV('Sides', 'a=$a, b=$b, c=$c'),
        const SizedBox(height: 12),
        _KV('Angle', switch (result.angle) {
          AngleType.right =>
            result.rightAtVertex == null
                ? 'Right-angled'
                : 'Right-angled (at vertex ${result.rightAtVertex})',
          AngleType.obtuse => 'Obtuse',
          AngleType.acute => 'Acute',
        }),
        const SizedBox(height: 12),
        _KV('Definition', result.definition),

        const SizedBox(height: 20),
        CupertinoButton.filled(
          borderRadius: BorderRadius.circular(12),
          onPressed: () => Navigator.of(context).maybePop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _KV extends StatelessWidget {
  final String k, v;
  const _KV(this.k, this.v);
  @override
  Widget build(BuildContext context) {
    final tt = CupertinoTheme.of(context).textTheme;
    return RichText(
      text: TextSpan(
        style: tt.textStyle,
        children: [
          TextSpan(
            text: '$k: ',
            style: tt.textStyle.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: v),
        ],
      ),
    );
  }
}

// ------------ Painter ------------
class _TrianglePainter extends CustomPainter {
  final double a, b, c;
  final AngleType angle;
  final String? rightAt; // "A","B","C" if right-angled

  _TrianglePainter({
    required this.a,
    required this.b,
    required this.c,
    required this.angle,
    required this.rightAt,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        colors: [Color(0xFF6E7BFF), Color(0xFF98A3FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

    final paintStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF3B4BFF);

    final labelStyle = const TextStyle(
      color: Color(0xFF222222),
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    final pts = _coords(a, b, c);
    if (pts == null) {
      _drawCentered(canvas, size, 'Invalid');
      return;
    }

    // fit to canvas
    const pad = 12.0;
    final fitted = _fit(
      pts,
      Rect.fromLTWH(pad, pad, size.width - 2 * pad, size.height - 2 * pad),
    );

    // Build path
    final path = Path()
      ..moveTo(fitted.a.dx, fitted.a.dy)
      ..lineTo(fitted.b.dx, fitted.b.dy)
      ..lineTo(fitted.c.dx, fitted.c.dy)
      ..close();

    // Detect degenerate (nearly collinear) after fitting
    final degenerate =
        (fitted.c.dy - fitted.a.dy).abs() < 0.5 &&
        (fitted.b.dy - fitted.a.dy).abs() < 0.5;

    if (!degenerate) canvas.drawPath(path, paintFill);
    canvas.drawPath(path, paintStroke);

    // Labels (AB has length c, BC has a, CA has b)
    _edgeLabel(canvas, labelStyle, fitted.a, fitted.b, 'c'); // AB length c
    _edgeLabel(canvas, labelStyle, fitted.b, fitted.c, 'a');
    _edgeLabel(canvas, labelStyle, fitted.c, fitted.a, 'b');

    // Vertex dots
    final dot = Paint()..color = const Color(0xFF3B4BFF);
    for (final p in [fitted.a, fitted.b, fitted.c]) {
      canvas.drawCircle(p, 2.5, dot);
    }

    // Right-angle marker if applicable
    if (angle == AngleType.right && rightAt != null) {
      late Offset V, V1, V2;
      if (rightAt == 'A') {
        V = fitted.a;
        V1 = fitted.b;
        V2 = fitted.c;
      } else if (rightAt == 'B') {
        V = fitted.b;
        V1 = fitted.c;
        V2 = fitted.a;
      } else {
        V = fitted.c;
        V1 = fitted.a;
        V2 = fitted.b;
      }
      _drawRightMarker(canvas, V, V1, V2);
    }
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      a != old.a ||
      b != old.b ||
      c != old.c ||
      angle != old.angle ||
      rightAt != old.rightAt;

  // Compute coordinates using law of cosines (A at (0,0), B at (c,0))
  _Pts? _coords(double a, double b, double c) {
    const eps = 1e-9;
    if (a <= 0 || b <= 0 || c <= 0) return null;
    if ((a + b) < c - eps || (b + c) < a - eps || (c + a) < b - eps)
      return null;

    final A = const Offset(0, 0);
    final B = Offset(c, 0);
    if (c.abs() < eps) return null;

    final x = (b * b + c * c - a * a) / (2 * c);
    final y2 = b * b - x * x;
    final y = y2 <= 0 ? 0.0 : math.sqrt(y2);
    final C = Offset(x, -y); // flip to sit upright

    return _Pts(A, B, C);
  }

  _Pts _fit(_Pts p, Rect r) {
    final minX = math.min(p.a.dx, math.min(p.b.dx, p.c.dx));
    final maxX = math.max(p.a.dx, math.max(p.b.dx, p.c.dx));
    final minY = math.min(p.a.dy, math.min(p.b.dy, p.c.dy));
    final maxY = math.max(p.a.dy, math.max(p.b.dy, p.c.dy));
    final w = maxX - minX, h = maxY - minY;
    final scale = (w == 0 || h == 0)
        ? 1.0
        : 0.9 * math.min(r.width / w, r.height / h);

    Offset norm(Offset q) => Offset(
      r.left + (q.dx - minX) * scale + (r.width - w * scale) / 2,
      r.top + (q.dy - minY) * scale + (r.height - h * scale) / 2,
    );
    return _Pts(norm(p.a), norm(p.b), norm(p.c));
  }

  void _edgeLabel(Canvas c, TextStyle style, Offset p1, Offset p2, String txt) {
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final dx = p2.dx - p1.dx, dy = p2.dy - p1.dy;
    final len = math.max(1.0, math.sqrt(dx * dx + dy * dy));
    final nx = -dy / len, ny = dx / len;
    final pos = mid + Offset(nx * 10, ny * 10);

    final tp = TextPainter(
      text: TextSpan(text: txt, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, pos - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawRightMarker(Canvas canvas, Offset v, Offset v1, Offset v2) {
    // small square inside the angle at vertex v
    const double s = 14; // marker size in px
    final d1 = (v1 - v);
    final d2 = (v2 - v);
    final l1 = d1.distance == 0 ? 1 : d1.distance;
    final l2 = d2.distance == 0 ? 1 : d2.distance;
    final u1 = Offset(d1.dx / l1, d1.dy / l1);
    final u2 = Offset(d2.dx / l2, d2.dy / l2);

    final p1 = v + u1 * s;
    final p2 = v + u2 * s;
    final p3 = p1 + (p2 - v);

    final marker = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF3B4BFF);

    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p3.dx, p3.dy)
      ..lineTo(p2.dx, p2.dy);
    canvas.drawPath(path, marker);
  }

  void _drawCentered(Canvas c, Size s, String msg) {
    final tp = TextPainter(
      text: TextSpan(
        text: msg,
        style: const TextStyle(
          color: Color(0xFFDD3333),
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: s.width - 24);
    tp.paint(c, Offset((s.width - tp.width) / 2, (s.height - tp.height) / 2));
  }
}

class _Pts {
  final Offset a, b, c;
  _Pts(this.a, this.b, this.c);
}
