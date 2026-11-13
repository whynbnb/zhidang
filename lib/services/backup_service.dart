import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../models/comparison_group.dart';
import '../models/custom_unit.dart';
import '../models/product.dart';
import '../models/product_category.dart';
import '../models/supplier.dart';
import '../settings/app_settings.dart';
import 'category_store.dart';
import 'comparison_store.dart';
import 'data_revision.dart';
import 'storage_service.dart';
import 'supplier_store.dart';
import 'unit_store.dart';

/// Result of saving a backup file.
enum BackupExportResult { saved, cancelled }

class BackupPayload {
  const BackupPayload({
    required this.products,
    required this.suppliers,
    required this.units,
    required this.comparisons,
    this.categories = const [],
    this.unitRelations = const [],
    this.exportedAt,
    this.version = 1,
  });

  final int version;
  final DateTime? exportedAt;
  final List<Product> products;
  final List<Supplier> suppliers;
  final List<ProductCategory> categories;
  final List<CustomUnit> units;
  final List<UnitRelation> unitRelations;
  final List<ComparisonGroup> comparisons;
}

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  static const currentVersion = 1;
  final _storage = StorageService();

  Future<String> buildJson() async {
    final products = await _storage.loadProducts();
    final payload = {
      'version': currentVersion,
      'app': 'zhidang',
      'exportedAt': DateTime.now().toIso8601String(),
      'products': products.map((e) => e.toJson()).toList(),
      'suppliers':
          SupplierStore.instance.suppliers.map((e) => e.toJson()).toList(),
      'categories':
          CategoryStore.instance.categories.map((e) => e.toJson()).toList(),
      'units': UnitStore.instance.units.map((e) => e.toJson()).toList(),
      'unitRelations':
          UnitStore.instance.relations.map((e) => e.toJson()).toList(),
      'comparisons':
          ComparisonStore.instance.groups.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Save the backup through the platform file dialog.
  ///
  /// Using `saveFile` everywhere avoids share-sheet gaps:
  /// - Linux cannot share files at all (share_plus throws).
  /// - iPad share sheets require a popover origin.
  /// - Users get a real `.json` file they can import again.
  Future<BackupExportResult> exportFile({String? dialogTitle}) async {
    final json = await buildJson();
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final name = 'zhidang-backup-$stamp.json';
    final bytes = Uint8List.fromList(utf8.encode(json));
    return _saveBytes(name, bytes, dialogTitle);
  }

  /// CSV export for spreadsheet analysis. One row per offer measure, plus a
  /// row for products without offers.
  Future<String> buildCsv() async {
    final products = await _storage.loadProducts();
    final zh = AppSettings.instance.isZh;
    final headers = zh
        ? const [
            '商品',
            '大类',
            '商品标签',
            '品牌/规格',
            '总价',
            '数量',
            '单位',
            '单价',
            '报价标签',
            '店铺',
            '区域',
            '报价备注',
            '收藏',
            '限时',
            '商品备注',
            '更新时间',
          ]
        : const [
            'Product',
            'Category',
            'Product tags',
            'Brand / spec',
            'Total price',
            'Quantity',
            'Unit',
            'Unit price',
            'Offer tags',
            'Shop',
            'Area',
            'Offer note',
            'Favorite',
            'Limited',
            'Product note',
            'Updated',
          ];
    final rows = <List<String>>[headers];

    for (final product in products) {
      final category =
          CategoryStore.instance.byId(product.categoryId)?.name ?? '';
      final productTags = product.tags.join(' / ');
      if (product.offers.isEmpty) {
        rows.add([
          product.name,
          category,
          productTags,
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          product.note,
          '',
        ]);
        continue;
      }
      for (final offer in product.offers) {
        final updated = DateFormat('yyyy-MM-dd HH:mm').format(offer.updatedAt);
        for (final measure in offer.measures) {
          if (measure.quantity <= 0) continue;
          rows.add([
            product.name,
            category,
            productTags,
            offer.brand,
            _plainNumber(offer.price),
            _plainNumber(measure.quantity),
            measure.unit,
            _plainNumber(offer.price / measure.quantity, decimals: 6),
            offer.tags.join(' / '),
            offer.shop,
            offer.shopArea,
            offer.note,
            offer.favorite ? (zh ? '是' : 'Yes') : (zh ? '否' : 'No'),
            offer.limitedPrice ? (zh ? '是' : 'Yes') : (zh ? '否' : 'No'),
            product.note,
            updated,
          ]);
        }
      }
    }

    return rows
        .map((row) => row.map(_csvCell).join(','))
        .join('\r\n');
  }

  /// Save the CSV using the platform file dialog (UTF-8 BOM for Excel).
  Future<BackupExportResult> exportCsvFile({String? dialogTitle}) async {
    final csv = await buildCsv();
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final name = 'zhidang-products-$stamp.csv';
    final bytes = Uint8List.fromList(utf8.encode('\uFEFF$csv'));
    return _saveBytes(name, bytes, dialogTitle);
  }

  Future<BackupExportResult> _saveBytes(
    String name,
    Uint8List bytes,
    String? dialogTitle,
  ) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: dialogTitle,
      fileName: name,
      type: FileType.any,
      bytes: bytes,
    );

    // Web triggers a browser download and returns null on purpose.
    if (kIsWeb) return BackupExportResult.saved;

    if (path == null || path.trim().isEmpty) {
      return BackupExportResult.cancelled;
    }

    // Desktop plugins report a normal path; make sure the bytes landed.
    // Android/iOS return content URIs and write the bytes natively, so skip.
    final isDesktop =
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
    if (isDesktop) {
      final file = File(path);
      if (!await file.exists() || await file.length() != bytes.length) {
        await file.writeAsBytes(bytes, flush: true);
      }
    }
    return BackupExportResult.saved;
  }

  static String _csvCell(String value) {
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _plainNumber(double value, {int decimals = 3}) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    final text = value.toStringAsFixed(decimals);
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }

  BackupPayload parse(String raw) {
    // Strip UTF-8 BOM that some editors/OSes prepend; jsonDecode fails on it.
    final text = raw.replaceFirst('\uFEFF', '');
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('Invalid backup root');
    }
    final map = Map<String, dynamic>.from(decoded);

    final app = map['app']?.toString();
    if (app != null && app.isNotEmpty && app != 'zhidang') {
      throw const FormatException('Not a zhidang backup');
    }

    final productsRaw = map['products'];
    // Products are the core payload; other sections may be absent in older
    // or hand-edited backups and are treated as empty instead of failing.
    if (productsRaw is! List) {
      throw const FormatException('Missing products');
    }
    // Reject arbitrary JSON that merely happens to contain `products`,
    // otherwise importing it would wipe the user's data.
    final hasMarker = map.containsKey('version') ||
        map.containsKey('suppliers') ||
        map.containsKey('units') ||
        map.containsKey('unitRelations') ||
        map.containsKey('comparisons') ||
        map.containsKey('categories');
    if (app != 'zhidang' && !hasMarker) {
      throw const FormatException('Not a zhidang backup');
    }
    final suppliersRaw = map['suppliers'];
    final suppliersList = suppliersRaw is List ? suppliersRaw : const [];
    final unitsRaw = map['units'];
    final unitsList = unitsRaw is List ? unitsRaw : const [];
    final unitRelationsRaw = map['unitRelations'];
    final unitRelationsList =
        unitRelationsRaw is List ? unitRelationsRaw : const [];
    final comparisonsRaw = map['comparisons'];
    final comparisonsList =
        comparisonsRaw is List ? comparisonsRaw : const [];
    final categoriesRaw = map['categories'];
    final categoriesList = categoriesRaw is List ? categoriesRaw : const [];

    final products = productsRaw
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final suppliers = suppliersList
        .map((e) => Supplier.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final categories = categoriesList
        .map(
          (e) =>
              ProductCategory.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .where((c) => c.name.trim().isNotEmpty)
        .toList();
    final units = unitsList
        .map((e) => CustomUnit.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((u) => u.name.trim().isNotEmpty)
        .toList();
    final unitRelations = unitRelationsList
        .map(
          (e) => UnitRelation.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .where((r) => r.factor > 0 && r.fromUnit != r.toUnit)
        .toList();
    final comparisons = comparisonsList
        .map(
          (e) =>
              ComparisonGroup.fromJson(Map<String, dynamic>.from(e as Map)),
        )
        .where((g) => g.name.trim().isNotEmpty)
        .toList();

    return BackupPayload(
      version: (map['version'] as num?)?.toInt() ?? 1,
      exportedAt: map['exportedAt'] != null
          ? DateTime.tryParse(map['exportedAt'] as String)
          : null,
      products: products,
      suppliers: suppliers,
      categories: categories,
      units: units,
      unitRelations: unitRelations,
      comparisons: comparisons,
    );
  }

  Future<BackupPayload?> pickAndParse() async {
    // Pick any file: extension/MIME filters hide valid backups on some
    // Android file managers and iOS providers. Validate contents instead.
    // Only the web needs bytes in memory; native pickers give a usable path.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: kIsWeb,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    String? raw;
    if (file.bytes != null) {
      raw = utf8.decode(file.bytes!, allowMalformed: true);
    }
    if ((raw == null || raw.isEmpty) && file.path != null && !kIsWeb) {
      final f = File(file.path!);
      if (await f.exists()) {
        raw = utf8.decode(await f.readAsBytes(), allowMalformed: true);
      }
    }
    if (raw == null || raw.trim().isEmpty) {
      throw const FormatException('Empty backup file');
    }
    return parse(raw);
  }

  Future<void> apply(BackupPayload payload) async {
    await _storage.saveProducts(payload.products);
    await SupplierStore.instance.replaceAll(payload.suppliers);
    await CategoryStore.instance.replaceAll(payload.categories);
    if (payload.units.isEmpty) {
      await UnitStore.instance.resetToDefaults(AppSettings.instance.locale);
    } else {
      await UnitStore.instance.replaceAll(payload.units);
    }
    await UnitStore.instance.replaceRelations(payload.unitRelations);
    await ComparisonStore.instance.replaceAll(payload.comparisons);
    DataRevision.bump();
  }

  Future<void> clearAll() async {
    await _storage.saveProducts([]);
    await SupplierStore.instance.clear();
    await CategoryStore.instance.clear();
    await ComparisonStore.instance.clear();
    await UnitStore.instance.resetToDefaults(AppSettings.instance.locale);
    await UnitStore.instance.replaceRelations(const []);
    DataRevision.bump();
  }
}
