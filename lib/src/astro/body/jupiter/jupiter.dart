part of '../../astronomy.dart';

class JupiterMoonT {
  final double mu;
  final List<double> al;
  final List<List<double>> a;
  final List<List<double>> l;
  final List<List<double>> z;
  final List<List<double>> zeta;

  JupiterMoonT({
    required this.mu,
    required this.al,
    required this.a,
    required this.l,
    required this.z,
    required this.zeta,
  });
}

/// @brief Holds the positions and velocities of Jupiter's major 4 moons.
///
/// The {@link JupiterMoons} function returns an object of this type
/// to report position and velocity vectors for Jupiter's largest 4 moons
/// Io, Europa, Ganymede, and Callisto. Each position vector is relative
/// to the center of Jupiter. Both position and velocity are oriented in
/// the EQJ system (that is, using Earth's equator at the J2000 epoch).
/// The positions are expressed in astronomical units (AU),
/// and the velocities in AU/day.
///
/// @property {StateVector} io
///      The position and velocity of Jupiter's moon Io.
///
/// @property {StateVector} europa
///      The position and velocity of Jupiter's moon Europa.
///
/// @property {StateVector} ganymede
///      The position and velocity of Jupiter's moon Ganymede.
///
/// @property {StateVector} callisto
///      The position and velocity of Jupiter's moon Callisto.
class JupiterMoonsInfo {
  final StateVector io;
  final StateVector europa;
  final StateVector ganymede;
  final StateVector callisto;

  JupiterMoonsInfo({
    required this.io,
    required this.europa,
    required this.ganymede,
    required this.callisto,
  });
}

