import 'package:flutter/material.dart';

import '../models/product.dart';

Future<Product?> showProductForm(
  BuildContext context, {
  Product? product,
}) {
  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ProductFormSheet(product: product),
  );
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({this.product});

  final Product? product;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _note;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product?.name ?? '');
    _note = TextEditingController(text: widget.product?.note ?? '');
    _unit = widget.product?.unit ?? 'g';
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.product;
    final result = base == null
        ? Product(name: _name.text.trim(), unit: _unit, note: _note.text.trim())
        : base.copyWith(
            name: _name.text.trim(),
            unit: _unit,
            note: _note.text.trim(),
          );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.product != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? '编辑商品' : '新建商品',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              autofocus: !editing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '商品名称',
                hintText: '例如：牛奶、洗衣液、大米',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写商品名称' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(
                labelText: '计量单位',
                border: OutlineInputBorder(),
              ),
              items: unitOptions
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _unit = v);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(editing ? '保存' : '创建'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Offer?> showOfferForm(
  BuildContext context, {
  Offer? offer,
  required String unit,
}) {
  return showModalBottomSheet<Offer>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _OfferFormSheet(offer: offer, unit: unit),
  );
}

class _OfferFormSheet extends StatefulWidget {
  const _OfferFormSheet({this.offer, required this.unit});

  final Offer? offer;
  final String unit;

  @override
  State<_OfferFormSheet> createState() => _OfferFormSheetState();
}

class _OfferFormSheetState extends State<_OfferFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brand;
  late final TextEditingController _price;
  late final TextEditingController _quantity;
  late final TextEditingController _shop;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final o = widget.offer;
    _brand = TextEditingController(text: o?.brand ?? '');
    _price = TextEditingController(
      text: o == null ? '' : _fmt(o.price),
    );
    _quantity = TextEditingController(
      text: o == null ? '' : _fmt(o.quantity),
    );
    _shop = TextEditingController(text: o?.shop ?? '');
    _note = TextEditingController(text: o?.note ?? '');
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    _brand.dispose();
    _price.dispose();
    _quantity.dispose();
    _shop.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(_price.text.trim());
    final quantity = double.parse(_quantity.text.trim());
    final base = widget.offer;
    final result = base == null
        ? Offer(
            brand: _brand.text.trim(),
            price: price,
            quantity: quantity,
            shop: _shop.text.trim(),
            note: _note.text.trim(),
          )
        : base.copyWith(
            brand: _brand.text.trim(),
            price: price,
            quantity: quantity,
            shop: _shop.text.trim(),
            note: _note.text.trim(),
          );
    Navigator.of(context).pop(result);
  }

  String? _positiveNumber(String? v) {
    if (v == null || v.trim().isEmpty) return '请填写';
    final n = double.tryParse(v.trim());
    if (n == null) return '请输入数字';
    if (n <= 0) return '需大于 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final editing = widget.offer != null;
    final unit = widget.unit;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? '编辑报价' : '添加报价',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brand,
              autofocus: !editing,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '品牌 / 规格名',
                hintText: '例如：伊利金典、蓝月亮',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '请填写品牌' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: '总价（元）',
                      border: OutlineInputBorder(),
                    ),
                    validator: _positiveNumber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: '数量（$unit）',
                      border: const OutlineInputBorder(),
                    ),
                    validator: _positiveNumber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _shop,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: '购买渠道（可选）',
                hintText: '超市 / 电商 / 本地店',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _submit,
              child: Text(editing ? '保存' : '添加'),
            ),
          ],
        ),
      ),
    );
  }
}
