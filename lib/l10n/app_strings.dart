import 'package:flutter/material.dart';

import '../settings/app_settings.dart';

class AppStrings {
  const AppStrings(this.locale);

  final Locale locale;

  bool get isZh => locale.languageCode != 'en';

  static AppStrings of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_StringsScope>();
    if (inherited != null) return inherited.strings;
    return AppStrings(AppSettings.instance.locale);
  }

  static Widget provide({
    required Locale locale,
    required Widget child,
  }) {
    return _StringsScope(
      strings: AppStrings(locale),
      child: child,
    );
  }

  String get appName => isZh ? '值当' : 'Zhidang';

  String get settings => isZh ? '设置' : 'Settings';
  String get menuSettings => isZh ? '设置…' : 'Settings…';
  String get menuEdit => isZh ? '编辑' : 'Edit';
  String get menuView => isZh ? '显示' : 'View';
  String get menuWindow => isZh ? '窗口' : 'Window';
  String get menuUndo => isZh ? '撤销' : 'Undo';
  String get menuRedo => isZh ? '重做' : 'Redo';
  String get menuCut => isZh ? '剪切' : 'Cut';
  String get menuCopy => isZh ? '拷贝' : 'Copy';
  String get menuPaste => isZh ? '粘贴' : 'Paste';
  String get menuSelectAll => isZh ? '全选' : 'Select All';
  String get language => isZh ? '语言' : 'Language';
  String get languageZh => isZh ? '中文' : 'Chinese';
  String get languageEn => isZh ? 'English' : 'English';
  String get appearance => isZh ? '外观' : 'Appearance';
  String get themeMode => isZh ? '主题模式' : 'Theme mode';
  String get themeSystem => isZh ? '跟随系统' : 'System';
  String get themeLight => isZh ? '浅色' : 'Light';
  String get themeDark => isZh ? '深色' : 'Dark';
  String get themeColor => isZh ? '主题色' : 'Theme color';
  String get appIcon => isZh ? '应用图标' : 'App icon';
  String get appIconHint => isZh
      ? '仅 iOS / Android 可切换桌面图标'
      : 'Desktop icon switching works on iOS / Android';
  String get appIconDefault => isZh ? '默认' : 'Default';
  String get appIconClassic => isZh ? '经典' : 'Classic';
  String get appIconChanged => isZh
      ? '图标已切换；若桌面未更新，请下拉刷新或稍候'
      : 'Icon updated; pull to refresh home screen if needed';
  String get appIconUnsupported => isZh
      ? '当前平台不支持切换桌面图标'
      : 'This platform cannot change the launcher icon';
  String get appIconFailed => isZh ? '切换图标失败' : 'Failed to change icon';
  String get data => isZh ? '数据' : 'Data';
  String get suppliers => isZh ? '供应商' : 'Suppliers';
  String get suppliersManage => isZh ? '管理供应商' : 'Manage suppliers';
  String get suppliersManageHint => isZh
      ? '预先维护超市、电商等购买渠道'
      : 'Predefine stores and purchase channels';
  String get addSupplier => isZh ? '添加供应商' : 'Add supplier';
  String get editSupplier => isZh ? '编辑供应商' : 'Edit supplier';
  String get deleteSupplier => isZh ? '删除供应商' : 'Delete supplier';
  String deleteSupplierConfirm(String name) =>
      isZh ? '确定删除供应商「$name」？' : 'Delete supplier "$name"?';
  String get supplierName => isZh ? '供应商名称' : 'Supplier name';
  String get supplierNameHint =>
      isZh ? '例如：盒马、京东、沃尔玛' : 'e.g. Costco, Amazon, Walmart';
  String get supplierNameRequired =>
      isZh ? '请填写供应商名称' : 'Please enter a supplier name';
  String get supplierNameExists =>
      isZh ? '该供应商已存在' : 'This supplier already exists';
  String get searchSuppliers =>
      isZh ? '搜索供应商' : 'Search suppliers';
  String get noSuppliers => isZh ? '还没有供应商' : 'No suppliers yet';
  String get noSupplierResults => isZh ? '没有匹配的供应商' : 'No matching suppliers';
  String get suppliersHint => isZh
      ? '添加常用购买渠道后，录入报价时可快速选择。'
      : 'Add common stores so you can pick them quickly when adding offers.';
  String supplierCount(int n) =>
      isZh ? '共 $n 个供应商' : (n == 1 ? '1 supplier' : '$n suppliers');
  String get selectSupplier => isZh ? '选择供应商' : 'Select supplier';
  String get noneOption => isZh ? '无' : 'None';
  String get customSupplier => isZh ? '其他（手动输入）' : 'Other (type manually)';

  String get about => isZh ? '关于' : 'About';
  String get aboutBody => isZh
      ? '记录商品单价，比较不同品牌谁更值当。'
      : 'Track unit prices and compare brands for the best value.';
  String get version => isZh ? '版本' : 'Version';

  String get newProduct => isZh ? '新建商品' : 'New product';
  String get create => isZh ? '新建' : 'New';
  String get addFirstProduct => isZh ? '添加第一个商品' : 'Add first product';
  String get searchHint => isZh ? '搜索商品 / 品牌' : 'Search products / brands';
  String get noProducts => isZh ? '还没有商品' : 'No products yet';
  String productCount(int n) =>
      isZh ? '共 $n 个商品' : (n == 1 ? '1 product' : '$n products');
  String get emptyHintTitle =>
      isZh ? '记录单价，轻松比价' : 'Track unit prices, compare easily';
  String get emptyHintBody => isZh
      ? '添加商品，再录入不同品牌的价格和规格，\n自动算出谁更值当。'
      : 'Add a product, enter brand prices and sizes,\nand see which one is the best value.';
  String get selectProductHint =>
      isZh ? '从左侧选择一个商品查看比价' : 'Select a product on the left to compare';
  String get backToList => isZh ? '返回列表' : 'Back to list';
  String unitLabel(String unit) => isZh ? '单位：$unit' : 'Unit: $unit';
  String measureUnit(String unit) =>
      isZh ? '计量单位：$unit' : 'Unit of measure: $unit';

  String get editProduct => isZh ? '编辑商品' : 'Edit product';
  String get deleteProduct => isZh ? '删除商品' : 'Delete product';
  String get edit => isZh ? '编辑' : 'Edit';
  String get delete => isZh ? '删除' : 'Delete';
  String get cancel => isZh ? '取消' : 'Cancel';
  String get save => isZh ? '保存' : 'Save';
  String get add => isZh ? '添加' : 'Add';
  String get createAction => isZh ? '创建' : 'Create';

  String deleteProductConfirm(String name) => isZh
      ? '确定删除「$name」及其全部报价？'
      : 'Delete "$name" and all its offers?';
  String get deleteOffer => isZh ? '删除报价' : 'Delete offer';
  String deleteOfferConfirm(String brand) =>
      isZh ? '确定删除「$brand」？' : 'Delete "$brand"?';

  String get bestValueNow => isZh ? '当前最值当' : 'Best value now';
  String get brandCompare => isZh ? '品牌比价' : 'Brand comparison';
  String get addOffer => isZh ? '添加报价' : 'Add offer';
  String get noOffers => isZh ? '还没有报价' : 'No offers yet';
  String get noOffersHint => isZh
      ? '添加不同品牌的总价和规格，自动换算单价'
      : 'Add brand prices and sizes to calculate unit prices';
  String brandCount(int n) =>
      isZh ? '$n 个品牌' : (n == 1 ? '1 brand' : '$n brands');
  String bestBrand(String brand) => isZh ? '最优：$brand' : 'Best: $brand';
  String get noOfferHintCard =>
      isZh ? '还没有报价，点进来添加' : 'No offers yet — tap to add';
  String get bestBadge => isZh ? '优' : 'Best';

  String get productName => isZh ? '商品名称' : 'Product name';
  String get productNameHint =>
      isZh ? '例如：牛奶、洗衣液、大米' : 'e.g. milk, detergent, rice';
  String get productNameRequired =>
      isZh ? '请填写商品名称' : 'Please enter a product name';
  String get unitOfMeasure => isZh ? '计量单位' : 'Unit of measure';
  String get measureDimensions => isZh ? '度量维度' : 'Measure dimensions';
  String get measureDimensionsHint => isZh
      ? '可多选，如纸巾可按 包 / 张 分别比价'
      : 'Select multiple, e.g. pack / sheet';
  String get measureDimensionRequired =>
      isZh ? '请至少选择一个度量维度' : 'Select at least one dimension';
  String measureUnitsLabel(String units) =>
      isZh ? '度量维度：$units' : 'Dimensions: $units';
  String dimensionCount(int n) =>
      isZh ? '$n 个维度' : (n == 1 ? '1 dimension' : '$n dimensions');
  String get compareByDimension => isZh ? '按维度比价' : 'Compare by dimension';
  String get advancedOptions => isZh ? '高级选项' : 'Advanced';
  String get unitRelations => isZh ? '单位换算（可选）' : 'Unit conversion (optional)';
  String get unitRelationsHint => isZh
      ? '仅在需要「1 包 = 200 张」这类自动换算时使用'
      : 'Only when you need auto conversion like 1 pack = 200 sheets';
  String get offerRelations => isZh ? '本报价换算（可选）' : 'Offer conversion (optional)';
  String get offerRelationsHint => isZh
      ? '不同品牌可设不同换算；不填也能手动输入各单位数量'
      : 'Each brand can differ; you can still enter quantities manually';
  String get addRelation => isZh ? '添加换算' : 'Add relation';
  String get editRelation => isZh ? '编辑换算' : 'Edit relation';
  String get deleteRelation => isZh ? '删除换算' : 'Delete relation';
  String get noRelations => isZh ? '未设置换算' : 'No conversion set';
  String get useDefaultRelations =>
      isZh ? '套用商品默认' : 'Use product default';
  String relationsConfigured(int n) =>
      isZh ? '已设 $n 条' : (n == 1 ? '1 set' : '$n set');
  String get relationFrom => isZh ? '从单位' : 'From';
  String get relationTo => isZh ? '到单位' : 'To';
  String get relationFactor => isZh ? '数量' : 'Amount';
  String relationEquals(String from, String factor, String to) =>
      isZh ? '1 $from = $factor $to' : '1 $from = $factor $to';
  String get relationInvalid => isZh
      ? '请填写有效换算（两单位不同且数量大于 0）'
      : 'Enter a valid relation (different units, amount > 0)';
  String get relationSameUnit =>
      isZh ? '两个单位不能相同' : 'Units must be different';
  String get autoFilled => isZh ? '已按换算自动填入' : 'Auto-filled by relation';
  String get noteOptional => isZh ? '备注（可选）' : 'Note (optional)';

  String get editOffer => isZh ? '编辑报价' : 'Edit offer';
  String get brandOrSpec => isZh ? '品牌 / 规格名' : 'Brand / variant';
  String get brandHint =>
      isZh ? '例如：伊利金典、蓝月亮' : 'e.g. Brand A, Value pack';
  String get brandRequired => isZh ? '请填写品牌' : 'Please enter a brand';
  String get totalPrice => isZh ? '总价（元）' : 'Total price';
  String get offerMeasures => isZh ? '规格数量' : 'Quantities';
  String get offerMeasuresHint => isZh
      ? '填写购买数量；需要自动换算时再展开下方高级选项'
      : 'Enter purchase quantities; open Advanced only if you need conversion';
  String get measureAtLeastOneRequired => isZh
      ? '请至少填写一个维度的数量'
      : 'Enter quantity for at least one dimension';
  String get quantityOptionalHint => isZh ? '可不填' : 'Optional';
  String quantityLabel(String unit) =>
      isZh ? '数量（$unit）' : 'Quantity ($unit)';
  String get quantityQuickPick => isZh ? '快速数量' : 'Quick quantity';
  String get shopOptional => isZh ? '供应商（可选）' : 'Supplier (optional)';
  String get shopHint =>
      isZh ? '选择或输入购买渠道' : 'Select or type a purchase channel';
  String get requiredField => isZh ? '请填写' : 'Required';
  String get enterNumber => isZh ? '请输入数字' : 'Enter a number';
  String get mustBePositive => isZh ? '需大于 0' : 'Must be greater than 0';

  List<String> get unitOptions => isZh
      ? const ['g', 'kg', 'ml', 'L', '个', '包', '盒', '瓶', '袋', '卷', '张', '片']
      : const [
          'g',
          'kg',
          'ml',
          'L',
          'pc',
          'pack',
          'box',
          'bottle',
          'bag',
          'roll',
          'sheet',
        ];
}

class _StringsScope extends InheritedWidget {
  const _StringsScope({
    required this.strings,
    required super.child,
  });

  final AppStrings strings;

  @override
  bool updateShouldNotify(_StringsScope oldWidget) =>
      strings.locale != oldWidget.strings.locale;
}
