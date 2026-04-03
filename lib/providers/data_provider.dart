import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

class GroceryItem {
  final String id;
  final String name;
  final String category;
  /// Current quantity shown to the user (may be scaled by servings).
  double qty;

  /// Base quantity at the list's [GroceryList.baseServings].
  /// Used to recalculate [qty] when servings change.
  final double baseQty;

  /// Display unit for the quantity, e.g. 'g', 'pcs', 'jar', 'to taste'.
  /// If 'to taste', quantity steppers and scaling are disabled.
  final String unit;
  final double price;
  bool isBought;

  GroceryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.qty,
    double? baseQty,
    this.unit = 'pcs',
    required this.price,
    this.isBought = false,
  }) : baseQty = baseQty ?? qty;

  bool get isToTaste => unit.trim().toLowerCase() == 'to taste';

  String get qtyLabel {
    if (isToTaste) return 'to taste';
    final q = qty;
    String number;
    if ((q - q.roundToDouble()).abs() < 0.0001) {
      number = q.round().toString();
    } else {
      number = q.toStringAsFixed(q < 10 ? 1 : 0);
    }
    final u = unit.trim();
    if (u.isEmpty || u == 'pcs') return number;
    return '$number$u';
  }
}

class PriceBookEntry {
  final String name;
  final double unitPrice;
  final String category;

  const PriceBookEntry({required this.name, required this.unitPrice, required this.category});

  Map<String, dynamic> toJson() => {'name': name, 'unitPrice': unitPrice, 'category': category};

  static PriceBookEntry? fromJson(Map<String, dynamic> json) {
    try {
      final name = (json['name'] as String?)?.trim() ?? '';
      final category = (json['category'] as String?)?.trim() ?? 'Other';
      final unitPriceRaw = json['unitPrice'];
      final unitPrice = unitPriceRaw is num ? unitPriceRaw.toDouble() : double.tryParse(unitPriceRaw?.toString() ?? '');
      if (name.isEmpty || unitPrice == null || unitPrice.isNaN || unitPrice.isInfinite || unitPrice < 0) return null;
      return PriceBookEntry(name: name, unitPrice: unitPrice, category: category.isEmpty ? 'Other' : category);
    } catch (_) {
      return null;
    }
  }
}

class GroceryList {
  final String id;
  final String title;
  final String date;
  final bool isShared;
  final bool isDone;
  final int baseServings;
  final int servings;
  final List<GroceryItem> items;
  final String owner;
  final List<String> collaborators;

  GroceryList({
    required this.id,
    required this.title,
    required this.date,
    required this.isShared,
    this.isDone = false,
    this.baseServings = 2,
    int? servings,
    required this.items,
    required this.owner,
    required this.collaborators,
  }) : servings = servings ?? baseServings;

  double get totalPrice => items.fold(0, (sum, item) => sum + (item.price * item.qty));
  double get boughtPrice => items.where((i) => i.isBought).fold(0, (sum, item) => sum + (item.price * item.qty));
  int get boughtCount => items.where((i) => i.isBought).length;
}

class DataProvider extends ChangeNotifier {
  String? _activeListId;

  // Using time-only IDs can collide when multiple items are created in a tight loop
  // (e.g. mapping a batch of quick-add inputs). Add a counter + random suffix.
  final Random _idRand = Random();
  int _idCounter = 0;

  /// Generates a highly collision-resistant ID for local-only entities.
  ///
  /// NOTE: We intentionally avoid external packages (uuid) per project guidance.
  String generateId() {
    _idCounter = (_idCounter + 1) & 0x7fffffff;
    final ts = DateTime.now().microsecondsSinceEpoch;
    final r = _idRand.nextInt(1 << 30);
    return '${ts}_${_idCounter}_$r';
  }

  static const _priceBookPrefsKey = 'price_book_v1';

  bool _priceBookLoaded = false;
  final Map<String, PriceBookEntry> _priceBook = {};

  // Dish templates are used for the (local-only) dish-to-list experience.
  // Once a backend/AI is connected, this can be replaced with a real generator.
  static const List<String> knownDishes = [
    'Spaghetti Carbonara',
    'Chicken Tikka Masala',
    'Avocado Toast',
    'Beef Stir Fry',
    'Quinoa Salad',
    'Lemon Garlic Butter Salmon',
    'Chicken Alfredo',
    'Chicken Noodle Soup',
    'Shrimp Tacos',
    'Veggie Fried Rice',
    'Greek Salad',
    'Pancakes',
  ];