final List<JupiterMoonT> JupiterMoonModel = [
  JupiterMoonT(
      // [0] Io

      mu: 2.8248942843381399e-07,
      al: [
        1.4462132960212239e+00,
        3.5515522861824000e+00
      ],
      a: [
        [0.0028210960212903, 0.0000000000000000e+00, 0.0000000000000000e+00]
      ],
      l: [
        [-0.0001925258348666, 4.9369589722644998e+00, 1.3584836583050000e-02],
        [-0.0000970803596076, 4.3188796477322002e+00, 1.3034138432430000e-02],
        [-0.0000898817416500, 1.9080016428616999e+00, 3.0506486715799999e-03],
        [-0.0000553101050262, 1.4936156681568999e+00, 1.2938928911549999e-02]
      ],
      z: [
        [0.0041510849668155, 4.0899396355450000e+00, -1.2906864146660001e-02],
        [0.0006260521444113, 1.4461888986270000e+00, 3.5515522949801999e+00],
        [0.0000352747346169, 2.1256287034577999e+00, 1.2727416566999999e-04]
      ],
      zeta: [
        [0.0003142172466014, 2.7964219722923001e+00, -2.3150960980000000e-03],
        [0.0000904169207946, 1.0477061879627001e+00, -5.6920638196000003e-04]
      ]),

  // [1] Europa
  JupiterMoonT(mu: 2.8248327439289299e-07, al: [
    -3.7352634374713622e-01,
    1.7693227111234699e+00
  ], a: [
    [0.0044871037804314, 0.0000000000000000e+00, 0.0000000000000000e+00],
    [0.0000004324367498, 1.8196456062910000e+00, 1.7822295777568000e+00]
  ], l: [
    [0.0008576433172936, 4.3188693178264002e+00, 1.3034138308049999e-02],
    [0.0004549582875086, 1.4936531751079001e+00, 1.2938928819619999e-02],
    [0.0003248939825174, 1.8196494533458001e+00, 1.7822295777568000e+00],
    [-0.0003074250079334, 4.9377037005910998e+00, 1.3584832867240000e-02],
    [0.0001982386144784, 1.9079869054759999e+00, 3.0510121286900001e-03],
    [0.0001834063551804, 2.1402853388529000e+00, 1.4500978933800000e-03],
    [-0.0001434383188452, 5.6222140366630002e+00, 8.9111478887838003e-01],
    [-0.0000771939140944, 4.3002724372349999e+00, 2.6733443704265998e+00]
  ], z: [
    [-0.0093589104136341, 4.0899396509038999e+00, -1.2906864146660001e-02],
    [0.0002988994545555, 5.9097265185595003e+00, 1.7693227079461999e+00],
    [0.0002139036390350, 2.1256289300016000e+00, 1.2727418406999999e-04],
    [0.0001980963564781, 2.7435168292649998e+00, 6.7797343008999997e-04],
    [0.0001210388158965, 5.5839943711203004e+00, 3.2056614899999997e-05],
    [0.0000837042048393, 1.6094538368039000e+00, -9.0402165808846002e-01],
    [0.0000823525166369, 1.4461887708689001e+00, 3.5515522949801999e+00]
  ], zeta: [
    [0.0040404917832303, 1.0477063169425000e+00, -5.6920640539999997e-04],
    [0.0002200421034564, 3.3368857864364001e+00, -1.2491307306999999e-04],
    [0.0001662544744719, 2.4134862374710999e+00, 0.0000000000000000e+00],
    [0.0000590282470983, 5.9719930968366004e+00, -3.0561602250000000e-05]
  ]),

  // [2] Ganymede
  JupiterMoonT(mu: 2.8249818418472298e-07, al: [
    2.8740893911433479e-01,
    8.7820792358932798e-01
  ], a: [
    [0.0071566594572575, 0.0000000000000000e+00, 0.0000000000000000e+00],
    [0.0000013930299110, 1.1586745884981000e+00, 2.6733443704265998e+00]
  ], l: [
    [0.0002310797886226, 2.1402987195941998e+00, 1.4500978438400001e-03],
    [-0.0001828635964118, 4.3188672736968003e+00, 1.3034138282630000e-02],
    [0.0001512378778204, 4.9373102372298003e+00, 1.3584834812520000e-02],
    [-0.0001163720969778, 4.3002659861490002e+00, 2.6733443704265998e+00],
    [-0.0000955478069846, 1.4936612842567001e+00, 1.2938928798570001e-02],
    [0.0000815246854464, 5.6222137132535002e+00, 8.9111478887838003e-01],
    [-0.0000801219679602, 1.2995922951532000e+00, 1.0034433456728999e+00],
    [-0.0000607017260182, 6.4978769669238001e-01, 5.0172167043264004e-01]
  ], z: [
    [0.0014289811307319, 2.1256295942738999e+00, 1.2727413029000001e-04],
    [0.0007710931226760, 5.5836330003496002e+00, 3.2064341100000001e-05],
    [0.0005925911780766, 4.0899396636447998e+00, -1.2906864146660001e-02],
    [0.0002045597496146, 5.2713683670371996e+00, -1.2523544076106000e-01],
    [0.0001785118648258, 2.8743156721063001e-01, 8.7820792442520001e-01],
    [0.0001131999784893, 1.4462127277818000e+00, 3.5515522949801999e+00],
    [-0.0000658778169210, 2.2702423990985001e+00, -1.7951364394536999e+00],
    [0.0000497058888328, 5.9096792204858000e+00, 1.7693227129285001e+00]
  ], zeta: [
    [0.0015932721570848, 3.3368862796665000e+00, -1.2491307058000000e-04],
    [0.0008533093128905, 2.4133881688166001e+00, 0.0000000000000000e+00],
    [0.0003513347911037, 5.9720789850126996e+00, -3.0561017709999999e-05],
    [-0.0001441929255483, 1.0477061764435001e+00, -5.6920632124000004e-04]
  ]),

  // [3] Callisto
  JupiterMoonT(mu: 2.8249214488990899e-07, al: [
    -3.6203412913757038e-01,
    3.7648623343382798e-01
  ], a: [
    [0.0125879701715314, 0.0000000000000000e+00, 0.0000000000000000e+00],
    [0.0000035952049470, 6.4965776007116005e-01, 5.0172168165034003e-01],
    [0.0000027580210652, 1.8084235781510001e+00, 3.1750660413359002e+00]
  ], l: [
    [0.0005586040123824, 2.1404207189814999e+00, 1.4500979323100001e-03],
    [-0.0003805813868176, 2.7358844897852999e+00, 2.9729650620000000e-05],
    [0.0002205152863262, 6.4979652596399995e-01, 5.0172167243580001e-01],
    [0.0001877895151158, 1.8084787604004999e+00, 3.1750660413359002e+00],
    [0.0000766916975242, 6.2720114319754998e+00, 1.3928364636651001e+00],
    [0.0000747056855106, 1.2995916202344000e+00, 1.0034433456728999e+00]
  ], z: [
    [0.0073755808467977, 5.5836071576083999e+00, 3.2065099140000001e-05],
    [0.0002065924169942, 5.9209831565786004e+00, 3.7648624194703001e-01],
    [0.0001589869764021, 2.8744006242622999e-01, 8.7820792442520001e-01],
    [-0.0001561131605348, 2.1257397865089001e+00, 1.2727441285000001e-04],
    [0.0001486043380971, 1.4462134301023000e+00, 3.5515522949801999e+00],
    [0.0000635073108731, 5.9096803285953996e+00, 1.7693227129285001e+00],
    [0.0000599351698525, 4.1125517584797997e+00, -2.7985797954588998e+00],
    [0.0000540660842731, 5.5390350845569003e+00, 2.8683408228299999e-03],
    [-0.0000489596900866, 4.6218149483337996e+00, -6.2695712529518999e-01]
  ], zeta: [
    [0.0038422977898495, 2.4133922085556998e+00, 0.0000000000000000e+00],
    [0.0022453891791894, 5.9721736773277003e+00, -3.0561255249999997e-05],
    [-0.0002604479450559, 3.3368746306408998e+00, -1.2491309972000001e-04],
    [0.0000332112143230, 5.5604137742336999e+00, 2.9003768850700000e-03]
  ])
];

