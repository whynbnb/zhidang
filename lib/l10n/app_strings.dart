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
  String get navMode => isZh ? '导航栏模式' : 'Navigation mode';
  String get navModeHint => isZh
      ? '配置比价与设置的入口位置'
      : 'Configure where Compare and Settings appear';
  String get compareEntry => isZh ? '比价入口' : 'Compare entry';
  String get compareEntryHint => isZh
      ? '选择如何进入跨商品比价'
      : 'Choose how to open cross-product compare';
  String get compareNavBottom => isZh ? '导航栏' : 'Nav bar';
  String get compareNavBottomHint => isZh
      ? '在导航栏显示比价（与商品等一并出现）'
      : 'Show Compare on the navigation bar with Products';
  String get compareNavHeader => isZh ? '顶部图标' : 'Header icon';
  String get compareNavHeaderHint => isZh
      ? '在页面顶部显示比价图标'
      : 'Show a compare icon in the page header';
  String get compareNavDisabled => isZh ? '关闭入口' : 'Hidden';
  String get compareNavDisabledHint => isZh
      ? '隐藏所有比价入口'
      : 'Hide all compare entry points';
  String get settingsEntry => isZh ? '设置入口' : 'Settings entry';
  String get settingsEntryHint => isZh
      ? '选择设置图标的位置（桌面默认导航栏）'
      : 'Choose where Settings appears (nav bar on desktop by default)';
  String get settingsNavBar => isZh ? '导航栏' : 'Nav bar';
  String get settingsNavBarHint => isZh
      ? '在导航栏显示设置'
      : 'Show Settings on the navigation bar';
  String get settingsNavHeader => isZh ? '顶部图标' : 'Header icon';
  String get settingsNavHeaderHint => isZh
      ? '在页面顶部显示设置图标'
      : 'Show a settings icon in the page header';
  String get sidebarNav => isZh ? '侧边栏导航' : 'Sidebar navigation';
  String get sidebarNavHint => isZh
      ? '有导航项时，桌面与平板横屏使用侧边栏；关闭则始终底边栏'
      : 'When nav items exist, use a side rail on desktop/tablet landscape; off keeps the bottom bar';
  String get sidebarNavBottom => isZh ? '底边栏' : 'Bottom bar';
  String get sidebarNavSide => isZh ? '侧边栏' : 'Sidebar';
  String get navBarEmptyHint => isZh
      ? '比价与设置都不在导航栏时，导航栏会自动隐藏'
      : 'The navigation bar hides when neither Compare nor Settings is placed there';
  String get themeMode => isZh ? '主题模式' : 'Theme mode';
  String get themeSystem => isZh ? '系统' : 'System';
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
  String get supplierTypes => isZh ? '供应商类型' : 'Supplier types';
  String get supplierTypesHint => isZh
      ? '可多选：电商、外卖、实体店'
      : 'Select one or more: online, delivery, store';
  String get supplierTypeEcommerce => isZh ? '电商' : 'Online';
  String get supplierTypeDelivery => isZh ? '外卖' : 'Delivery';
  String get supplierTypeStore => isZh ? '实体店' : 'Store';
  String get supplierAddress => isZh ? '门店地址' : 'Store address';
  String get supplierAddressHint =>
      isZh ? '实体店可选填地址' : 'Optional for physical stores';
  String get supplierAddressOptional =>
      isZh ? '门店地址（可选）' : 'Store address (optional)';

  String get tags => isZh ? '标签' : 'Tags';
  String get addTag => isZh ? '添加标签' : 'Add tag';
  String get tagNameHint =>
      isZh ? '例如：日用品、促销、会员价' : 'e.g. household, sale, member';
  String tagsAssignHint(int max) => isZh
      ? '最多 $max 个；输入添加，点击标签可移除'
      : 'Up to $max; type to add, tap a tag to remove';
  String tagsLimitReached(int max) =>
      isZh ? '已达上限（$max 个）' : 'Limit reached ($max)';

  String get units => isZh ? '单位' : 'Units';
  String get unitsManage => isZh ? '管理单位' : 'Manage units';
  String get unitsManageHint => isZh
      ? '维护可选计量单位，创建商品时从此列表选择'
      : 'Manage measurement units used when creating products';
  String get addUnit => isZh ? '添加单位' : 'Add unit';
  String get editUnit => isZh ? '编辑单位' : 'Edit unit';
  String get deleteUnit => isZh ? '删除单位' : 'Delete unit';
  String deleteUnitConfirm(String name) =>
      isZh ? '确定删除单位「$name」？' : 'Delete unit "$name"?';
  String get unitName => isZh ? '单位名称' : 'Unit name';
  String get unitNameHint =>
      isZh ? '例如：听、箱、打、斤' : 'e.g. can, case, dozen';
  String get unitNameRequired =>
      isZh ? '请填写单位名称' : 'Please enter a unit name';
  String get unitNameExists =>
      isZh ? '该单位已存在' : 'This unit already exists';
  String get searchUnits => isZh ? '搜索单位' : 'Search units';
  String get noUnits => isZh ? '还没有单位' : 'No units yet';
  String get noUnitResults => isZh ? '没有匹配的单位' : 'No matching units';
  String get unitsHint => isZh
      ? '这里的单位会出现在创建商品的维度选择中。'
      : 'Units here appear when choosing product dimensions.';
  String unitCount(int n) =>
      isZh ? '共 $n 个单位' : (n == 1 ? '1 unit' : '$n units');
  String get resetUnits => isZh ? '恢复默认单位' : 'Reset to defaults';
  String get resetUnitsConfirm => isZh
      ? '将清空当前单位列表，并恢复为默认预设单位。是否继续？'
      : 'This will replace your unit list with the default presets. Continue?';
  String get unitsResetDone => isZh ? '已恢复默认单位' : 'Default units restored';

  String get dataManage => isZh ? '数据管理' : 'Data management';
  String get dataManageHint => isZh
      ? '导入、导出或清空商品、供应商、单位与比价组'
      : 'Import, export or clear products, suppliers, units and compare groups';
  String get exportData => isZh ? '导出数据' : 'Export data';
  String get exportDataHint => isZh
      ? '导出商品、供应商、单位与比价组为 JSON'
      : 'Export products, suppliers, units and compare groups as JSON';
  String get importData => isZh ? '导入数据' : 'Import data';
  String get importDataHint => isZh
      ? '从备份恢复；将覆盖当前数据'
      : 'Restore from backup; replaces current data';
  String get importDataConfirm => isZh
      ? '导入将覆盖现有商品、供应商、单位和比价组，是否继续？'
      : 'Import will replace products, suppliers, units and compare groups. Continue?';
  String get clearData => isZh ? '清空全部数据' : 'Clear all data';
  String get clearDataHint => isZh
      ? '删除全部商品、供应商与比价组，并恢复默认单位'
      : 'Delete all products, suppliers and compare groups; reset units';
  String get clearDataConfirm => isZh
      ? '确定清空全部数据？此操作不可撤销。'
      : 'Clear all data? This cannot be undone.';
  String get exportDone => isZh ? '导出成功' : 'Export complete';
  String get importDone => isZh ? '导入成功' : 'Import complete';
  String get clearDataDone => isZh ? '已清空数据' : 'All data cleared';
  String get exportFailed => isZh ? '导出失败' : 'Export failed';
  String get importFailed =>
      isZh ? '导入失败或文件无效' : 'Import failed or file invalid';
  String get clearFailed => isZh ? '清空失败' : 'Clear failed';
  String get importCancelled => isZh ? '已取消导入' : 'Import cancelled';
  String get importAction => isZh ? '导入' : 'Import';
  String get clearAction => isZh ? '清空' : 'Clear';
  String importSummary(
    int products,
    int suppliers,
    int units,
    int comparisons,
  ) =>
      isZh
          ? '将导入 $products 个商品、$suppliers 个供应商、$units 个单位、$comparisons 个比价组'
          : 'Will import $products products, $suppliers suppliers, $units units, $comparisons groups';

  String get about => isZh ? '关于' : 'About';
  String get aboutBody => isZh
      ? '记录商品单价，比较不同品牌谁更值当。'
      : 'Track unit prices and compare brands for the best value.';
  String get version => isZh ? '版本' : 'Version';

  String get tabProducts => isZh ? '商品' : 'Products';
  String get tabCompare => isZh ? '比价' : 'Compare';
  String get tempCompare => isZh ? '临时比价' : 'Quick compare';
  String get tempCompareHint => isZh
      ? '立刻挑选商品，按单价排出高低，不保存关系'
      : 'Pick products now and rank by unit price — not saved';
  String get tempCompareNeedProducts => isZh
      ? '至少需要 2 个商品才能比价'
      : 'Add at least 2 products to compare';
  String get tempSessionHint => isZh
      ? '本次为临时比价，关闭后不会保留'
      : 'Temporary session — not saved when you leave';
  String get fixedCompare => isZh ? '固定比价' : 'Saved groups';
  String get fixedCompareHint => isZh
      ? '把常对比的商品固定成一组，随时打开'
      : 'Pin products you often compare into a reusable group';
  String get addFixedGroup => isZh ? '新建固定比价' : 'New group';
  String get editFixedGroup => isZh ? '编辑固定比价' : 'Edit group';
  String get deleteGroup => isZh ? '删除比价组' : 'Delete group';
  String deleteGroupConfirm(String name) =>
      isZh ? '确定删除比价组「$name」？' : 'Delete comparison group "$name"?';
  String get noFixedGroups => isZh ? '还没有固定比价' : 'No saved groups yet';
  String get noFixedGroupsHint => isZh
      ? '例如把猪肉、牛肉、羊肉放进一组，分开记商品也能一起比'
      : 'e.g. pork, beef, lamb — separate products, one ranking';
  String get groupName => isZh ? '组名称' : 'Group name';
  String get groupNameHint =>
      isZh ? '例如：红肉对比、纸品对比' : 'e.g. red meat, paper goods';
  String get groupNameRequired =>
      isZh ? '请填写组名称' : 'Please enter a group name';
  String get groupProducts => isZh ? '参与比价的商品' : 'Products in group';
  String get groupProductsHint => isZh
      ? '至少选 2 个，且必须有共同计量单位'
      : 'Pick at least 2 with a shared measurement unit';
  String get groupNeedTwoProducts => isZh
      ? '请至少选择 2 个商品'
      : 'Select at least 2 products';
  String get compareNeedCommonUnit => isZh
      ? '所选商品没有共同单位，无法比价'
      : 'Selected products share no common unit';
  String commonUnitsReady(String units) => isZh
      ? '可比单位：$units'
      : 'Shared units: $units';
  String get groupNoProducts => isZh ? '组内商品已失效' : 'Products missing';
  String get groupInvalidTitle => isZh ? '无法打开比价' : 'Cannot open compare';
  String get groupInvalidMissing => isZh
      ? '组内部分商品已删除或不可用，有效商品不足 2 个。'
      : 'Some products in this group are missing; fewer than 2 remain.';
  String groupInvalidMissingPartial(int missing, int remain) => isZh
      ? '有 $missing 个商品已删除；当前仅剩 $remain 个有效商品（至少需要 2 个）。'
      : '$missing product(s) missing; only $remain left (need at least 2).';
  String get groupInvalidNoCommonUnit => isZh
      ? '组内商品的计量单位已变更，当前没有共同单位，无法比价。请编辑组或调整商品单位。'
      : 'Product units changed; there is no shared unit left. Edit the group or product units.';
  String get groupInvalidPreferredUnit => isZh
      ? '组内默认比价单位已不再适用（商品单位可能已变更），将自动改用可用单位。'
      : 'Default unit no longer applies (units may have changed); a shared unit will be used.';
  String get groupEditAction => isZh ? '去编辑' : 'Edit group';
  String get groupStatusInvalid => isZh ? '需调整后才能比价' : 'Needs fix before compare';
  String groupProductSummary(int n, String preview) => isZh
      ? '$n 个商品：$preview'
      : '$n products: $preview';
  String get groupPreferredUnit => isZh ? '默认比价单位' : 'Default unit';
  String get groupPreferredUnitHint => isZh
      ? '仅列出所选商品的共同单位；可自动选择'
      : 'Only shared units among selected products; or auto';
  String get autoUnit => isZh ? '自动' : 'Auto';
  String get openCompare => isZh ? '打开比价' : 'Open';
  String get groupSaved => isZh ? '已创建固定比价' : 'Group created';
  String get groupUpdated => isZh ? '已更新固定比价' : 'Group updated';
  String get compareByUnit => isZh ? '按单位比价' : 'Compare by unit';
  String get compareRanking => isZh ? '单价排名' : 'Unit price ranking';
  String noOfferForUnit(String unit) =>
      isZh ? '暂无 $unit 报价' : 'No offer for $unit';
  String get pickProductsHint => isZh
      ? '勾选要对比的商品（至少 2 个，且须有共同单位）'
      : 'Check products to compare (at least 2, shared unit required)';
  String confirmPick(int n) =>
      isZh ? '开始比价（$n）' : 'Compare ($n)';

  String get newProduct => isZh ? '新建商品' : 'New product';
  String get create => isZh ? '新建' : 'New';
  String get addFirstProduct => isZh ? '添加第一个商品' : 'Add first product';
  String get searchHint =>
      isZh ? '搜索商品 / 品牌 / 标签' : 'Search products / brands / tags';
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
  String get selectGroupHint =>
      isZh ? '从左侧选择比价组，或发起临时比价' : 'Select a group on the left, or start a temporary compare';
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
  String get preferredOfferNow => isZh ? '当前关注' : 'Preferred';
  String get brandCompare => isZh ? '品牌比价' : 'Brand comparison';
  String get addOffer => isZh ? '添加报价' : 'Add offer';
  String get offerViewAll => isZh ? '全部' : 'All';
  String get offerViewFavorites => isZh ? '收藏' : 'Favorites';
  String get offerViewCheapest => isZh ? '最便宜' : 'Cheapest';
  String get offerViewMode => isZh ? '显示方式' : 'Show';
  String get favoriteOffer => isZh ? '收藏报价' : 'Favorite offer';
  String get unfavoriteOffer => isZh ? '取消收藏' : 'Remove favorite';
  String get noFavoriteOffers => isZh ? '还没有收藏报价' : 'No favorite offers yet';
  String get noFavoriteOffersHint => isZh
      ? '点报价上的星标收藏；没有收藏时「当前关注」会显示最便宜的'
      : 'Tap the star on an offer; preferred falls back to cheapest';
  String get favoriteBadge => isZh ? '藏' : '★';
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
  String get listDisplayUnit => isZh ? '主单位' : 'Primary unit';
  String get listDisplayUnitHint => isZh
      ? '商品卡片上的最优单价按此单位显示'
      : 'Best unit price on product cards uses this unit';
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
  String get relationNeedTwoUnits => isZh
      ? '至少选择两个不同维度后才能设置换算'
      : 'Select at least two dimensions before adding a conversion';
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

  String get counter => isZh ? '计数器' : 'Counter';
  String get counterHint => isZh
      ? '默认关闭；次数计数只记数字，时间记录会保存每次时间与备注'
      : 'Off by default; count mode stores a number, log mode stores each time and note';
  String get counterModeNone => isZh ? '关闭' : 'Off';
  String get counterModeCount => isZh ? '次数' : 'Count';
  String get counterModeLog => isZh ? '时间记录' : 'Timeline';
  String get counterModeCountLabel => isZh ? '次数计数' : 'Count only';
  String get counterModeLogLabel => isZh ? '时间记录' : 'Time log';
  String counterTimes(int n) => isZh ? '$n 次' : (n == 1 ? '1 time' : '$n times');
  String counterLogEntries(int n) =>
      isZh ? '$n 条记录' : (n == 1 ? '1 entry' : '$n entries');
  String get counterIncrement => isZh ? '加一' : 'Add';
  String get counterDecrement => isZh ? '减一' : 'Minus';
  String get counterReset => isZh ? '清零' : 'Reset';
  String get counterResetConfirm => isZh
      ? '确定清零该报价的计数？'
      : 'Reset this offer counter?';
  String get counterLogs => isZh ? '时间记录' : 'Time log';
  String get counterAddLog => isZh ? '添加记录' : 'Add entry';
  String get counterLogNoteOptional =>
      isZh ? '本次备注（可选）' : 'Note for this entry (optional)';
  String get counterNoLogs => isZh ? '还没有记录' : 'No log entries yet';
  String get counterDeleteLog => isZh ? '删除记录' : 'Delete entry';
  String get counterViewLogs => isZh ? '查看记录' : 'View log';
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