  final List<GroceryList> _myLists = [
    GroceryList(
      id: '1',
      title: 'Weekly Groceries',
      date: 'Updated 2 hours ago',
      isShared: true,
      isDone: false,
      baseServings: 2,
      owner: 'me',
      collaborators: ['Sarah Miller'],
      items: [
        GroceryItem(id: '101', name: 'Organic Bananas', category: 'Produce', qty: 1.0, price: 2.50, unit: 'pcs'),
        GroceryItem(id: '102', name: 'Whole Milk', category: 'Eggs & Dairy', qty: 2.0, price: 3.90, unit: 'pcs'),
        GroceryItem(id: '103', name: 'Sourdough Bread', category: 'Bakery', qty: 1.0, price: 5.00, unit: 'pcs'),
        GroceryItem(id: '104', name: 'Avocados', category: 'Produce', qty: 3.0, price: 1.50, unit: 'pcs'),
        GroceryItem(id: '105', name: 'Greek Yogurt', category: 'Eggs & Dairy', qty: 1.0, price: 6.20, unit: 'pcs'),
        GroceryItem(id: '106', name: 'Sea Salt', category: 'Pantry', qty: 1.0, price: 3.20, unit: 'jar', isBought: true),
        GroceryItem(id: '107', name: 'Olive Oil', category: 'Pantry', qty: 1.0, price: 14.00, unit: 'btl', isBought: true),
      ],
    ),
    GroceryList(
      id: '2',
      title: 'Spaghetti Carbonara Night',
      date: 'Created yesterday',
      isShared: false,
      isDone: false,
      baseServings: 2,
      owner: 'me',
      collaborators: [],
      items: [
        GroceryItem(id: '201', name: 'Spaghetti', category: 'Pantry', qty: 400.0, baseQty: 400.0, unit: 'g', price: 0.005),
        GroceryItem(id: '202', name: 'Guanciale (or pancetta)', category: 'Meat', qty: 150.0, baseQty: 150.0, unit: 'g', price: 0.056),
        GroceryItem(id: '203', name: 'Pecorino Romano', category: 'Eggs & Dairy', qty: 90.0, baseQty: 90.0, unit: 'g', price: 0.075),
        GroceryItem(id: '204', name: 'Eggs', category: 'Eggs & Dairy', qty: 4.0, baseQty: 4.0, unit: 'pcs', price: 0.55),
        GroceryItem(id: '205', name: 'Black Pepper', category: 'Pantry', qty: 1.0, baseQty: 1.0, unit: 'jar', price: 2.50),
        GroceryItem(id: '206', name: 'Salt (for pasta water)', category: 'Pantry', qty: 1.0, baseQty: 1.0, unit: 'to taste', price: 0.00),
      ],
    ),
    GroceryList(
      id: '4',
      title: 'Last Week\'s Haul',
      date: 'Completed 3 days ago',
      isShared: false,
      isDone: true,
      baseServings: 2,
      owner: 'me',
      collaborators: [],
      items: [
        GroceryItem(id: '401', name: 'Apples', category: 'Produce', qty: 6.0, unit: 'pcs', price: 1.25, isBought: true),
        GroceryItem(id: '402', name: 'Coffee', category: 'Pantry', qty: 1.0, unit: 'bag', price: 9.50, isBought: true),
        GroceryItem(id: '403', name: 'Bread', category: 'Bakery', qty: 1.0, unit: 'loaf', price: 3.50, isBought: true),
      ],
    )
  ];

  final List<GroceryList> _sharedLists = [
    GroceryList(
      id: '3',
      title: 'Weekend BBQ Party',
      date: 'Updated 1 day ago',
      isShared: true,
      isDone: false,
      baseServings: 2,
      owner: 'Sarah Miller',
      collaborators: ['me'],
      items: [
        GroceryItem(id: '301', name: 'Burgers', category: 'Meat', qty: 12.0, unit: 'pcs', price: 1.50),
        GroceryItem(id: '302', name: 'Buns', category: 'Bakery', qty: 2.0, unit: 'bag', price: 3.00),
      ],
    )
  ];

  List<GroceryList> get myLists => _myLists;
  List<GroceryList> get sharedLists => _sharedLists;

  bool get priceBookLoaded => _priceBookLoaded;

