part of '../astronomy.dart';

class SiderealTimeInfo {
  final double tt;
  final double st;

  SiderealTimeInfo(this.tt, this.st);
}

SiderealTimeInfo? siderealTimeCache;

double _siderealTime(AstroTime time) {
  // calculates Greenwich Apparent Sidereal Time (GAST)
  if (siderealTimeCache == null || siderealTimeCache!.tt != time.tt) {
    final t = time.tt / 36525.0;
    final eqeq = 15 *
        eTilt(time)
            .ee; // Replace with eqeq = 0 to get GMST instead of GAST (if we ever need it)
    final theta = era(time);
    final st = (eqeq +
        0.014506 +
        ((((-0.0000000368 * t - 0.000029956) * t - 0.00000044) * t +
                        1.3915817) *
                    t +
                4612.156534) *
            t);

    var gst = ((st / 3600 + theta) % 360) / 15;
    if (gst < 0) {
      gst += 24;
    }
    siderealTimeCache = SiderealTimeInfo(time.tt, gst);
  }
  return siderealTimeCache!
      .st; // Return sidereal hours in the half-open range [0, 24).
}

/// @brief Calculates Greenwich Apparent Sidereal Time (GAST).
///
/// Given a date and time, this function calculates the rotation of the
/// Earth, represented by the equatorial angle of the Greenwich prime meridian
/// with respect to distant stars (not the Sun, which moves relative to background
/// stars by almost one degree per day).
/// This angle is called Greenwich Apparent Sidereal Time (GAST).
/// GAST is measured in sidereal hours in the half-open range [0, 24).
/// When GAST = 0, it means the prime meridian is aligned with the of-date equinox,
/// corrected at that time for precession and nutation of the Earth's axis.
/// In this context, the "equinox" is the direction in space where the Earth's
/// orbital plane (the ecliptic) intersects with the plane of the Earth's equator,
/// at the location on the Earth's orbit of the (seasonal) March equinox.
/// As the Earth rotates, GAST increases from 0 up to 24 sidereal hours,
/// then starts over at 0.
/// To convert to degrees, multiply the return value by 15.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to find GAST.
///
/// @returns {number}
double siderealTime(dynamic date) {
  final time = AstroTime(date);
  return _siderealTime(time);
}
