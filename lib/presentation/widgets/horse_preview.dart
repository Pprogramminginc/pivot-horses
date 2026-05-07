import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../../domain/models/horse.dart';
import '../../domain/models/render_layer.dart';
import '../../logic/services/horse_renderer_service.dart';

class HorsePreview extends StatelessWidget {
  const HorsePreview({
    super.key,
    required this.horse,
    this.compact = false,
    this.naturalStage = false,
    this.forceStatic = false,
    this.tailStyleVisualOverride,
    this.verticalOffsetOverride,
    this.cameraTargetOverride,
  });

  final Horse horse;
  final bool compact;
  final bool naturalStage;
  final bool forceStatic;
  final String? tailStyleVisualOverride;
  final double? verticalOffsetOverride;
  final String? cameraTargetOverride;

  @override
  Widget build(BuildContext context) {
    final theme = _HorsePreviewTheme.fromHorse(
      horse,
      naturalStage: naturalStage,
    );
    final layers = const HorseRendererService().buildLayers(
      horse,
      tailStyleOverride: tailStyleVisualOverride,
    );
    final showPreviewBadges = !compact && !_hidePreviewBadges(horse);
    final previewAccent = _previewAccentLabel(horse);

    return AspectRatio(
      aspectRatio: compact ? 1.08 : 1.1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 24 : 32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _HorseStagePainter(compact: compact, theme: theme),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 12 : 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(compact ? 20 : 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: compact ? 0.04 : 0.06,
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: compact ? 0.08 : 0.12,
                      ),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        left: compact ? 22 : 26,
                        right: compact ? 22 : 26,
                        bottom: compact ? 18 : 24,
                        height: compact ? 28 : 36,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.floorColor.withValues(
                                  alpha: compact ? 0.08 : 0.12,
                                ),
                                theme.floorColor.withValues(
                                  alpha: compact ? 0.26 : 0.34,
                                ),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      if (showPreviewBadges)
                        Positioned(
                          left: 16,
                          right: 16,
                          top: 14,
                          child: Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _PreviewBadge(
                                    label: horse.breed,
                                    color: theme.coatBadgeColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _PreviewBadge(
                                label: previewAccent,
                                color: theme.eyeGlow,
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          compact ? 6 : 12,
                          compact ? 10 : 28,
                          compact ? 6 : 12,
                          compact ? 10 : 20,
                        ),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: compact ? 332 : 380,
                            height: compact ? 302 : 346,
                            child: Transform.translate(
                              offset: Offset(0, verticalOffsetOverride ?? 0),
                              child: _HorseLayeredArt(layers: layers),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorseLayeredArt extends StatelessWidget {
  const _HorseLayeredArt({required this.layers});

  final List<RenderLayer> layers;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (final layer in layers)
            Opacity(
              opacity: layer.opacity,
              child: Image.asset(
                layer.assetPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}

String _previewAccentLabel(Horse horse) {
  final eye = horse.traitOption('eye_color', fallback: 'Brown');
  if (eye != 'Brown') {
    return eye;
  }
  final maneColor = horse.traitOption('mane_color', fallback: 'Brown');
  return '$maneColor ${horse.traitOption('mane_style', fallback: horse.breed)}';
}

bool _hidePreviewBadges(Horse horse) {
  return false;
}

class _HorseStagePainter extends CustomPainter {
  const _HorseStagePainter({required this.compact, required this.theme});

  final bool compact;
  final _HorsePreviewTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(compact ? 24 : 32),
    );
    canvas.drawRRect(
      outer,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: theme.outerGradient,
        ).createShader(Offset.zero & size),
    );

    final framePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.22),
          Colors.white.withValues(alpha: 0.04),
          Colors.black.withValues(alpha: 0.18),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 2.2 : 2.8;
    canvas.drawRRect(outer.deflate(compact ? 1.4 : 1.8), framePaint);

    final backplateRect = Rect.fromLTWH(
      size.width * 0.10,
      size.height * 0.10,
      size.width * 0.80,
      size.height * 0.72,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        backplateRect,
        Radius.circular(compact ? 24 : 30),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.atmosphereColor.withValues(alpha: compact ? 0.26 : 0.34),
            theme.haloColor.withValues(alpha: compact ? 0.10 : 0.14),
            Colors.transparent,
          ],
        ).createShader(backplateRect),
    );

    final atmosphereRect = Rect.fromCenter(
      center: Offset(size.width * 0.52, size.height * 0.44),
      width: size.width * 0.86,
      height: size.height * 0.72,
    );
    canvas.drawOval(
      atmosphereRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            theme.atmosphereColor.withValues(alpha: compact ? 0.44 : 0.52),
            theme.atmosphereColor.withValues(alpha: compact ? 0.18 : 0.24),
            Colors.transparent,
          ],
        ).createShader(atmosphereRect),
    );

    final sunRect = Rect.fromCircle(
      center: Offset(size.width * 0.66, size.height * 0.30),
      radius: size.width * (compact ? 0.18 : 0.22),
    );
    canvas.drawCircle(
      sunRect.center,
      sunRect.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            theme.haloColor.withValues(alpha: compact ? 0.38 : 0.46),
            theme.haloColor.withValues(alpha: compact ? 0.14 : 0.18),
            Colors.transparent,
          ],
        ).createShader(sunRect),
    );

    final glowRect = Rect.fromCircle(
      center: Offset(size.width * 0.50, size.height * 0.40),
      radius: size.width * 0.30,
    );
    canvas.drawCircle(
      glowRect.center,
      glowRect.width / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            theme.glowColor.withValues(alpha: compact ? 0.42 : 0.50),
            Colors.transparent,
          ],
        ).createShader(glowRect),
    );

    final haloRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.45),
      width: size.width * 0.62,
      height: size.height * 0.40,
    );
    canvas.drawOval(
      haloRect,
      Paint()
        ..color = Colors.transparent
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 2.0 : 2.8
        ..shader = SweepGradient(
          colors: [
            theme.haloColor.withValues(alpha: 0.0),
            theme.haloColor.withValues(alpha: compact ? 0.70 : 0.80),
            theme.haloColor.withValues(alpha: 0.0),
            theme.glowColor.withValues(alpha: compact ? 0.55 : 0.68),
            theme.haloColor.withValues(alpha: 0.0),
          ],
        ).createShader(haloRect),
    );

    final leftBeamRect = Rect.fromLTWH(
      size.width * 0.06,
      size.height * 0.18,
      size.width * 0.22,
      size.height * 0.46,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(leftBeamRect, Radius.circular(compact ? 18 : 24)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.haloColor.withValues(alpha: compact ? 0.18 : 0.24),
            Colors.transparent,
          ],
        ).createShader(leftBeamRect),
    );

    final beamRect = Rect.fromLTWH(
      size.width * 0.16,
      size.height * 0.04,
      size.width * 0.52,
      size.height * 0.24,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(beamRect, Radius.circular(compact ? 20 : 26)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white.withValues(alpha: 0.24), Colors.transparent],
        ).createShader(beamRect),
    );

    final accentSweep = Path()
      ..moveTo(size.width * 0.08, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.56,
        size.width * 0.74,
        size.height * 0.62,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.64,
        size.width * 0.92,
        size.height * 0.58,
      );
    canvas.drawPath(
      accentSweep,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 2.6 : 3.4
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            theme.accentArcColor.withValues(alpha: 0.0),
            theme.accentArcColor.withValues(alpha: compact ? 0.62 : 0.74),
            theme.accentArcColor.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    final topSweep = Path()
      ..moveTo(size.width * 0.18, size.height * 0.16)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.06,
        size.width * 0.72,
        size.height * 0.18,
      );
    canvas.drawPath(
      topSweep,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 2.2 : 2.8
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            theme.haloColor.withValues(alpha: 0.0),
            theme.haloColor.withValues(alpha: compact ? 0.48 : 0.58),
            theme.haloColor.withValues(alpha: 0.0),
          ],
        ).createShader(Offset.zero & size),
    );

    final ground = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.10,
        size.height * 0.73,
        size.width * 0.80,
        size.height * 0.16,
      ),
      Radius.circular(compact ? 26 : 30),
    );
    canvas.drawRRect(
      ground,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.floorHighlightColor.withValues(alpha: compact ? 0.18 : 0.24),
            theme.floorColor.withValues(alpha: compact ? 0.44 : 0.58),
            theme.floorShadowColor.withValues(alpha: compact ? 0.62 : 0.76),
          ],
        ).createShader(ground.outerRect),
    );

    final platformRim = Rect.fromLTWH(
      size.width * 0.16,
      size.height * 0.745,
      size.width * 0.68,
      size.height * 0.028,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(platformRim, Radius.circular(compact ? 18 : 22)),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            theme.floorHighlightColor.withValues(alpha: compact ? 0.34 : 0.42),
            Colors.transparent,
          ],
        ).createShader(platformRim),
    );

    final reflectionRect = Rect.fromCenter(
      center: Offset(size.width * 0.50, size.height * 0.79),
      width: size.width * 0.48,
      height: size.height * 0.09,
    );
    canvas.drawOval(
      reflectionRect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            theme.sparkColor.withValues(alpha: compact ? 0.18 : 0.24),
            Colors.transparent,
          ],
        ).createShader(reflectionRect),
    );

    final particlePaint = Paint()..color = theme.sparkColor;
    for (final particle in theme.particles) {
      canvas.drawCircle(
        Offset(size.width * particle.dx, size.height * particle.dy),
        compact ? particle.radius * 0.7 : particle.radius,
        particlePaint
          ..color = theme.sparkColor.withValues(
            alpha: compact ? particle.alpha + 0.10 : particle.alpha + 0.14,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HorseStagePainter oldDelegate) {
    return oldDelegate.compact != compact || oldDelegate.theme != theme;
  }
}

class _HorsePreviewTheme {
  const _HorsePreviewTheme({
    required this.outerGradient,
    required this.innerGradient,
    required this.glowColor,
    required this.eyeGlow,
    required this.floorColor,
    required this.coatTint,
    required this.coatBadgeColor,
    required this.exposure,
    required this.atmosphereColor,
    required this.haloColor,
    required this.accentArcColor,
    required this.sparkColor,
    required this.particles,
    required this.floorHighlightColor,
    required this.floorShadowColor,
  });

  final List<Color> outerGradient;
  final List<Color> innerGradient;
  final Color glowColor;
  final Color eyeGlow;
  final Color floorColor;
  final Color coatTint;
  final Color coatBadgeColor;
  final double exposure;
  final Color atmosphereColor;
  final Color haloColor;
  final Color accentArcColor;
  final Color sparkColor;
  final List<_StageParticle> particles;
  final Color floorHighlightColor;
  final Color floorShadowColor;

  factory _HorsePreviewTheme.fromHorse(
    Horse horse, {
    bool naturalStage = false,
  }) {
    final eye = horse.traitOption('eye_color', fallback: 'Brown');
    final markings = horse.traitOption('markings', fallback: 'None');
    final bodyType = horse.traitOption('body_type', fallback: 'Athletic');
    final maneStyle = horse.traitOption('mane_style', fallback: 'Natural');
    final rarity = horse.visualRarity;
    final hasMetallicSheen = horse.specialTraits.any(
      (trait) => trait.toLowerCase() == 'metallic sheen',
    );
    final isMutant = horse.isMutant;
    final breed = horse.breed.toLowerCase();
    final coatTheme = switch (breed) {
      final b when b.contains('arabian') => (
        outer: [const Color(0xFF2A2440), const Color(0xFF11141E)],
        inner: [const Color(0xFF5C4A74), const Color(0xFF1A2432)],
        glow: const Color(0xFFB8E4FF),
        floor: const Color(0xCC262F46),
        tint: const Color(0xFFE9EEF5),
        badge: const Color(0xFF8FD6FF),
        exposure: 1.12,
      ),
      final b when b.contains('percheron') => (
        outer: [const Color(0xFF22242E), const Color(0xFF101218)],
        inner: [const Color(0xFF454B5F), const Color(0xFF1A1E28)],
        glow: const Color(0xFFC1CEDD),
        floor: const Color(0xCC252B39),
        tint: const Color(0xFF7C8591),
        badge: const Color(0xFFBFCFE3),
        exposure: 1.08,
      ),
      final b when b.contains('paint') || b.contains('appaloosa') => (
        outer: [const Color(0xFF3A2230), const Color(0xFF17111C)],
        inner: [const Color(0xFF6A3847), const Color(0xFF2A1A21)],
        glow: const Color(0xFFFFB56B),
        floor: const Color(0xCC4A2830),
        tint: const Color(0xFFD7AF82),
        badge: const Color(0xFFFFD08A),
        exposure: 1.12,
      ),
      final b when b.contains('bay') => (
        outer: [const Color(0xFF251B30), const Color(0xFF11131E)],
        inner: [const Color(0xFF4C2A46), const Color(0xFF172231)],
        glow: const Color(0xFFFFC857),
        floor: const Color(0xCC2E2842),
        tint: const Color(0xFFB97D4A),
        badge: const Color(0xFF59F0E4),
        exposure: 1.12,
      ),
      _ => (
        outer: [const Color(0xFF2A1C32), const Color(0xFF13111C)],
        inner: [const Color(0xFF4F2C49), const Color(0xFF18212F)],
        glow: const Color(0xFFFFE8B6),
        floor: const Color(0xCC31273C),
        tint: const Color(0xFFC29B6D),
        badge: const Color(0xFFFFC857),
        exposure: 1.1,
      ),
    };

    final stageTheme = switch ((
      breed,
      bodyType.toLowerCase(),
      isMutant,
      markings,
    )) {
      (_, _, true, _) => (
        atmosphere: const Color(0xFF62D7FF),
        halo: const Color(0xFFFF7AD9),
        arc: const Color(0xFFA4FFEA),
        spark: const Color(0xCCFFF2A8),
      ),
      (final b, _, _, _) when b.contains('arabian') => (
        atmosphere: const Color(0xFFE8F2FF),
        halo: const Color(0xFF8FD6FF),
        arc: const Color(0xFFFEF3C8),
        spark: const Color(0xB3FFFFFF),
      ),
      (final b, _, _, _) when b.contains('percheron') => (
        atmosphere: const Color(0xFF5A647C),
        halo: const Color(0xFFC7D2E6),
        arc: const Color(0xFF89A7D8),
        spark: const Color(0xB3D7E0FF),
      ),
      (final b, _, _, _) when b.contains('paint') => (
        atmosphere: const Color(0xFFFFC57A),
        halo: const Color(0xFFFF7B54),
        arc: const Color(0xFFFFF0B0),
        spark: const Color(0xCCFFF1C7),
      ),
      (final b, _, _, _) when b.contains('appaloosa') => (
        atmosphere: const Color(0xFFFFC770),
        halo: const Color(0xFFF47C48),
        arc: const Color(0xFFFFE3AE),
        spark: const Color(0xCCFFF6D8),
      ),
      (_, 'hefty', _, _) => (
        atmosphere: const Color(0xFF7C8591),
        halo: const Color(0xFFC7D2E6),
        arc: const Color(0xFF89A7D8),
        spark: const Color(0xB3D7E0FF),
      ),
      (_, 'compact', _, _) => (
        atmosphere: const Color(0xFFCDA8FF),
        halo: const Color(0xFF8D7CFF),
        arc: const Color(0xFFFFD36E),
        spark: const Color(0xCCF9E7FF),
      ),
      (_, _, _, 'Blaze') => (
        atmosphere: const Color(0xFFFFC57A),
        halo: const Color(0xFFFF7B54),
        arc: const Color(0xFFFFE3AE),
        spark: const Color(0xCCFFF1C7),
      ),
      (final b, _, _, _) when b.contains('shetland') => (
        atmosphere: const Color(0xFFCDA8FF),
        halo: const Color(0xFF8D7CFF),
        arc: const Color(0xFFFFD36E),
        spark: const Color(0xCCF9E7FF),
      ),
      _ => (
        atmosphere: coatTheme.glow,
        halo: rarity.valueColor,
        arc: coatTheme.badge,
        spark: switch (eye) {
          'Blue' => AppTheme.secondary,
          'Green' => const Color(0xCC92FFB8),
          'Hazel' => const Color(0xCCFFD89A),
          'Heterochromia' => const Color(0xCCB8EAFF),
          _ =>
            maneStyle == 'Braided'
                ? const Color(0xCCFFF0C8)
                : const Color(0xCCFFF4CF),
        },
      ),
    };

    final particles = naturalStage
        ? <_StageParticle>[
            _StageParticle(0.24, 0.26, 1.4, 0.08),
            _StageParticle(0.67, 0.22, 1.2, 0.07),
            _StageParticle(0.31, 0.61, 1.0, 0.05),
          ]
        : <_StageParticle>[
            _StageParticle(0.19, 0.22, 2.2, 0.18),
            _StageParticle(0.27, 0.31, 1.5, 0.22),
            _StageParticle(0.41, 0.17, 1.8, 0.26),
            _StageParticle(0.63, 0.25, 1.6, 0.20),
            _StageParticle(0.76, 0.20, 2.0, 0.16),
            _StageParticle(0.80, 0.33, 1.2, 0.18),
            _StageParticle(0.23, 0.64, 1.6, 0.12),
            _StageParticle(0.69, 0.58, 1.8, 0.12),
            if (isMutant) ...[
              _StageParticle(0.34, 0.27, 2.4, 0.34),
              _StageParticle(0.55, 0.21, 2.2, 0.30),
              _StageParticle(0.72, 0.42, 2.0, 0.28),
            ],
          ];

    final eyeGlow = switch (eye) {
      'Hazel' => const Color(0xFFF5C26B),
      'Green' => const Color(0xFF56E38A),
      'Blue' => AppTheme.secondary,
      'Heterochromia' => const Color(0xFF9FD6FF),
      _ => rarity.valueColor,
    };

    final naturalOuter = [const Color(0xFF6C5847), const Color(0xFF2B211B)];
    final naturalInner = [const Color(0xFFBEA58A), const Color(0xFF5D4A3D)];

    return _HorsePreviewTheme(
      outerGradient: naturalStage ? naturalOuter : coatTheme.outer,
      innerGradient: naturalStage ? naturalInner : coatTheme.inner,
      glowColor: hasMetallicSheen ? rarity.valueColor : coatTheme.glow,
      eyeGlow: eyeGlow,
      floorColor: naturalStage ? const Color(0xCC4E3D31) : coatTheme.floor,
      coatTint: coatTheme.tint,
      coatBadgeColor: naturalStage ? const Color(0xFFD9C2A2) : coatTheme.badge,
      exposure: coatTheme.exposure,
      atmosphereColor: hasMetallicSheen
          ? rarity.valueColor.withValues(alpha: 0.92)
          : (naturalStage ? const Color(0xFFE4D2BC) : stageTheme.atmosphere),
      haloColor: hasMetallicSheen
          ? rarity.valueColor
          : (naturalStage ? const Color(0xFFD2BEA4) : stageTheme.halo),
      accentArcColor: naturalStage ? const Color(0xFFB78A5A) : stageTheme.arc,
      sparkColor: naturalStage ? const Color(0x66F4E8D8) : stageTheme.spark,
      particles: particles,
      floorHighlightColor: naturalStage
          ? const Color(0xFFD9B98B)
          : Color.lerp(stageTheme.arc, Colors.white, 0.22)!,
      floorShadowColor: naturalStage
          ? const Color(0xFF2B211B)
          : Color.lerp(coatTheme.floor, Colors.black, 0.24)!,
    );
  }
}

class _StageParticle {
  const _StageParticle(this.dx, this.dy, this.radius, this.alpha);

  final double dx;
  final double dy;
  final double radius;
  final double alpha;
}

class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 148),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withValues(alpha: 0.38),
            color.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.72)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFFFFFBF5),
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 6),
          ],
        ),
      ),
    );
  }
}
