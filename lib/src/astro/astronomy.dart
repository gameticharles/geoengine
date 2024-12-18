/*

    Astronomy library for JavaScript (browser and Node.js).
    https://github.com/cosinekitty/astronomy

    MIT License

    Copyright (c) 2019-2023 Don Cross <cosinekitty@gmail.com>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

library;

import 'package:advance_math/advance_math.dart';

part 'constant.dart';
part 'common.dart';
part 'time/astro_time.dart';
part 'time/sidereal_time.dart';
part 'earth_tilt_info.dart';
part 'other_classes.dart';
part 'season.dart';
part 'apsis.dart';
part 'atmosphere.dart';
part 'transit.dart';
part 'elongation.dart';

part 'body/body.dart';
part 'body/moon/libration.dart';
part 'body/moon/moon_phase.dart';
part 'body/moon/moon.dart';
part 'body/pluto.dart';
part 'body/saturn.dart';

part 'body/jupiter/jupiter.dart';

part 'eclipse/shadow.dart';
part 'eclipse/eclipse.dart';

part 'models/rotation_matrix.dart';
part 'models/state_vector.dart';
part 'models/astro_vector.dart';
part 'models/coordinates.dart';
part 'models/gravity_sim.dart';
part 'models/axis_info.dart';
part 'models/constellation.dart';
part 'models/illumination.dart';

part 'observer.dart';
part 'enums.dart';

typedef ShadowFunc = double Function(ShadowInfo shadow);

void main() {
  //bruteSearchPlanetApsis(Body.Mercury, AstroTime(34.22)).dist_km;
  print(nextTransit(Body.Venus, DateTime.now()).finish);
  AstroTime time = AstroTime(64473.24);

  // print( rotationAxis(Body.Mars, time).dec);

  print(StateVector.lagrangePoint(1, time, Body.Earth, Body.Moon).y);
  //0.0010824860086227986

  // print(NodeEventKind.index());
}
