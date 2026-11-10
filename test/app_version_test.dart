import 'package:flutter_test/flutter_test.dart';
import 'package:zhidang/app/app_version.dart';

void main() {
  test('display version keeps only major and minor', () {
    expect(displayVersion('0.10.0'), '0.10');
    expect(displayVersion('0.10.3+12'), '0.10');
    expect(displayVersion('1.2'), '1.2');
  });
}
