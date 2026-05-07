import '../../domain/models/horse.dart';
import '../../domain/models/horse_trait_defaults.dart';
import '../../domain/models/render_layer.dart';

class HorseRendererService {
  const HorseRendererService();

  static const String _assetRoot = 'assets/horses/compiled';

  List<RenderLayer> buildLayers(Horse horse, {String? tailStyleOverride}) {
    horse = normalizeHorseVisibleTraits(horse);
    final eyeVariant = _eyeVariant(horse);
    final breedVariant = _breedVariant(horse);
    final maneVariant = _maneVariant(horse);
    final tailVariant = _tailVariant(horse, styleOverride: tailStyleOverride);
    final saddleVariant = _saddleVariant(horse);
    final maneAboveBody =
        maneVariant.startsWith('mane_natural_') ||
        maneVariant.startsWith('mane_short_');

    final layers = <RenderLayer>[
      RenderLayer(
        slot: 'eye',
        label: eyeVariant,
        assetPath: '$_assetRoot/eyes/$eyeVariant.png',
      ),
      RenderLayer(
        slot: 'tail',
        label: tailVariant,
        assetPath: '$_assetRoot/tail/$tailVariant.png',
      ),
      if (!maneAboveBody)
        RenderLayer(
          slot: 'mane',
          label: maneVariant,
          assetPath: '$_assetRoot/mane/$maneVariant.png',
        ),
      RenderLayer(
        slot: 'body',
        label: breedVariant,
        assetPath: '$_assetRoot/breed/$breedVariant.png',
      ),
      if (saddleVariant != null)
        RenderLayer(
          slot: 'saddle',
          label: saddleVariant,
          assetPath: '$_assetRoot/saddle/$saddleVariant.png',
        ),
      if (maneAboveBody)
        RenderLayer(
          slot: 'mane',
          label: maneVariant,
          assetPath: '$_assetRoot/mane/$maneVariant.png',
        ),
    ];

    return layers;
  }

  String _breedVariant(Horse horse) {
    final breed = horse.breed.toLowerCase();
    final bodyType = horse.traitOption('body_type', fallback: '').toLowerCase();
    final markings = horse.traitOption('markings', fallback: '').toLowerCase();

    if (breed.contains('arabian')) {
      return 'horse_arabian';
    }
    if (breed.contains('appaloosa')) {
      return 'horse_appaloosa';
    }
    if (breed.contains('paint') ||
        breed.contains('painted') ||
        markings == 'pinto') {
      return 'horse_painted';
    }
    if (breed == 'bay' ||
        breed.contains('bay brown') ||
        breed.contains('starter stock')) {
      return 'horse_bay';
    }
    if (breed.contains('shetland') || bodyType == 'compact') {
      return 'horse_shetland_pony';
    }
    if (breed.contains('percheron')) {
      return 'horse_percheron';
    }
    if (bodyType == 'hefty') {
      return 'horse_percheron';
    }

    return 'horse_bay';
  }

  String _eyeVariant(Horse horse) {
    final option = horse
        .traitOption('eye_color', fallback: 'Brown')
        .toLowerCase();
    if (option == 'heterochromia') {
      return 'eye_heterochromia';
    }

    return switch (option) {
      'blue' => 'eye_blue',
      'hazel' => 'eye_hazel',
      'green' => 'eye_green',
      _ => 'eye_brown',
    };
  }

  String _maneVariant(Horse horse) {
    final style = _normalizedManeStyle(horse);
    final color = _normalizedHairColor(
      horse,
      traitType: 'mane_color',
      fallback: _defaultHairColor(horse),
    );
    return 'mane_${style}_$color';
  }

  String _tailVariant(Horse horse, {String? styleOverride}) {
    final style = _normalizedTailStyle(horse, override: styleOverride);
    final color = _normalizedHairColor(
      horse,
      traitType: 'tail_color',
      fallback: _defaultHairColor(horse),
    );
    return 'tail_${style}_$color';
  }

  String? _saddleVariant(Horse horse) {
    if (!_shouldDisplayInheritedSaddle(horse)) {
      return null;
    }

    final option = horse.traitOfOrNull('saddle')?.option.toLowerCase();
    return switch (option) {
      'black' => 'saddle_black',
      'red' => 'saddle_red',
      'sandy' => 'saddle_sandy',
      'silver' => 'saddle_silver',
      _ => null,
    };
  }

  bool _shouldDisplayInheritedSaddle(Horse horse) {
    if (horse.traitOfOrNull('saddle') == null) {
      return false;
    }

    // Keep foundation starter horses visually unchanged, but show saddle once
    // the trait appears in an inherited line such as a foal.
    final isFoundationStarter =
        horse.generation <= 1 &&
        horse.damSnapshot == null &&
        horse.sireSnapshot == null;
    return !isFoundationStarter;
  }

  String _normalizedManeStyle(Horse horse) {
    final option = horse
        .traitOption('mane_style', fallback: 'Natural')
        .toLowerCase();
    return switch (option) {
      'short' => 'short',
      'braided' => 'braided',
      'hawk' => 'hawk',
      _ => 'natural',
    };
  }

  String _normalizedTailStyle(Horse horse, {String? override}) {
    final option =
        (override ?? horse.traitOption('tail_style', fallback: 'Natural'))
            .toLowerCase();
    return switch (option) {
      'short' => 'short',
      'braided' => 'braided',
      'curly' => 'curly',
      _ => 'natural',
    };
  }

  String _normalizedHairColor(
    Horse horse, {
    required String traitType,
    required String fallback,
  }) {
    final option = horse
        .traitOption(traitType, fallback: fallback)
        .toLowerCase();
    return switch (option) {
      'black' => 'black',
      'white' => 'white',
      _ => 'brown',
    };
  }

  String _defaultHairColor(Horse horse) {
    final breed = horse.breed.toLowerCase();
    if (breed.contains('percheron')) {
      return 'Black';
    }
    if (breed.contains('arabian')) {
      return 'White';
    }
    return 'Brown';
  }
}
