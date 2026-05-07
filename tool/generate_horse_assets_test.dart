import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generate horse assets', () async {
    final generator = HorseAssetGenerator();
    await generator.generateAll();
    expect(
      File('assets/horses/arabian/body/athletic.png').existsSync(),
      isTrue,
    );
  });
}

class HorseAssetGenerator {
  static const canvasSize = ui.Size(1200, 1200);

  Future<void> generateAll() async {
    await _write('assets/horses/arabian/body/slim.png', _paintBodySlim);
    await _write('assets/horses/arabian/body/athletic.png', _paintBodyAthletic);
    await _write('assets/horses/arabian/body/stock.png', _paintBodyStock);
    await _write('assets/horses/arabian/mane/natural.png', _paintManeNatural);
    await _write('assets/horses/arabian/mane/short.png', _paintManeShort);
    await _write('assets/horses/arabian/mane/medium.png', _paintManeMedium);
    await _write('assets/horses/arabian/mane/braided.png', _paintManeBraided);
    await _write('assets/horses/arabian/mane/long_curly.png', _paintManeLongCurly);
    await _write('assets/horses/arabian/tail/natural.png', _paintTailNatural);
    await _write('assets/horses/arabian/tail/full.png', _paintTailFull);
    await _write('assets/horses/arabian/markings/blaze.png', _paintMarkingBlaze);
    await _write('assets/horses/arabian/markings/star.png', _paintMarkingStar);
    await _write('assets/horses/arabian/markings/stripe.png', _paintMarkingStripe);
    await _write('assets/horses/arabian/pattern/dapple.png', _paintPatternDapple);
    await _write('assets/horses/arabian/fx/metallic_sheen.png', _paintSheen);
    await _write('assets/horses/arabian/face/eye.png', _paintEye);
  }

  Future<void> _write(
    String path,
    void Function(Canvas canvas, ui.Size size) painter,
  ) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter(canvas, canvasSize);
    final image = await recorder.endRecording().toImage(
      canvasSize.width.toInt(),
      canvasSize.height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  }

  void _paintBodySlim(Canvas canvas, ui.Size size) {
    _paintBody(canvas, size, bodyScaleX: 0.94, bodyScaleY: 0.9, neckLift: -12);
  }

  void _paintBodyAthletic(Canvas canvas, ui.Size size) {
    _paintBody(canvas, size, bodyScaleX: 1.0, bodyScaleY: 1.0, neckLift: 0);
  }

  void _paintBodyStock(Canvas canvas, ui.Size size) {
    _paintBody(canvas, size, bodyScaleX: 1.08, bodyScaleY: 1.08, neckLift: 10);
  }

