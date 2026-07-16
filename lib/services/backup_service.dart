import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/custom_unit.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../settings/app_settings.dart';
import 'data_revision.dart';
import 'storage_service.dart';
import 'supplier_store.dart';
import 'unit_store.dart';

class BackupPayload {
  const BackupPayload({
    required this.products,
    required this.suppliers,
    required this.units,
    this.exportedAt,
    this.version = 1,
  });

  final int version;
  final DateTime? exportedAt;
  final List<Product> products;
  final List<Supplier> suppliers;
  final List<CustomUnit> units;
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
      'units': UnitStore.instance.units.map((e) => e.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> exportToShare() async {
    final json = await buildJson();
    final stamp = DateFormat('yyyyMMdd-HHmmss').format(DateTime.now());
    final name = 'zhidang-backup-$stamp.json';

    if (kIsWeb) {
      await SharePlus.instance.share(
        ShareParams(
          text: json,
          subject: name,
          title: name,
        ),
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(json, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: name)],
        subject: name,
        title: name,
      ),
    );
  }

  BackupPayload parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid backup root');
    }
    final map = Map<String, dynamic>.from(decoded);

    final productsRaw = map['products'];
    final suppliersRaw = map['suppliers'];
    final unitsRaw = map['units'];
    if (productsRaw is! List || suppliersRaw is! List || unitsRaw is! List) {
      throw const FormatException('Missing products/suppliers/units');
    }

    final products = productsRaw
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final suppliers = suppliersRaw
        .map((e) => Supplier.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final units = unitsRaw
        .map((e) => CustomUnit.fromJson(Map<String, dynamic>.from(e as Map)))
        .where((u) => u.name.trim().isNotEmpty)
        .toList();

    return BackupPayload(
      version: (map['version'] as num?)?.toInt() ?? 1,
      exportedAt: map['exportedAt'] != null
          ? DateTime.tryParse(map['exportedAt'] as String)
          : null,
      products: products,
      suppliers: suppliers,
      units: units,
    );
  }

  Future<BackupPayload?> pickAndParse() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    String? raw = file.bytes != null ? utf8.decode(file.bytes!) : null;
    if (raw == null && file.path != null && !kIsWeb) {
      raw = await File(file.path!).readAsString();
    }
    if (raw == null || raw.trim().isEmpty) {
      throw const FormatException('Empty backup file');
    }
    return parse(raw);
  }

  Future<void> apply(BackupPayload payload) async {
    await _storage.saveProducts(payload.products);
    await SupplierStore.instance.replaceAll(payload.suppliers);
    if (payload.units.isEmpty) {
      await UnitStore.instance.resetToDefaults(AppSettings.instance.locale);
    } else {
      await UnitStore.instance.replaceAll(payload.units);
    }
    DataRevision.bump();
  }

  Future<void> clearAll() async {
    await _storage.saveProducts([]);
    await SupplierStore.instance.clear();
    await UnitStore.instance.resetToDefaults(AppSettings.instance.locale);
    DataRevision.bump();
  }
}
