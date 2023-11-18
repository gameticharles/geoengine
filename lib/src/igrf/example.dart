import 'igrf_utils.dart' as iut;
import 'io_options.dart' as ioo;

void main() {
  var igrf = iut.loadSHCFile('assets/data/igrf_model/IGRF13.shc');

  print(' ');
  print('******************************************************');
  print('*              IGRF SYNTHESIS PROGRAM                *');
  print('*                                                    *');
  print('* A program for the computation of geomagnetic       *');
  print('* field elements from the International Geomagnetic  *');
  print('* Reference Field (13th generation) as revised in    *');
  print('* December 2019 by the IAGA Working Group V-MOD.     *');
  print('*                                                    *');
  print('* It is valid for dates from 1900.0 to 2025.0;       *');
  print('* values up to 2030.0 will be computed with          *');
  print('* reduced accuracy. Values for dates before 1945.0   *');
  print('* and after 2015.0 are non-definitive, otherwise     *');
  print('* the values are definitive.                         *');
  print('*                                                    *');
  print('*                                                    *');
  print('*            (on behalf of) IAGA Working Group V-MOD *');
  print('******************************************************');
  print(' ');
  print('Enter name of output file');
  print('or press "Return" for output to screen');

  print('Enter name of output file or press "Return" for output to screen');
  var name = ''; // stdin.readLineSync();

  // int iopt;
  // while (true) {
  //   print('Choose an option:');
  //   print('1 - values at one location and date');
  //   print('2 - values at yearly intervals at one location');
  //   print('3 - values on a latitude/longitude grid at one date');
  //   iopt = int.tryParse(stdin.readLineSync()!) ?? 0;
  //   if (iopt < 1 || iopt > 3) {
  //     continue;
  //   } else {
  //     break;
  //   }
  // }

  int iopt = 1;

  List<dynamic> result;

  // Parse the inputs for computing the main field and SV values.
  // Convert geodetic to geocentric coordinates if required
  if (iopt == 1) {
    // (date, alt, lat, colat, lon, itype, sd, cd) = ioo.option1();
    result = ioo.option1();
  } else if (iopt == 2) {
    //(date, alt, lat, colat, lon, itype, sd, cd) = ioo.option2();
    result = ioo.option2();
  } else {
    //(date, alt, lat, colat, lon, itype, sd, cd) = ioo.option3();
    result = ioo.option3();
  }

  print(igrf.time);

  // Interpolate the geomagnetic coefficients to the desired date(s)
  // -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
  // var f = Interp1D(igrf.time, igrf.coeffs, fillValue: 'extrapolate');
  // var coeffs = f(date);
/*
    // Compute the main field B_r, B_theta and B_phi value for the location(s) 
    var Br, Bt, Bp = iut.synthValues(coeffs.T, alt, colat, lon,
                              igrf.parameters['nmax']);
    
    // For the SV, find the 5 year period in which the date lies and compute
    // the SV within that period. IGRF has constant SV between each 5 year period
    // We don't need to subtract 1900 but it makes it clearer:
    var epoch = (date-1900)~/5 ;   
    var epoch_start = epoch*5;
    // Add 1900 back on plus 1 year to account for SV in nT per year (nT/yr):
    var coeffs_sv = f(1900+epoch_start+1) - f(1900+epoch_start);   
    var Brs, Bts, Bps = iut.synthValues(coeffs_sv.T, alt, colat, lon,
                              igrf.parameters['nmax']);
    
    // Use the main field coefficients from the start of each five epoch
    // to compute the SV for Dec, Inc, Hor and Total Field (F) 
    // [Note: these are non-linear components of X, Y and Z so treat separately]
    var coeffsm = f(1900+epoch_start);
    var Brm, Btm, Bpm = iut.synthValues(coeffsm.T, alt, colat, lon,
                              igrf.parameters['nmax']);
    
    
    // Rearrange to X, Y, Z components 
    var X = -Bt; 
    var Y = Bp; 
    var Z = -Br;

    // For the SV
    var dX = -Bts; 
    var dY = Bps; 
    var dZ = -Brs ;
    var Xm = -Btm; 
    var Ym = Bpm;
    var Zm = -Brm;

    // Rotate back to geodetic coords if needed
    if (itype == 1){
        t = X; 
        X = X*cd + Z*sd;  
        Z = Z*cd - t*sd;
        t = dX; dX = dX*cd + dZ*sd;  dZ = dZ*cd - t*sd;
        t = Xm; Xm = Xm*cd + Zm*sd;  Zm = Zm*cd - t*sd;}
        
    // Compute the four non-linear components 
    var res = iut.xyz2dhif(X,Y,Z);
    double dec=res[0]; 
    double hoz=res[1]; 
    double inc=res[2];
    double eff =res[3];

    // The IGRF SV coefficients are relative to the main field components 
    // at the start of each five year epoch e.g. 2010, 2015, 2020
    decs, hozs, incs, effs = iut.xyz2dhif_sv(Xm, Ym, Zm, dX, dY, dZ);
    
    
    // Finally, parse the outputs for writing to screen or file
    if (iopt == 1){
        ioo.write1(name, date, alt, lat, colat, lon, X, Y, Z, dX, dY, dZ, 
                  dec, hoz, inc, eff, decs, hozs, incs, effs, itype);
        if (name != null) {
          print('Written to file: $name' );
        }
    }else if (iopt == 2){
        ioo.write2(name, date, alt, lat, colat, lon, X, Y, Z, dX, dY, dZ, 
                  dec, hoz, inc, eff, decs, hozs, incs, effs, itype);
        if (name != null) {
          print('Written to file: $name' );
        }
    } else{
        ioo.write3(name, date, alt, lat, colat, lon, X, Y, Z, dX, dY, dZ, 
                  dec, hoz, inc, eff, decs, hozs, incs, effs, itype);
        if (name != null) {
          print('Written to file: $name' );
        }
    }
    */
}