StateVector JupiterMoon_elem2pv(AstroTime time, double mu, List<double> elem) {
  // Dart doesn't support destructuring directly in function parameters like TypeScript,
  // so accessing elements from the list directly by index.

  double A = elem[0];
  double AL = elem[1];
  double K = elem[2];
  double H = elem[3];
  double Q = elem[4];
  double P = elem[5];

  double AN = sqrt(mu / (A * A * A));

  double CE, SE, DE;
  double EE = AL + K * sin(AL) - H * cos(AL);
  do {
    CE = cos(EE);
    SE = sin(EE);
    DE = (AL - EE + K * SE - H * CE) / (1.0 - K * CE - H * SE);
    EE += DE;
  } while (DE.abs() >= 1.0e-12);

  CE = cos(EE);
  SE = sin(EE);
  double DLE = H * CE - K * SE;
  double RSAM1 = -K * CE - H * SE;
  double ASR = 1.0 / (1.0 + RSAM1);
  double PHI = sqrt(1.0 - K * K - H * H);
  double PSI = 1.0 / (1.0 + PHI);
  double X1 = A * (CE - K - PSI * H * DLE);
  double Y1 = A * (SE - H + PSI * K * DLE);
  double VX1 = AN * ASR * A * (-SE - PSI * H * RSAM1);
  double VY1 = AN * ASR * A * (CE + PSI * K * RSAM1);
  double F2 = 2.0 * sqrt(1.0 - Q * Q - P * P);
  double P2 = 1.0 - 2.0 * P * P;
  double Q2 = 1.0 - 2.0 * Q * Q;
  double PQ = 2.0 * P * Q;

  return StateVector(
    X1 * P2 + Y1 * PQ,
    X1 * PQ + Y1 * Q2,
    (Q * Y1 - X1 * P) * F2,
    VX1 * P2 + VY1 * PQ,
    VX1 * PQ + VY1 * Q2,
    (Q * VY1 - VX1 * P) * F2,
    time,
  );
}



StateVector CalcJupiterMoon(AstroTime time, JupiterMoonT m) {
  final double t =
      time.tt + 18262.5; // number of days since 1950-01-01T00:00:00Z

  // Calculate 6 orbital elements at the given time t
  List<double> elem = [0, m.al[0] + (t * m.al[1]), 0, 0, 0, 0];

  for (var term in m.a) {
    double amplitude = term[0];
    double phase = term[1];
    double frequency = term[2];
    elem[0] += amplitude * cos(phase + (t * frequency));
  }

  for (var term in m.l) {
    double amplitude = term[0];
    double phase = term[1];
    double frequency = term[2];
    elem[1] += amplitude * sin(phase + (t * frequency));
  }

  elem[1] %= PI2;
  if (elem[1] < 0) elem[1] += PI2;

  for (var term in m.z) {
    double amplitude = term[0];
    double phase = term[1];
    double frequency = term[2];
    double arg = phase + (t * frequency);
    elem[2] += amplitude * cos(arg);
    elem[3] += amplitude * sin(arg);
  }

  for (var term in m.zeta) {
    double amplitude = term[0];
    double phase = term[1];
    double frequency = term[2];
    double arg = phase + (t * frequency);
    elem[4] += amplitude * cos(arg);
    elem[5] += amplitude * sin(arg);
  }

  // Convert the orbital elements into position vectors in the Jupiter equatorial system (JUP).
  StateVector state = JupiterMoon_elem2pv(time, m.mu, elem);

  // Re-orient position and velocity vectors from Jupiter-equatorial (JUP) to Earth-equatorial in J2000 (EQJ).
  return StateVector.rotateState(RotationMatrix.rotationJUPtoEQJ, state);
}

/// @brief Calculates jovicentric positions and velocities of Jupiter's largest 4 moons.
///
/// Calculates position and velocity vectors for Jupiter's moons
/// Io, Europa, Ganymede, and Callisto, at the given date and time.
/// The vectors are jovicentric (relative to the center of Jupiter).
/// Their orientation is the Earth's equatorial system at the J2000 epoch (EQJ).
/// The position components are expressed in astronomical units (AU), and the
/// velocity components are in AU/day.
///
/// To convert to heliocentric vectors, call {@link HelioVector}
/// with `Astronomy.Body.Jupiter` to get Jupiter's heliocentric position, then
/// add the jovicentric vectors. Likewise, you can call {@link GeoVector}
/// to convert to geocentric vectors.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to calculate Jupiter's moons.
///
/// @return {JupiterMoonsInfo}
///      Position and velocity vectors of Jupiter's largest 4 moons.
JupiterMoonsInfo JupiterMoons(dynamic date) {
  AstroTime time = AstroTime(date);

  return JupiterMoonsInfo(
    io: CalcJupiterMoon(time, JupiterMoonModel[0]),
    europa: CalcJupiterMoon(time, JupiterMoonModel[1]),
    ganymede: CalcJupiterMoon(time, JupiterMoonModel[2]),
    callisto: CalcJupiterMoon(time, JupiterMoonModel[3]),
  );
}
