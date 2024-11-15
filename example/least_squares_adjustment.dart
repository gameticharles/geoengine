import 'package:advance_math/advance_math.dart';
import 'package:geoengine/geoengine.dart';

void main(List<String> args) {
  var A = Matrix([
    [-1, 0, 0, 0],
    [-1, 1, 0, 0],
    [0, -1, 1, 0],
    [0, 0, -1, 0],
    [0, 0, -1, 1],
    [0, 0, 0, -1],
    [1, 0, 0, -1],
  ]);
  var W =
      DiagonalMatrix([1 / 16, 1 / 9, 1 / 49, 1 / 36, 1 / 16, 1 / 9, 1 / 25]);
  var B = ColumnMatrix([0, 0, 0.13, 0, 0, -0.32, -0.53]);

  var lsa = LeastSquaresAdjustment(A: A, B: B, W: W, confidenceLevel: 40);
  print(lsa);

  print(lsa.qxx);
}
