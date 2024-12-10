part of 'astronomy.dart';

/// @brief Information about idealized atmospheric variables at a given elevation.
///
/// @property {number} pressure
///      Atmospheric pressure in pascals.
///
/// @property {number} temperature
///      Atmospheric temperature in kelvins.
///
/// @property {number} density
///      Atmospheric density relative to sea level.
class AtmosphereInfo {
  final double pressure;
  final double temperature;
  final double density;

  AtmosphereInfo(this.pressure, this.temperature, this.density);
}

/// @brief Calculates U.S. Standard Atmosphere (1976) variables as a function of elevation.
///
/// This function calculates idealized values of pressure, temperature, and density
/// using the U.S. Standard Atmosphere (1976) model.
/// 1. COESA, U.S. Standard Atmosphere, 1976, U.S. Government Printing Office, Washington, DC, 1976.
/// 2. Jursa, A. S., Ed., Handbook of Geophysics and the Space Environment, Air Force Geophysics Laboratory, 1985.
/// See:
/// https://hbcp.chemnetbase.com/faces/documents/14_12/14_12_0001.xhtml
/// https://ntrs.nasa.gov/api/citations/19770009539/downloads/19770009539.pdf
/// https://www.ngdc.noaa.gov/stp/space-weather/online-publications/miscellaneous/us-standard-atmosphere-1976/us-standard-atmosphere_st76-1562_noaa.pdf
///
/// @param {number} elevationMeters
///      The elevation above sea level at which to calculate atmospheric variables.
///      Must be in the range -500 to +100000, or an exception will occur.
///
/// @returns {AtmosphereInfo}
AtmosphereInfo atmosphere(double elevationMeters) {
  const double P0 = 101325.0; // pressure at sea level [pascals]
  const double T0 = 288.15; // temperature at sea level [kelvins]
  const double T1 = 216.65; // temperature between 20 km and 32 km [kelvins]

  if (!elevationMeters.isFinite ||
      elevationMeters < -500.0 ||
      elevationMeters > 100000.0) {
    throw Exception('Invalid elevation: $elevationMeters');
  }

  double temperature;
  double pressure;
  if (elevationMeters <= 11000.0) {
    temperature = T0 - 0.0065 * elevationMeters;
    pressure = P0 * pow(T0 / temperature, -5.25577);
  } else if (elevationMeters <= 20000.0) {
    temperature = T1;
    pressure = 22632.0 * exp(-0.00015768832 * (elevationMeters - 11000.0));
  } else {
    temperature = T1 + 0.001 * (elevationMeters - 20000.0);
    pressure = 5474.87 * pow(T1 / temperature, 34.16319);
  }

  // Calculate density relative to sea level value
  final density = (pressure / temperature) / (P0 / T0);

  return AtmosphereInfo(pressure, temperature, density);
}
