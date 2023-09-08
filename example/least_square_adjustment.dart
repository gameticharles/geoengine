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
  var W = Diagonal([1 / 16, 1 / 9, 1 / 49, 1 / 36, 1 / 16, 1 / 9, 1 / 25]);
  var B = Column([0, 0, 0.13, 0, 0, -0.32, -0.53]);

  var lsa = LeastSquaresAdjustment(A: A, B: B, W: W, confidenceLevel: 50);
  var c = lsa.chiSquareTest();
  print(c);
  print(lsa.getResults());

  // var batchResults = LeastSquaresAdjustment.batchAdjust(
  //     As: [A, A, A],
  //     Bs: [B, B, B],
  //     Ws: [W, W, W],
  //     confidenceLevels: [99.9, 50, 30]);

  // // Access individual LeastSquaresAdjustment objects to get results
  // var firstResult = batchResults[0];
  // print(firstResult.getResults());
}
