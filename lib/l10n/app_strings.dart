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
  String get languageSystem => isZh ? '系统' : 'System';
  String get languageZh => isZh ? '中文' : 'Chinese';
  String get languageEn => isZh ? 'English' : 'English';
  String get appearance => isZh ? '外观' : 'Appearance';
  String get navMode => isZh ? '导航栏模式' : 'Navigation mode';
  String get navModeHint => isZh
      ? '配置数据中心、比价与设置的入口位置'
      : 'Configure where Data Center, Compare and Settings appear';
  String get simpleNavMode => isZh ? '简洁模式' : 'Simple mode';
  String get simpleNavModeHint => isZh
      ? '数据中心与设置收进顶部图标，比价收进数据中心；下方选项将锁定'
      : 'Data Center and Settings use header icons and Compare moves into Data Center. Options below are locked.';
  String get simpleNavModeLocked => isZh
      ? '简洁模式下不可调整；关闭后可继续修改各入口'
      : 'Locked in simple mode. Turn it off to change these entries.';
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
  String get compareNavDataCenter => isZh ? '数据中心' : 'Data Center';
  String get compareNavDataCenterHint => isZh
      ? '从导航栏和顶部移除，在数据中心快捷工具中打开'
      : 'Remove from nav and header; open it from Data Center tools';
  String get compareNavDisabled => isZh ? '关闭入口' : 'Hidden';
  String get compareNavDisabledHint => isZh
      ? '隐藏所有比价入口'
      : 'Hide all compare entry points';
  String get dataCenterEntry => isZh ? '数据中心入口' : 'Data center entry';
  String get dataCenterEntryHint => isZh
      ? '选择数据中心的显示位置'
      : 'Choose where the Data Center appears';
  String get dataCenterNavBottom => isZh ? '导航栏' : 'Nav bar';
  String get dataCenterNavBottomHint => isZh
      ? '在导航栏显示数据中心（与商品等一并出现）'
      : 'Show Data Center on the navigation bar with Products';
  String get dataCenterNavHeader => isZh ? '顶部图标' : 'Header icon';
  String get dataCenterNavHeaderHint => isZh
      ? '在页面顶部显示数据中心图标'
      : 'Show a data center icon in the page header';
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
  String get sidebarAutoHint => isZh
      ? '桌面宽窗口会自动使用侧边栏，平板横屏同样使用侧边栏；其余情况使用底边栏。'
      : 'Wide desktop windows and tablets in landscape use a sidebar automatically; other sizes use the bottom bar.';
  String get navBarEmptyHint => isZh
      ? '比价与设置都不在导航栏时，导航栏会自动隐藏'
      : 'The navigation bar hides when neither Compare nor Settings is placed there';
  String get compactMode => isZh ? '紧凑模式' : 'Compact mode';
  String get compactModeHint => isZh
      ? '使用紧凑的商品列表，不再显示大卡片'
      : 'Dense product rows instead of large cards';
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
  String get dataCenter => isZh ? '数据中心' : 'Data center';
  String get dataTools => isZh ? '快捷工具' : 'Tools';
  String get dataMaintenance => isZh ? '数据维护' : 'Maintenance';
  String get offersStat => isZh ? '报价' : 'Offers';
  String get comparisonGroupsStat => isZh ? '比价组' : 'Groups';
  String comparisonGroupsCount(int n) => isZh
      ? '$n 个比价组'
      : (n == 1 ? '1 comparison group' : '$n comparison groups');
  String get suppliers => isZh ? '供应商' : 'Suppliers';
  String get suppliersManage => isZh ? '管理供应商' : 'Manage suppliers';
  String get suppliersManageHint => isZh
      ? '预先维护超市、电商等购买渠道'
      : 'Predefine stores and purchase channels';
  String get categories => isZh ? '商品大类' : 'Categories';
  String get categoriesManage => isZh ? '管理商品大类' : 'Manage categories';
  String get categoriesManageHint => isZh
      ? '如肉类、纸品；大类内商品共享单位并可自动比价'
      : 'e.g. meat, paper; shared units and auto compare';
  String get addCategory => isZh ? '添加大类' : 'Add category';
  String get editCategory => isZh ? '编辑大类' : 'Edit category';
  String get deleteCategory => isZh ? '删除大类' : 'Delete category';
  String deleteCategoryConfirm(String name) =>
      isZh ? '确定删除大类「$name」？成员商品将解除关联。' : 'Delete category "$name"? Products will be unlinked.';
  String get categoryName => isZh ? '大类名称' : 'Category name';
  String get categoryNameHint =>
      isZh ? '例如：肉类、乳品、纸品' : 'e.g. meat, dairy, paper';
  String get categoryNameRequired =>
      isZh ? '请填写大类名称' : 'Please enter a category name';
  String get categoryNameExists =>
      isZh ? '该大类已存在' : 'This category already exists';
  String get categoryUnit => isZh ? '大类单位' : 'Category units';
  String get categoryUnitHint => isZh
      ? '可多选；加入该大类的商品会继承这些单位；移除时若无相关报价数据可自动去掉'
      : 'Multi-select; member products inherit these units; unused ones can drop when leaving';
  String get searchCategories =>
      isZh ? '搜索大类' : 'Search categories';
  String get noCategories => isZh ? '还没有商品大类' : 'No categories yet';
  String get noCategoryResults => isZh ? '没有匹配的大类' : 'No matching categories';
  String get categoriesHint => isZh
      ? '把同类商品归到大类后，可共享单位并在比价页自动成组。'
      : 'Group related products to share a unit and auto-compare.';
  String categoryCount(int n) =>
      isZh ? '共 $n 个大类' : (n == 1 ? '1 category' : '$n categories');
  String get productCategory => isZh ? '所属大类' : 'Category';
  String get productCategoryHint => isZh
      ? '可选；加入后继承大类单位'
      : 'Optional; inherits the category unit';
  String get categoryCompare => isZh ? '大类比价' : 'Category compare';
  String get categoryCompareHint => isZh
      ? '同大类商品已对齐单位，可直接打开比价'
      : 'Same-category products share a unit — open to compare';
  String get categoryNeedTwoProducts => isZh
      ? '该大类至少需要 2 个商品'
      : 'Need at least 2 products in this category';
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
  String get supplierAreas => isZh ? '区域/分类' : 'Areas';
  String get supplierAreasHint => isZh
      ? '属于当前供应商的区域或分类，例如熟食区、生鲜区'
      : 'Areas or departments of this supplier, e.g. deli, fresh produce';
  String get addSupplierArea => isZh ? '添加区域' : 'Add area';
  String get supplierAreaNameHint =>
      isZh ? '例如熟食区、生鲜区' : 'e.g. deli, produce';
  String supplierAreasLimit(int n) =>
      isZh ? '最多 $n 个区域' : (n == 1 ? '1 area max' : '$n areas max');
  String get shopAreaOptional => isZh ? '区域（可选）' : 'Area (optional)';
  String get noShopArea => isZh ? '不指定区域' : 'No area';

  String get tags => isZh ? '标签' : 'Tags';
  String get addTag => isZh ? '添加标签' : 'Add tag';
  String get tagNameHint =>
      isZh ? '例如：日用品、促销、会员价' : 'e.g. household, sale, member';
  String tagsAssignHint(int max) => isZh
      ? '最多 $max 个；输入添加，点击标签可移除'
      : 'Up to $max; type to add, tap a tag to remove';
  String tagsLimitReached(int max) =>
      isZh ? '已达上限（$max 个）' : 'Limit reached ($max)';
  String get tagsInCategory => isZh
      ? '当前大类已有标签（点击添加）'
      : 'Tags in this category (tap to add)';
  String get tagsInProductOffers => isZh
      ? '此商品报价已有标签（点击添加）'
      : "Tags used by this product's offers (tap to add)";

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
  String get quickQuantityPresets => isZh
      ? '快速数量预设'
      : 'Quick quantity presets';
  String get quickQuantityPresetsHint => isZh
      ? '报价编辑时显示的快捷数量按钮；关闭开关可暂时隐藏，删除则彻底移除。'
      : 'Buttons shown in the offer editor. Turn one off to hide it, or delete it entirely.';
  String get addQuickPreset => isZh
      ? '添加快速数量'
      : 'Add quick quantity';
  String get addQuickPresetHint =>
      isZh ? '输入数量，例如 2.5' : 'Enter a quantity, e.g. 2.5';
  String get restoreDefaultPresets =>
      isZh ? '恢复默认' : 'Restore defaults';
  String get noQuickPresets => isZh
      ? '还没有快速数量，可添加或恢复默认'
      : 'No quick quantities yet; add one or restore defaults';
  String get presetValueInvalid =>
      isZh ? '请输入大于 0 的数量' : 'Enter a quantity greater than 0';
  String get presetDuplicate =>
      isZh ? '该数量已存在' : 'This quantity already exists';
  String unitCount(int n) =>
      isZh ? '共 $n 个单位' : (n == 1 ? '1 unit' : '$n units');
  String get resetUnits => isZh ? '恢复默认单位' : 'Reset to defaults';
  String get resetUnitsConfirm => isZh
      ? '将清空当前单位列表，并恢复为默认预设单位。是否继续？'
      : 'This will replace your unit list with the default presets. Continue?';
  String get unitsResetDone => isZh ? '已恢复默认单位' : 'Default units restored';

  String get dataManage => isZh ? '数据管理' : 'Data management';
  String get dataManageHint => isZh
      ? '导入、导出或清空商品、供应商、大类、单位与比价组'
      : 'Import, export or clear products, suppliers, categories, units and compare groups';
  String get exportData => isZh ? '导出数据' : 'Export data';
  String get exportDataHint => isZh
      ? '导出商品、供应商、大类、单位与比价组为 JSON'
      : 'Export products, suppliers, categories, units and compare groups as JSON';
  String get exportCsv => isZh ? '导出 CSV' : 'Export CSV';
  String get exportCsvHint => isZh
      ? '导出商品与报价明细，便于在表格中分析'
      : 'Export products and offer details for spreadsheet analysis';
  String get exportCsvDone => isZh ? 'CSV 已导出' : 'CSV exported';
  String get importData => isZh ? '导入数据' : 'Import data';
  String get importDataHint => isZh
      ? '从备份恢复；将覆盖当前数据'
      : 'Restore from backup; replaces current data';
  String get importDataConfirm => isZh
      ? '导入将覆盖现有商品、供应商、大类、单位和比价组，是否继续？'
      : 'Import will replace products, suppliers, categories, units and compare groups. Continue?';
  String get clearData => isZh ? '清空全部数据' : 'Clear all data';
  String get clearDataHint => isZh
      ? '删除全部商品、供应商、大类与比价组，并恢复默认单位'
      : 'Delete all products, suppliers, categories and compare groups; reset units';
  String get clearDataConfirm => isZh
      ? '确定清空全部数据？此操作不可撤销。'
      : 'Clear all data? This cannot be undone.';
  String get exportDone => isZh ? '导出成功' : 'Export complete';
  String get exportCancelled => isZh ? '已取消导出' : 'Export cancelled';
  String get importDone => isZh ? '导入成功' : 'Import complete';
  String get clearDataDone => isZh ? '已清空数据' : 'All data cleared';
  String get exportFailed => isZh ? '导出失败' : 'Export failed';
  String get importFailed =>
      isZh ? '导入失败，请重试' : 'Import failed, please try again';
  String get importInvalid => isZh
      ? '不是有效的备份文件'
      : 'This is not a valid backup file';
  String get clearFailed => isZh ? '清空失败' : 'Clear failed';
  String get importCancelled => isZh ? '已取消导入' : 'Import cancelled';
  String get importAction => isZh ? '导入' : 'Import';
  String get clearAction => isZh ? '清空' : 'Clear';
  String importSummary(
    int products,
    int suppliers,
    int units,
    int comparisons, {
    int categories = 0,
  }) =>
      isZh
          ? '将导入 $products 个商品、$suppliers 个供应商、$categories 个大类、$units 个单位、$comparisons 个比价组'
          : 'Will import $products products, $suppliers suppliers, $categories categories, $units units, $comparisons groups';

  String get about => isZh ? '关于' : 'About';
  String get aboutBody => isZh
      ? '记录商品单价，比较不同品牌谁更值当。'
      : 'Track unit prices and compare brands for the best value.';
  String get version => isZh ? '版本' : 'Version';

  String get tabProducts => isZh ? '商品' : 'Products';
  String get tabData => isZh ? '数据' : 'Data';
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
  String get discardChangesTitle => isZh ? '放弃修改？' : 'Discard changes?';
  String get discardChangesBody => isZh
      ? '当前修改尚未保存，返回后将丢失。'
      : "Your changes haven't been saved and will be lost.";
  String get discardChanges => isZh ? '放弃' : 'Discard';
  String get keepEditing => isZh ? '继续编辑' : 'Keep editing';
  String get save => isZh ? '保存' : 'Save';
  String get add => isZh ? '添加' : 'Add';
  String get createAction => isZh ? '创建' : 'Create';

  String deleteProductConfirm(String name) => isZh
      ? '确定删除「$name」及其全部报价？'
      : 'Delete "$name" and all its offers?';
  String get deleteOffer => isZh ? '删除报价' : 'Delete offer';
  String deleteOfferConfirm(String brand) =>
      isZh ? '确定删除「$brand」？' : 'Delete "$brand"?';
  String get moveOfferToProduct =>
      isZh ? '移动到其他商品' : 'Move to another product';
  String get moveOfferHint => isZh
      ? '保存后从当前商品移除；数量会按目标商品的单位自动换算'
      : 'Removed from this product after saving; quantities convert to the target units';
  String moveOfferTarget(String name) => isZh
      ? '将移动到「$name」'
      : 'Will move to "$name"';
  String moveOfferUnits(String units) =>
      isZh ? '目标单位：$units' : 'Target units: $units';
  String moveOfferIncompatible(String units) => isZh
      ? '单位不兼容 · $units'
      : 'Incompatible units · $units';
  String moveOfferPartial(String units) => isZh
      ? '部分规格将丢弃 · $units'
      : 'Some measures will be discarded · $units';
  String get moveOfferDropTitle =>
      isZh ? '部分规格无法换算' : 'Some measures cannot convert';
  String get moveOfferDropHint => isZh
      ? '以下规格无法换算到目标商品的单位，移动时将丢弃：'
      : 'These measures cannot convert to the target units and will be discarded:';
  String get moveOfferDropConfirm =>
      isZh ? '丢弃并移动' : 'Discard and move';
  String get moveOfferNoTargets =>
      isZh ? '没有其他商品可移动' : 'No other products to move to';
  String get moveOfferUnitMismatch => isZh
      ? '当前规格无法换算到目标商品的单位'
      : 'These measures cannot convert to the target product units';
  String offerMoved(String name) =>
      isZh ? '已移动到「$name」' : 'Moved to "$name"';

  String get bestValueNow => isZh ? '当前最值当' : 'Best value now';
  String get preferredOfferNow => isZh ? '当前关注' : 'Preferred';
  String productCompareTitle(String name) =>
      isZh ? '商品比价 - $name' : 'Product comparison - $name';
  String get addOffer => isZh ? '添加报价' : 'Add offer';
  String get offerViewAll => isZh ? '全部' : 'All';
  String get offerViewFavorites => isZh ? '收藏' : 'Favorites';
  String get favoritesOnly => isZh ? '只看收藏' : 'Favorites only';
  String get showAllOffers => isZh ? '显示全部' : 'Show all offers';
  String get filterByTag => isZh ? '按标签筛选' : 'Filter by tag';
  String get allTags => isZh ? '全部标签' : 'All tags';
  String get clearTagFilter => isZh ? '清除标签筛选' : 'Clear tag filters';
  String get noTaggedOffers => isZh
      ? '没有符合标签的报价'
      : 'No offers match these tags';
  String get noTaggedOffersHint => isZh
      ? '换一个标签，或清除标签筛选'
      : 'Try another tag or clear the tag filters';
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
  String dimensionCountShort(int n) =>
      isZh ? '$n 维度' : (n == 1 ? '1 dim' : '$n dims');
  String bestBrand(String brand) => isZh ? '最优：$brand' : 'Best: $brand';
  String get noOfferHintCard =>
      isZh ? '还没有报价，点进来添加' : 'No offers yet — tap to add';
  String get bestBadge => isZh ? '优' : 'Best';
  String get limitedPrice => isZh ? '限时价格' : 'Limited-time price';
  String get limitedPriceHint => isZh
      ? '不易买到，仅在列表中作为比较，不参与最优价计算'
      : 'Hard to buy; kept for comparison only and excluded from best-price calculation';
  String get limitedBadge => isZh ? '限时' : 'Limited';
  String limitedPriceLabel(String brand) =>
      isZh ? '限时：$brand' : 'Limited: $brand';
  String get limitedPriceNow => isZh ? '当前限时参考' : 'Limited reference';

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
  String get unitConversions => isZh ? '单位换算' : 'Unit conversions';
  String get unitReorderHint => isZh ? '拖动排序' : 'Drag to reorder';
  String get unitConversionsHint => isZh
      ? '这里的换算不会自动应用到商品；快速换算会直接使用，商品和报价可在高级选项中手动选择'
      : 'These conversions are not forced onto products. Quick convert uses them directly; products and offers can add them under Advanced.';
  String get categoryRelationsHint => isZh
      ? '大类选择的换算不会强制应用到商品，商品可自行选用'
      : 'Conversions chosen here are not forced onto products; each product can choose its own.';
  String get useCategoryRelations =>
      isZh ? '使用大类换算' : 'Use category conversions';
  String unitConversionsCount(int n) =>
      isZh ? '已设 $n 条' : (n == 1 ? '1 conversion' : '$n conversions');
  String get noUnitConversions => isZh
      ? '还没有全局单位换算'
      : 'No global unit conversions yet';
  String get chooseGlobalRelations => isZh
      ? '从单位库选择'
      : 'Choose from unit library';
  String get noSelectableGlobalRelations => isZh
      ? '单位库里没有可添加的换算'
      : 'No more conversions in the unit library';
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
      ? '填写购买数量；左侧图标点按可选中快速数量目标，长按可清空该单位'
      : 'Enter quantities; tap the left icon to target quick quantities, long-press to clear';
  String get measureAtLeastOneRequired => isZh
      ? '请至少填写一个维度的数量'
      : 'Enter quantity for at least one dimension';
  String get quantityOptionalHint => isZh ? '可不填' : 'Optional';
  String quantityLabel(String unit) =>
      isZh ? '数量（$unit）' : 'Quantity ($unit)';
  String get quantityHandleHint => isZh
      ? '点按选中此单位，长按清空；不会弹出键盘'
      : 'Tap to select this unit, long-press to clear; no keyboard';
  String get quantityClear => isZh ? '清空该单位数量' : 'Clear this unit';
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

  String get quickCalcTitle => isZh ? '快速换算' : 'Quick convert';
  String get quickCalcTitleHint => isZh
      ? '双击标题打开快速换算'
      : 'Double-click the title to convert prices';
  String quickCalcPinnedCount(int n) => isZh
      ? '已固定 $n 条数据'
      : (n == 1 ? '1 pinned row' : '$n pinned rows');
  String get quickCalcNoPinned => isZh
      ? '未固定数据，打开后可固定常用换算'
      : 'No pinned rows; pin common conversions inside';
  String get quickCalcHint => isZh
      ? '输入总价和数量，自动算出单价。未固定的数据只在本次运行中保留；固定后下次打开仍保留。'
      : 'Enter the total price and quantity to see the unit price. Unpinned data stays for this run only; pinned rows are restored next launch.';
  String get quickCalcAddHint => isZh
      ? '填好后点右侧 ✓ 保留；点图钉固定后，下次打开仍保留'
      : 'Tap ✓ to keep a row; pin it to keep it after restart';
  String get quickCalcIncomplete =>
      isZh ? '请填写总价和数量' : 'Enter a price and quantity';
  String get quickCalcClear => isZh ? '清空' : 'Clear';
  String get quickCalcClearConfirm => isZh
      ? '清空本次全部换算数据？'
      : 'Clear all conversion data for this session?';
  String get quickCalcName => isZh ? '名称（可选）' : 'Label (optional)';
  String get quickCalcNameHint => isZh ? '例如鸡蛋' : 'e.g. Eggs';
  String get quickCalcPrice => isZh ? '总价（元）' : 'Total price';
  String get quickCalcQuantity => isZh ? '数量' : 'Quantity';
  String get quickCalcUnit => isZh ? '单位' : 'Unit';
  String get quickCalcBest => isZh ? '最低' : 'Lowest';
  String get quickCalcGroupWeight => isZh ? '重量' : 'Weight';
  String get quickCalcGroupVolume => isZh ? '体积' : 'Volume';
  String quickCalcGroupUnit(String unit) =>
      isZh ? '单位：$unit' : 'Unit: $unit';
  String get quickCalcEmptyHint => isZh
      ? '填写总价和数量后显示单价'
      : 'Enter a price and quantity to see the unit price';
  String get quickCalcDeleteRow => isZh ? '删除这组数据' : 'Remove this row';
  String get quickCalcPin =>
      isZh ? '固定，下次打开仍保留' : 'Pin to keep after restart';
  String get quickCalcUnpin => isZh ? '取消固定' : 'Unpin';
  String get quickCalcPrimaryUnit =>
      isZh ? '主显示单位' : 'Primary display unit';
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