  void _paintBody(
    Canvas canvas,
    ui.Size size, {
    required double bodyScaleX,
    required double bodyScaleY,
    required double neckLift,
  }) {
    final bodyRect = Rect.fromCenter(
      center: Offset(size.width * 0.58, size.height * 0.62),
      width: size.width * 0.50 * bodyScaleX,
      height: size.height * 0.24 * bodyScaleY,
    );
    final headRect = Rect.fromCenter(
      center: Offset(size.width * 0.34, size.height * (0.39 + neckLift / 1200)),
      width: size.width * 0.12,
      height: size.height * 0.13,
    );
    final wither = Offset(bodyRect.left + bodyRect.width * 0.12, bodyRect.top + 18);
    final neckTop = Offset(size.width * 0.43, size.height * (0.46 + neckLift / 1200));
    final shoulder = Offset(bodyRect.left + 22, bodyRect.top + bodyRect.height * 0.54);
    final belly = Offset(bodyRect.center.dx, bodyRect.bottom + 10);
    final croup = Offset(bodyRect.right - 12, bodyRect.top + bodyRect.height * 0.24);

    final silhouette = Path()
      ..moveTo(croup.dx - 18, bodyRect.top + 16)
      ..cubicTo(
        bodyRect.center.dx + 54,
        bodyRect.top - 24,
        bodyRect.left + 64,
        bodyRect.top - 8,
        wither.dx,
        wither.dy,
      )
      ..cubicTo(
        size.width * 0.46,
        size.height * 0.56,
        size.width * 0.44,
        size.height * 0.50,
        neckTop.dx,
        neckTop.dy,
      )
      ..cubicTo(
        headRect.center.dx + 14,
        headRect.center.dy - 18,
        headRect.center.dx + 18,
        headRect.top + 6,
        headRect.left + 12,
        headRect.top + 24,
      )
      ..cubicTo(
        headRect.left - 8,
        headRect.center.dy + 4,
        headRect.left - 6,
        headRect.bottom + 8,
        headRect.left + 18,
        headRect.bottom + 12,
      )
      ..cubicTo(
        headRect.left + 44,
        headRect.bottom + 8,
        headRect.center.dx + 12,
        headRect.center.dy + 18,
        neckTop.dx + 6,
        size.height * 0.58,
      )
      ..cubicTo(
        shoulder.dx + 18,
        bodyRect.bottom + 4,
        shoulder.dx + 6,
        bodyRect.bottom + 18,
        bodyRect.left + 34,
        bodyRect.bottom + 8,
      )
      ..cubicTo(
        bodyRect.center.dx - 20,
        belly.dy,
        bodyRect.right - 42,
        bodyRect.bottom + 18,
        bodyRect.right - 16,
        bodyRect.bottom + 4,
      )
      ..cubicTo(
        bodyRect.right + 16,
        bodyRect.center.dy - 4,
        bodyRect.right + 10,
        bodyRect.top + 28,
        croup.dx,
        croup.dy,
      )
      ..close();

    final basePaint = Paint()..color = const Color(0xFFD8D1C8);
    final outlinePaint = Paint()
      ..color = const Color(0xFF473F39)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(silhouette, basePaint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyRect.left + bodyRect.width * 0.56, bodyRect.top + bodyRect.height * 0.48),
        width: bodyRect.width * 0.56,
        height: bodyRect.height * 0.50,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(bodyRect.left + bodyRect.width * 0.24, bodyRect.top + bodyRect.height * 0.60),
        width: bodyRect.width * 0.16,
        height: bodyRect.height * 0.22,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.07),
    );

    final legs = [
      _legPath(start: Offset(bodyRect.left + bodyRect.width * 0.17, bodyRect.bottom - 8), groundY: size.height * 0.81, width: 28, forward: true),
      _legPath(start: Offset(bodyRect.left + bodyRect.width * 0.33, bodyRect.bottom - 6), groundY: size.height * 0.81, width: 26, forward: false),
      _legPath(start: Offset(bodyRect.left + bodyRect.width * 0.68, bodyRect.bottom - 10), groundY: size.height * 0.81, width: 24, forward: false),
      _legPath(start: Offset(bodyRect.left + bodyRect.width * 0.83, bodyRect.bottom - 14), groundY: size.height * 0.81, width: 24, forward: true),
    ];
    for (final leg in legs) {
      canvas.drawPath(leg, basePaint);
      canvas.drawPath(leg, outlinePaint);
    }

    final ears = [
      Path()
        ..moveTo(headRect.left + 34, headRect.top + 4)
        ..lineTo(headRect.left + 48, headRect.top - 20)
        ..lineTo(headRect.left + 54, headRect.top + 12)
        ..close(),
      Path()
        ..moveTo(headRect.left + 50, headRect.top + 8)
        ..lineTo(headRect.left + 64, headRect.top - 14)
        ..lineTo(headRect.left + 70, headRect.top + 16)
        ..close(),
    ];
    for (final ear in ears) {
      canvas.drawPath(ear, basePaint);
      canvas.drawPath(ear, outlinePaint);
    }

    canvas.drawPath(silhouette, outlinePaint);

    final facePaint = Paint()
      ..color = const Color(0xFF473F39)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final jawLine = Path()
      ..moveTo(headRect.left + 6, headRect.center.dy + 8)
      ..quadraticBezierTo(
        headRect.left + 26,
        headRect.bottom + 8,
        headRect.left + 46,
        headRect.center.dy + 16,
      );
    canvas.drawPath(jawLine, facePaint);
    canvas.drawLine(
      Offset(headRect.left + 20, headRect.top + 22),
      Offset(headRect.left + 4, headRect.center.dy + 6),
      facePaint,
    );
    canvas.drawCircle(
      Offset(headRect.left + 12, headRect.center.dy + 10),
      4,
      Paint()..color = const Color(0xFF473F39),
    );

    for (final hoofX in [
      bodyRect.left + bodyRect.width * 0.16,
      bodyRect.left + bodyRect.width * 0.32,
      bodyRect.left + bodyRect.width * 0.68,
      bodyRect.left + bodyRect.width * 0.82,
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(hoofX, size.height * 0.81, 30, 12),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0xFF473F39),
      );
    }
  }

  Path _legPath({
    required Offset start,
    required double groundY,
    required double width,
    required bool forward,
  }) {
    final bendX = forward ? start.dx + 10 : start.dx - 2;
    return Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo(bendX, start.dy + 72, start.dx + 6, groundY)
      ..lineTo(start.dx + width, groundY)
      ..quadraticBezierTo(start.dx + width - 6, start.dy + 72, start.dx + width - 2, start.dy)
      ..close();
  }

  void _paintManeNatural(Canvas canvas, ui.Size size) {
    _paintMane(canvas, size, kind: 'natural');
  }

  void _paintManeShort(Canvas canvas, ui.Size size) {
    _paintMane(canvas, size, kind: 'short');
  }

  void _paintManeMedium(Canvas canvas, ui.Size size) {
    _paintMane(canvas, size, kind: 'medium');
  }

  void _paintManeBraided(Canvas canvas, ui.Size size) {
    _paintMane(canvas, size, kind: 'braided');
  }

  void _paintManeLongCurly(Canvas canvas, ui.Size size) {
    _paintMane(canvas, size, kind: 'long_curly');
  }

  void _paintMane(Canvas canvas, ui.Size size, {required String kind}) {
    final paint = Paint()..color = const Color(0xFFD0D0D0);
    final path = Path()..moveTo(size.width * 0.42, size.height * 0.42);
    if (kind == 'short') {
      path
        ..cubicTo(size.width * 0.46, size.height * 0.48, size.width * 0.45, size.height * 0.51, size.width * 0.44, size.height * 0.54)
        ..cubicTo(size.width * 0.42, size.height * 0.50, size.width * 0.41, size.height * 0.46, size.width * 0.41, size.height * 0.43)
        ..close();
    } else if (kind == 'braided') {
      path
        ..cubicTo(size.width * 0.47, size.height * 0.50, size.width * 0.47, size.height * 0.60, size.width * 0.45, size.height * 0.73)
        ..cubicTo(size.width * 0.42, size.height * 0.66, size.width * 0.41, size.height * 0.55, size.width * 0.41, size.height * 0.44)
        ..close();
      for (final y in [0.50, 0.58, 0.66, 0.74]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(size.width * 0.44, size.height * y),
            width: size.width * 0.036,
            height: size.height * 0.042,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.18),
        );
      }
    } else if (kind == 'long_curly') {
      path
        ..cubicTo(size.width * 0.49, size.height * 0.50, size.width * 0.49, size.height * 0.66, size.width * 0.47, size.height * 0.83)
        ..cubicTo(size.width * 0.42, size.height * 0.75, size.width * 0.40, size.height * 0.61, size.width * 0.40, size.height * 0.45)
        ..close();
      final curlPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10;
      for (final dy in [0.61, 0.71, 0.80]) {
        final curl = Path()
          ..moveTo(size.width * 0.45, size.height * dy)
          ..quadraticBezierTo(
            size.width * 0.50,
            size.height * (dy + 0.035),
            size.width * 0.45,
            size.height * (dy + 0.075),
          );
        canvas.drawPath(curl, curlPaint);
      }
    } else if (kind == 'medium') {
      path
        ..cubicTo(size.width * 0.47, size.height * 0.50, size.width * 0.47, size.height * 0.60, size.width * 0.45, size.height * 0.69)
        ..cubicTo(size.width * 0.42, size.height * 0.64, size.width * 0.41, size.height * 0.54, size.width * 0.41, size.height * 0.44)
        ..close();
    } else {
      path
        ..cubicTo(size.width * 0.46, size.height * 0.49, size.width * 0.46, size.height * 0.57, size.width * 0.44, size.height * 0.63)
        ..cubicTo(size.width * 0.42, size.height * 0.59, size.width * 0.41, size.height * 0.51, size.width * 0.41, size.height * 0.43)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  void _paintTailNatural(Canvas canvas, ui.Size size) {
    _paintTail(canvas, size, full: false);
  }

  void _paintTailFull(Canvas canvas, ui.Size size) {
    _paintTail(canvas, size, full: true);
  }

  void _paintTail(Canvas canvas, ui.Size size, {required bool full}) {
    final paint = Paint()..color = const Color(0xFFD0D0D0);
    final path = Path()..moveTo(size.width * 0.77, size.height * 0.57);
    if (full) {
      path
        ..cubicTo(size.width * 0.86, size.height * 0.62, size.width * 0.86, size.height * 0.82, size.width * 0.80, size.height * 0.89)
        ..cubicTo(size.width * 0.74, size.height * 0.81, size.width * 0.74, size.height * 0.68, size.width * 0.76, size.height * 0.60)
        ..close();
    } else {
      path
        ..cubicTo(size.width * 0.84, size.height * 0.63, size.width * 0.84, size.height * 0.78, size.width * 0.79, size.height * 0.84)
        ..cubicTo(size.width * 0.75, size.height * 0.77, size.width * 0.75, size.height * 0.67, size.width * 0.76, size.height * 0.60)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  void _paintMarkingBlaze(Canvas canvas, ui.Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(size.width * 0.350, size.height * 0.34)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.44,
        size.width * 0.39,
        size.height * 0.57,
        size.width * 0.42,
        size.height * 0.76,
      )
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.70,
        size.width * 0.35,
        size.height * 0.54,
        size.width * 0.33,
        size.height * 0.38,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  void _paintMarkingStar(Canvas canvas, ui.Size size) {
    canvas.drawCircle(
      Offset(size.width * 0.352, size.height * 0.405),
      size.width * 0.015,
      Paint()..color = Colors.white,
    );
  }

  void _paintMarkingStripe(Canvas canvas, ui.Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.352, size.height * 0.47),
          width: size.width * 0.022,
          height: size.height * 0.28,
        ),
        const Radius.circular(12),
      ),
      Paint()..color = Colors.white,
    );
  }

  void _paintPatternDapple(Canvas canvas, ui.Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.28);
    for (final point in [
      Offset(size.width * 0.52, size.height * 0.58),
      Offset(size.width * 0.61, size.height * 0.57),
      Offset(size.width * 0.49, size.height * 0.67),
      Offset(size.width * 0.66, size.height * 0.69),
    ]) {
      canvas.drawCircle(point, size.width * 0.032, paint);
    }
  }

  void _paintSheen(Canvas canvas, ui.Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.35,
      size.height * 0.45,
      size.width * 0.44,
      size.height * 0.32,
    );
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x00FFF7CF),
          Color(0x66FFF7CF),
          Color(0x14FFD86E),
        ],
        stops: [0.2, 0.5, 0.85],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _paintEye(Canvas canvas, ui.Size size) {
    final iris = Paint()..color = const Color(0xFFD0D0D0);
    canvas.drawCircle(
      Offset(size.width * 0.372, size.height * 0.417),
      size.width * 0.011,
      iris,
    );
    canvas.drawCircle(
      Offset(size.width * 0.374, size.height * 0.415),
      size.width * 0.0035,
      Paint()..color = Colors.white.withValues(alpha: 0.92),
    );
  }
}