  List<PriceBookEntry> get priceBookEntries {
    final list = _priceBook.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  PriceBookEntry? getPriceBookEntry(String name) => _priceBook[_normalizeName(name)];

  Future<void> ensurePriceBookLoaded() async {
    if (_priceBookLoaded) return;
    await _loadPriceBook();
  }

  GroceryList? get activeList {
    if (_activeListId == null) return null;
    for (final list in [..._myLists, ..._sharedLists]) {
      if (list.id == _activeListId) return list;
    }
    return null;
  }

  void setActiveList(String listId) {
    _activeListId = listId;
    notifyListeners();
  }

  GroceryItem createItemFromInput(String input) {
    final trimmed = input.trim();
    final id = generateId();
    if (trimmed.isEmpty) {
      return GroceryItem(id: id, name: 'Item', category: 'Other', qty: 1.0, unit: 'pcs', price: 0);
    }

    // Very lightweight parsing: "6 eggs" => qty=6, name="eggs"; "Avocados (3)" => qty=3
    final qtyParensMatch = RegExp(r'\((\d+)\)').firstMatch(trimmed);
    final leadingQtyMatch = RegExp(r'^(\d+)\s+').firstMatch(trimmed);
    final qtyRaw = int.tryParse(qtyParensMatch?.group(1) ?? leadingQtyMatch?.group(1) ?? '') ?? 1;
    final qty = qtyRaw < 1 ? 1 : qtyRaw;

    var name = trimmed;
    if (leadingQtyMatch != null) name = name.substring(leadingQtyMatch.group(0)!.length);
    name = name.replaceAll(RegExp(r'\s*\(\d+\)\s*'), '').trim();
    if (name.isEmpty) name = 'Item';

    final entry = getPriceBookEntry(name);
    final category = entry?.category ?? _inferCategory(name);
    final unitPrice = entry?.unitPrice ?? 0;
    return GroceryItem(id: id, name: name, category: category, qty: qty.toDouble(), unit: 'pcs', price: unitPrice);
  }

  // Mock Pairing Logic
  final String myPairingCode = 'SYNC-4829';
  final List<String> _pairedDevices = ['Partner\'s iPhone'];
  
  List<String> get pairedDevices => _pairedDevices;

  bool pairWithDevice(String code) {
    if (code.trim().isNotEmpty && code != myPairingCode) {
      if (!_pairedDevices.contains('Device $code')) {
        _pairedDevices.add('Device $code');
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  void syncListWithDevice(String listId, String deviceName) {
    // Simulated syncing logic
    debugPrint('Syncing list $listId with $deviceName');
    // We could update the 'isShared' property or add to collaborators
    for (var list in _myLists) {
      if (list.id == listId && !list.collaborators.contains(deviceName)) {
        list.collaborators.add(deviceName);
        notifyListeners();
      }
    }
  }

  void toggleItemBought(String listId, String itemId) {
    for (var list in [..._myLists, ..._sharedLists]) {
      if (list.id == listId) {
        for (var item in list.items) {
          if (item.id == itemId) {
            item.isBought = !item.isBought;
            notifyListeners();
            return;
          }
        }
      }
    }
  }

  void adjustItemQty(String listId, String itemId, int delta) {
    for (final list in [..._myLists, ..._sharedLists]) {
      if (list.id != listId) continue;
      final factor = list.servings / list.baseServings;
      for (int i = 0; i < list.items.length; i++) {
        final item = list.items[i];
        if (item.id != itemId) continue;
        if (item.isToTaste) return;

        final step = _qtyStepForUnit(item.unit);
        final next = _sanitizeQty(item.qty + (delta * step), item.unit);
        list.items[i] = GroceryItem(
          id: item.id,
          name: item.name,
          category: item.category,
          qty: next,
          baseQty: factor == 0 ? next : (next / factor),
          unit: item.unit,
          price: item.price,
          isBought: item.isBought,
        );
        notifyListeners();
        return;
      }
    }
  }

  void setItemQty(String listId, String itemId, double qty) {
    for (final list in [..._myLists, ..._sharedLists]) {
      if (list.id != listId) continue;
      final factor = list.servings / list.baseServings;
      for (int i = 0; i < list.items.length; i++) {
        final item = list.items[i];
        if (item.id != itemId) continue;
        if (item.isToTaste) return;

        final next = _sanitizeQty(qty, item.unit);
        list.items[i] = GroceryItem(
          id: item.id,
          name: item.name,
          category: item.category,
          qty: next,
          baseQty: factor == 0 ? next : (next / factor),
          unit: item.unit,
          price: item.price,
          isBought: item.isBought,
        );
        notifyListeners();
        return;
      }
    }
  }

  double _qtyStepForUnit(String unit) => switch (unit.trim().toLowerCase()) { 'g' => 50.0, 'kg' => 0.1, _ => 1.0 };

  double _sanitizeQty(double qty, String unit) {
    final step = _qtyStepForUnit(unit);
    var next = qty;
    if (next.isNaN || next.isInfinite) next = step;
    if (next < step) next = step;

    return switch (unit.trim().toLowerCase()) {
      'g' => ((next / 50.0).round() * 50.0).clamp(50.0, 999999.0),
      'kg' => ((next * 10.0).round() / 10.0).clamp(0.1, 999999.0),
      _ => next.roundToDouble().clamp(1.0, 999999.0),
    };
  }

  void setListServings(String listId, int servings) {
    if (servings < 1) return;
    GroceryList? current;
    bool isMine = false;
    int idx = -1;

    idx = _myLists.indexWhere((l) => l.id == listId);
    if (idx != -1) {
      current = _myLists[idx];
      isMine = true;
    } else {
      idx = _sharedLists.indexWhere((l) => l.id == listId);
      if (idx != -1) current = _sharedLists[idx];
    }
    if (current == null) return;
    if (current.servings == servings) return;

    final factor = servings / current.baseServings;
    for (final item in current.items) {
      if (item.isToTaste) continue;
      item.qty = (item.baseQty * factor);
    }

    final updated = GroceryList(
      id: current.id,
      title: current.title,
      date: current.date,
      isShared: current.isShared,
      isDone: current.isDone,
      baseServings: current.baseServings,
      servings: servings,
      items: current.items,
      owner: current.owner,
      collaborators: current.collaborators,
    );

    if (isMine) {
      _myLists[idx] = updated;
    } else {
      _sharedLists[idx] = updated;
    }
    notifyListeners();
  }

  void removeItem(String listId, String itemId) {
    for (var list in [..._myLists, ..._sharedLists]) {
      if (list.id == listId) {
        list.items.removeWhere((item) => item.id == itemId);
        notifyListeners();
        return;
      }
    }
  }

  void addList(GroceryList list) {
    _myLists.insert(0, list);
    _activeListId ??= list.id;
    notifyListeners();
  }

  void addSharedList(GroceryList list) {
    _sharedLists.insert(0, list);
    notifyListeners();
  }

  void removeList(String listId) {
    _myLists.removeWhere((l) => l.id == listId);
    _sharedLists.removeWhere((l) => l.id == listId);
    if (_activeListId == listId) {
      _activeListId = _myLists.isNotEmpty ? _myLists.first.id : null;
    }
    notifyListeners();
  }

  void renameList(String listId, String newTitle) {
    for (final list in [..._myLists, ..._sharedLists]) {
      if (list.id == listId) {
        // GroceryList.title is final, so we need to replace the list
        final index = _myLists.indexWhere((l) => l.id == listId);
        if (index != -1) {
          _myLists[index] = GroceryList(
            id: list.id,
            title: newTitle,
            date: list.date,
            isShared: list.isShared,
            isDone: list.isDone,
            baseServings: list.baseServings,
            servings: list.servings,
            items: list.items,
            owner: list.owner,
            collaborators: list.collaborators,
          );
        }
        final sIndex = _sharedLists.indexWhere((l) => l.id == listId);
        if (sIndex != -1) {
          _sharedLists[sIndex] = GroceryList(
            id: list.id,
            title: newTitle,
            date: list.date,
            isShared: list.isShared,
            isDone: list.isDone,
            baseServings: list.baseServings,
            servings: list.servings,
            items: list.items,
            owner: list.owner,
            collaborators: list.collaborators,
          );
        }
        notifyListeners();
        return;
      }
    }
  }

  void markListDone(String listId) {
    bool updated = false;

    final index = _myLists.indexWhere((l) => l.id == listId);
    if (index != -1) {
      final list = _myLists[index];
      if (!list.isDone) {
        _myLists[index] = GroceryList(
          id: list.id,
          title: list.title,
          date: list.date,
          isShared: list.isShared,
          isDone: true,
          baseServings: list.baseServings,
          servings: list.servings,
          items: list.items,
          owner: list.owner,
          collaborators: list.collaborators,
        );
        updated = true;
      }
    }

    final sIndex = _sharedLists.indexWhere((l) => l.id == listId);
    if (sIndex != -1) {
      final list = _sharedLists[sIndex];
      if (!list.isDone) {
        _sharedLists[sIndex] = GroceryList(
          id: list.id,
          title: list.title,
          date: list.date,
          isShared: list.isShared,
          isDone: true,
          baseServings: list.baseServings,
          servings: list.servings,
          items: list.items,
          owner: list.owner,
          collaborators: list.collaborators,
        );
        updated = true;
      }
    }

    if (updated) notifyListeners();
  }

  void addItemToList(String listId, GroceryItem item) {
    for (final list in [..._myLists, ..._sharedLists]) {
      if (list.id == listId) {
        list.items.add(item);
        notifyListeners();
        return;
      }
    }
  }

  void addItemsToList(String listId, List<GroceryItem> items) {
    for (final list in [..._myLists, ..._sharedLists]) {
      if (list.id == listId) {
        list.items.addAll(items);
        notifyListeners();
        return;
      }
    }
  }

  void reAddItem(String listId, GroceryItem item, int index) {
    for (final list in [..._myLists, ..._sharedLists]) {
      if (list.id == listId) {
        final clampedIndex = index.clamp(0, list.items.length);
        list.items.insert(clampedIndex, item);
        notifyListeners();
        return;
      }
    }
  }

  Future<void> upsertPriceBookEntry({required String name, required double unitPrice, String? category}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final normalized = _normalizeName(trimmed);
    final resolvedCategory = (category ?? _inferCategory(trimmed)).trim();
    _priceBook[normalized] = PriceBookEntry(name: trimmed, unitPrice: unitPrice, category: resolvedCategory.isEmpty ? 'Other' : resolvedCategory);
    await _persistPriceBook();
    notifyListeners();
  }

  Future<void> removePriceBookEntry(String name) async {
    _priceBook.remove(_normalizeName(name));
    await _persistPriceBook();
    notifyListeners();
  }

  Future<void> _loadPriceBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_priceBookPrefsKey);
      _priceBook.clear();

      if (rawList == null || rawList.isEmpty) {
        for (final e in _defaultPriceBook()) {
          _priceBook[_normalizeName(e.name)] = e;
        }
        await _persistPriceBook();
      } else {
        bool hadInvalid = false;
        for (final raw in rawList) {
          try {
            final json = Map<String, dynamic>.from(_decodeJsonToMap(raw));
            final entry = PriceBookEntry.fromJson(json);
            if (entry == null) {
              hadInvalid = true;
              continue;
            }
            _priceBook[_normalizeName(entry.name)] = entry;
          } catch (e) {
            hadInvalid = true;
            debugPrint('Failed to decode price book entry: $e');
          }
        }

        if (_priceBook.isEmpty) {
          for (final e in _defaultPriceBook()) {
            _priceBook[_normalizeName(e.name)] = e;
          }
        }

        if (hadInvalid) {
          await _persistPriceBook();
        }
      }
    } catch (e) {
      debugPrint('Failed to load price book: $e');
      _priceBook
        ..clear()
        ..addEntries(_defaultPriceBook().map((e) => MapEntry(_normalizeName(e.name), e)));
    } finally {
      _priceBookLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persistPriceBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = _priceBook.values.map((e) => _encodeMapToJson(e.toJson())).toList();
      await prefs.setStringList(_priceBookPrefsKey, raw);
    } catch (e) {
      debugPrint('Failed to persist price book: $e');
    }
  }

  static String _normalizeName(String name) => name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _inferCategory(String name) {
    final key = name.toLowerCase();
    if (key.contains('egg')) return 'Eggs & Dairy';
    if (key.contains('milk') || key.contains('yogurt') || key.contains('cheese') || key.contains('butter')) return 'Eggs & Dairy';
    if (key.contains('bread') || key.contains('bun') || key.contains('bagel') || key.contains('tortilla')) return 'Bakery';
    if (key.contains('chicken') || key.contains('beef') || key.contains('pork') || key.contains('bacon') || key.contains('sausage')) return 'Meat';
    if (key.contains('salmon') || key.contains('shrimp') || key.contains('fish')) return 'Seafood';
    if (key.contains('apple') || key.contains('avocado') || key.contains('banana') || key.contains('tomato') || key.contains('onion') || key.contains('garlic') || key.contains('spinach') || key.contains('broccoli') || key.contains('pepper') || key.contains('cilantro') || key.contains('parsley') || key.contains('lemon') || key.contains('lime')) return 'Produce';
    if (key.contains('rice') || key.contains('pasta') || key.contains('oil') || key.contains('salt') || key.contains('pepper') || key.contains('sauce') || key.contains('coffee') || key.contains('flour')) return 'Pantry';
    return 'Other';
  }

  static List<PriceBookEntry> _defaultPriceBook() => const [
        PriceBookEntry(name: 'Apples', unitPrice: 1.25, category: 'Produce'),
        PriceBookEntry(name: 'Avocados', unitPrice: 1.50, category: 'Produce'),
        PriceBookEntry(name: 'Bananas', unitPrice: 2.50, category: 'Produce'),
        PriceBookEntry(name: 'Garlic', unitPrice: 0.90, category: 'Produce'),
        PriceBookEntry(name: 'Onions', unitPrice: 1.10, category: 'Produce'),
        PriceBookEntry(name: 'Tomatoes', unitPrice: 2.30, category: 'Produce'),
        PriceBookEntry(name: 'Spinach', unitPrice: 2.80, category: 'Produce'),
        PriceBookEntry(name: 'Whole Milk', unitPrice: 3.90, category: 'Eggs & Dairy'),
        PriceBookEntry(name: 'Milk', unitPrice: 3.90, category: 'Eggs & Dairy'),
        PriceBookEntry(name: 'Eggs', unitPrice: 4.65, category: 'Eggs & Dairy'),
        PriceBookEntry(name: 'Butter', unitPrice: 4.50, category: 'Eggs & Dairy'),
        PriceBookEntry(name: 'Greek Yogurt', unitPrice: 6.20, category: 'Eggs & Dairy'),
        PriceBookEntry(name: 'Sourdough Bread', unitPrice: 5.00, category: 'Bakery'),
        PriceBookEntry(name: 'Bread', unitPrice: 3.50, category: 'Bakery'),
        PriceBookEntry(name: 'Pasta', unitPrice: 2.00, category: 'Pantry'),
        PriceBookEntry(name: 'Rice', unitPrice: 4.20, category: 'Pantry'),
        PriceBookEntry(name: 'Olive Oil', unitPrice: 14.00, category: 'Pantry'),
        PriceBookEntry(name: 'Sea Salt', unitPrice: 3.20, category: 'Pantry'),
        PriceBookEntry(name: 'Coffee', unitPrice: 9.50, category: 'Pantry'),
      ];

  /// Creates a new list from a dish name (local templates).
  ///
  /// This is intentionally deterministic and offline so the user can
  /// explore the UI without any backend connected.
  GroceryList createListFromDish({required String dishName, bool useSmartAi = true}) {
    final normalized = dishName.trim();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final items = _itemsForDish(normalized, useSmartAi: useSmartAi);
    final list = GroceryList(
      id: id,
      title: normalized.isEmpty ? 'Dish List' : normalized,
      date: 'Just now',
      isShared: false,
      isDone: false,
      baseServings: 2,
      owner: 'me',
      collaborators: [],
      items: items,
    );
    addList(list);
    setActiveList(id);
    return list;
  }

  List<GroceryItem> _itemsForDish(String dishName, {required bool useSmartAi}) {
    final key = dishName.toLowerCase();
    final base = <GroceryItem>[];
    void add(String name, String category, double qty, double price, {String unit = 'pcs', bool toTaste = false}) {
      base.add(GroceryItem(
        id: '${dishName.hashCode}-${name.hashCode}-${base.length}',
        name: name,
        category: category,
        qty: qty,
        baseQty: qty,
        unit: toTaste ? 'to taste' : unit,
        price: price,
      ));
    }

    if (key.contains('carbonara')) {
      // Offline “expert” defaults for 2 servings.
      add('Spaghetti', 'Pantry', 400, 0.005, unit: 'g');
      add('Guanciale (or pancetta)', 'Meat', 150, 0.056, unit: 'g');
      add('Pecorino Romano', 'Eggs & Dairy', 90, 0.075, unit: 'g');
      add('Eggs', 'Eggs & Dairy', 4, 0.55, unit: 'pcs');
      add('Black Pepper', 'Pantry', 1, 2.50, unit: 'jar');
      add('Salt (for pasta water)', 'Pantry', 1, 0.00, toTaste: true);
    } else if (key.contains('tikka') || key.contains('masala')) {
      add('Chicken thighs', 'Meat', 2, 9.50, unit: 'pcs');
      add('Tikka masala simmer sauce', 'Pantry', 1, 4.75, unit: 'jar');
      add('Basmati rice', 'Pantry', 1, 4.20, unit: 'bag');
      add('Greek yogurt', 'Eggs & Dairy', 1, 6.20, unit: 'tub');
      add('Cilantro', 'Produce', 1, 1.50, unit: 'bunch');
    } else if (key.contains('avocado toast')) {
      add('Sourdough bread', 'Bakery', 1, 5.00, unit: 'loaf');
      add('Avocados', 'Produce', 3, 1.50, unit: 'pcs');
      add('Lemon', 'Produce', 1, 0.90, unit: 'pcs');
      add('Chili flakes', 'Pantry', 1, 3.00, unit: 'jar');
      add('Sea salt', 'Pantry', 1, 3.20, unit: 'jar');
    } else if (key.contains('stir fry')) {
      add('Broccoli', 'Produce', 1, 2.25, unit: 'head');
      add('Bell peppers', 'Produce', 3, 1.25, unit: 'pcs');
      add('Garlic', 'Produce', 1, 0.90, unit: 'bulb');
      add('Soy sauce', 'Pantry', 1, 3.75, unit: 'btl');
      add('Beef strips', 'Meat', 1, 10.50, unit: 'pkg');
    } else if (key.contains('salmon')) {
      add('Salmon fillets', 'Seafood', 2, 10.00, unit: 'pcs');
      add('Butter', 'Eggs & Dairy', 1, 4.50, unit: 'pack');
      add('Garlic', 'Produce', 1, 0.90, unit: 'bulb');
      add('Lemons', 'Produce', 2, 0.90, unit: 'pcs');
      add('Parsley', 'Produce', 1, 1.50, unit: 'bunch');
    } else {
      // Generic fallback: still feels “smart”, but stays offline.
      add('Olive oil', 'Pantry', 1, 14.00, unit: 'btl');
      add('Garlic', 'Produce', 1, 0.90, unit: 'bulb');
      add('Lemon', 'Produce', 1, 0.90, unit: 'pcs');
      add('Salt', 'Pantry', 1, 1.50, unit: 'jar');
      add('Black pepper', 'Pantry', 1, 2.50, unit: 'jar');
      if (useSmartAi) {
        add('Fresh herbs (optional)', 'Produce', 1, 2.50, unit: 'bunch');
      }
    }
    return base;
  }
}

Map<String, dynamic> _decodeJsonToMap(String raw) {
  // Intentionally minimal JSON codec to keep dependencies low.
  // The stored format is produced by _encodeMapToJson.
  final map = <String, dynamic>{};
  final trimmed = raw.trim();
  if (!trimmed.startsWith('{') || !trimmed.endsWith('}')) return map;
  final body = trimmed.substring(1, trimmed.length - 1);
  if (body.trim().isEmpty) return map;

  final parts = <String>[];
  final sb = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < body.length; i++) {
    final ch = body[i];
    if (ch == '"' && (i == 0 || body[i - 1] != '\\')) inQuotes = !inQuotes;
    if (ch == ',' && !inQuotes) {
      parts.add(sb.toString());
      sb.clear();
    } else {
      sb.write(ch);
    }
  }
  if (sb.isNotEmpty) parts.add(sb.toString());

  for (final part in parts) {
    final idx = part.indexOf(':');
    if (idx <= 0) continue;
    final key = part.substring(0, idx).trim();
    final value = part.substring(idx + 1).trim();
    final k = _unquote(key);
    if (k.isEmpty) continue;
    if (value.startsWith('"')) {
      map[k] = _unquote(value);
    } else {
      map[k] = num.tryParse(value) ?? value;
    }
  }
  return map;
}

String _encodeMapToJson(Map<String, dynamic> map) {
  String esc(String s) => s.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  final entries = map.entries.map((e) {
    final key = '"${esc(e.key)}"';
    final v = e.value;
    if (v is num) return '$key:${v.toString()}';
    return '$key:"${esc(v.toString())}"';
  }).join(',');
  return '{$entries}';
}

String _unquote(String s) {
  final t = s.trim();
  if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
    return t.substring(1, t.length - 1).replaceAll('\\"', '"').replaceAll('\\\\', '\\');
  }
  return t;
}
