import 'package:advance_math/advance_math.dart';
import 'package:test/test.dart';

void main() {
  test('calculate', () {
    var t = Triangle(a: 3, b: 4, c: 5);
    expect(t.area(AreaMethod.heron), 6);
  });
}
