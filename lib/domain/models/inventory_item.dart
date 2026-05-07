enum InventoryItemType { prenatalVitamin, carrot }

class InventoryItemStack {
  const InventoryItemStack({required this.type, required this.quantity});

  final InventoryItemType type;
  final int quantity;

  InventoryItemStack copyWith({int? quantity}) {
    return InventoryItemStack(type: type, quantity: quantity ?? this.quantity);
  }
}

class StoreItem {
  const StoreItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.assetPath,
    required this.price,
    required this.quantity,
    this.type,
    this.expansionTier,
  });

  final String id;
  final String title;
  final String subtitle;
  final String description;
  final String assetPath;
  final int price;
  final int quantity;
  final InventoryItemType? type;
  final int? expansionTier;

  bool get isExpansion => expansionTier != null;
}

class StoreCatalog {
  static const List<StoreItem> items = [
    StoreItem(
      id: 'prenatal_single',
      title: 'Prenatal Vitamin',
      subtitle: 'Single tablet',
      description:
          'Cuts one active pregnancy timer in half. Only one prenatal vitamin can be used per pregnancy.',
      assetPath: 'assets/items/prenatal_single.png',
      price: 350,
      quantity: 1,
      type: InventoryItemType.prenatalVitamin,
    ),
    StoreItem(
      id: 'prenatal_bundle_5',
      title: 'Prenatal Vitamin Pack',
      subtitle: 'Bundle of 5',
      description:
          'Five pregnancy timer boosts for active mares. Each pregnancy accepts only one tablet.',
      assetPath: 'assets/items/prenatal_bundle_5.png',
      price: 1500,
      quantity: 5,
      type: InventoryItemType.prenatalVitamin,
    ),
    StoreItem(
      id: 'carrot_single',
      title: 'Pivot Carrot',
      subtitle: 'Single use',
      description:
          'Cuts one active stallion recovery cooldown in half. Only one carrot can be used per cooldown stage.',
      assetPath: 'assets/items/carrot_single.png',
      price: 180,
      quantity: 1,
      type: InventoryItemType.carrot,
    ),
    StoreItem(
      id: 'carrot_bundle_5',
      title: 'Baby Carrots',
      subtitle: '5 uses',
      description:
          'A small pack of cooldown treats for stallions recovering after breeding.',
      assetPath: 'assets/items/carrot_bundle_5.png',
      price: 800,
      quantity: 5,
      type: InventoryItemType.carrot,
    ),
    StoreItem(
      id: 'carrot_bundle_10',
      title: 'Premium Carrot Bundle',
      subtitle: '10 uses',
      description:
          'A full bundle for busy breeding lines. Each cooldown stage can only receive one carrot.',
      assetPath: 'assets/items/carrot_bundle_10.png',
      price: 1450,
      quantity: 10,
      type: InventoryItemType.carrot,
    ),
    StoreItem(
      id: 'stable_expansion_25',
      title: 'Stable Expansion • Tier 1',
      subtitle: 'Monthly tier • 10 to 25 horse slots',
      description:
          'Unlocks the first monthly stable capacity tier and raises your stable to 25 horse slots.',
      assetPath: 'assets/items/stable_expansion.png',
      price: 2500,
      quantity: 1,
      expansionTier: 1,
    ),
    StoreItem(
      id: 'stable_expansion_50',
      title: 'Stable Expansion • Tier 2',
      subtitle: 'Monthly tier • 25 to 50 horse slots',
      description:
          'Unlocks after Tier 1 is purchased, then raises your monthly stable capacity to 50 horse slots.',
      assetPath: 'assets/items/stable_expansion.png',
      price: 6000,
      quantity: 1,
      expansionTier: 2,
    ),
  ];

  static StoreItem byId(String id) {
    return items.firstWhere((item) => item.id == id);
  }
}

String inventoryItemTypeKey(InventoryItemType type) {
  return switch (type) {
    InventoryItemType.prenatalVitamin => 'prenatalVitamin',
    InventoryItemType.carrot => 'carrot',
  };
}

InventoryItemType? inventoryItemTypeFromKey(String key) {
  return switch (key) {
    'prenatalVitamin' => InventoryItemType.prenatalVitamin,
    'carrot' => InventoryItemType.carrot,
    _ => null,
  };
}
