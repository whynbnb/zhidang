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
  String get noteOptional => isZh ? '备注（可选）' : 'Note (optional)';

  String get editOffer => isZh ? '编辑报价' : 'Edit offer';
  String get brandOrSpec => isZh ? '品牌 / 规格名' : 'Brand / variant';
  String get brandHint =>
      isZh ? '例如：伊利金典、蓝月亮' : 'e.g. Brand A, Value pack';
  String get brandRequired => isZh ? '请填写品牌' : 'Please enter a brand';
  String get totalPrice => isZh ? '总价（元）' : 'Total price';
  String quantityLabel(String unit) =>
      isZh ? '数量（$unit）' : 'Quantity ($unit)';
  String get shopOptional => isZh ? '购买渠道（可选）' : 'Store (optional)';
  String get shopHint =>
      isZh ? '超市 / 电商 / 本地店' : 'Supermarket / online / local';
  String get requiredField => isZh ? '请填写' : 'Required';
  String get enterNumber => isZh ? '请输入数字' : 'Enter a number';
  String get mustBePositive => isZh ? '需大于 0' : 'Must be greater than 0';

  List<String> get unitOptions => isZh
      ? const ['g', 'kg', 'ml', 'L', '个', '包', '盒', '瓶', '袋', '卷']
      : const ['g', 'kg', 'ml', 'L', 'pc', 'pack', 'box', 'bottle', 'bag', 'roll'];
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
