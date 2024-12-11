part of '../astronomy.dart';

/// @brief Holds a time and the observed altitude of the Sun at that time.
///
/// When reporting a solar eclipse observed at a specific location on the Earth
/// (a "local" solar eclipse), a series of events occur. In addition
/// to the time of each event, it is important to know the altitude of the Sun,
/// because each event may be invisible to the observer if the Sun is below
/// the horizon.
///
/// If `altitude` is negative, the event is theoretical only; it would be
/// visible if the Earth were transparent, but the observer cannot actually see it.
/// If `altitude` is positive but less than a few degrees, visibility will be impaired by
/// atmospheric interference (sunrise or sunset conditions).
///
/// @property {AstroTime} time
///      The date and time of the event.
///
/// @property {number} altitude
///      The angular altitude of the center of the Sun above/below the horizon, at `time`,
///      corrected for atmospheric refraction and expressed in degrees.
class EclipseEvent {
  AstroTime time;
  double altitude;

  EclipseEvent(this.time, this.altitude);
}

abstract class EclipseInfo {
  EclipseKind kind;
  double? obscuration;

  /// @brief The date and time of the eclipse peak.
  ///
  /// @type {AstroTime} for GlobalSolarEclipseInfo and LunarEclipseInfo
  /// @type {EclipseEvent} for LocalSolarEclipseInfo
  dynamic peak;

  EclipseInfo(this.kind, this.obscuration, this.peak);
}

/// @brief Returns information about a lunar eclipse.
///
/// Returned by {@link SearchLunarEclipse} or {@link NextLunarEclipse}
/// to report information about a lunar eclipse event.
/// When a lunar eclipse is found, it is classified as penumbral, partial, or total.
/// Penumbral eclipses are difficult to observe, because the Moon is only slightly dimmed
/// by the Earth's penumbra; no part of the Moon touches the Earth's umbra.
/// Partial eclipses occur when part, but not all, of the Moon touches the Earth's umbra.
/// Total eclipses occur when the entire Moon passes into the Earth's umbra.
///
/// The `kind` field thus holds one of the enum values `EclipseKind.Penumbral`, `EclipseKind.Partial`,
/// or `EclipseKind.Total`, depending on the kind of lunar eclipse found.
///
/// The `obscuration` field holds a value in the range [0, 1] that indicates what fraction
/// of the Moon's apparent disc area is covered by the Earth's umbra at the eclipse's peak.
/// This indicates how dark the peak eclipse appears. For penumbral eclipses, the obscuration
/// is 0, because the Moon does not pass through the Earth's umbra. For partial eclipses,
/// the obscuration is somewhere between 0 and 1. For total lunar eclipses, the obscuration is 1.
///
/// Field `peak` holds the date and time of the peak of the eclipse, when it is at its peak.
///
/// Fields `sd_penum`, `sd_partial`, and `sd_total` hold the semi-duration of each phase
/// of the eclipse, which is half of the amount of time the eclipse spends in each
/// phase (expressed in minutes), or 0 if the eclipse never reaches that phase.
/// By converting from minutes to days, and subtracting/adding with `peak`, the caller
/// may determine the date and time of the beginning/end of each eclipse phase.
///
/// @property {EclipseKind} kind
///      The type of lunar eclipse found.
///
/// @property {number} obscuration
///      The peak fraction of the Moon's apparent disc that is covered by the Earth's umbra.
///
/// @property {AstroTime} peak
///      The time of the eclipse at its peak.
///
/// @property {number} sdPenum
///      The semi-duration of the penumbral phase in minutes.
///
/// @property {number} sdPartial
///      The semi-duration of the penumbral phase in minutes, or 0.0 if none.
///
/// @property {number} sdTotal
///      The semi-duration of the penumbral phase in minutes, or 0.0 if none.
///
class LunarEclipseInfo extends EclipseInfo {
  static const double _minutesPerDay = 24 * 60;

  double sdPenum;
  double sdPartial;
  double sdTotal;
  double? magnitude;

  LunarEclipseInfo(
    super.kind,
    super.obscuration,
    super.peak,
    this.sdPenum,
    this.sdPartial,
    this.sdTotal, {
    this.magnitude,
  });

  /// Formats a number with leading zeros to match the specified width
  String _pad(num number, int width) {
    return number.toStringAsFixed(0).padLeft(width, '0');
  }

  /// Formats an AstroTime object into a readable UTC string
  String _formatDateTime(AstroTime time) {
    final date = time.date;
    return '${_pad(date.year, 4)}-${_pad(date.month, 2)}-${_pad(date.day, 2)} '
        '${_pad(date.hour, 2)}:${_pad(date.minute, 2)}:${_pad(date.second, 2)}'
        '.${_pad(date.millisecond, 3)} UTC';
  }

  /// Converts minutes to a human-readable duration string
  String _formatDuration(double minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = (minutes % 60).round();

    if (hours > 0 && remainingMinutes > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}, $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      return '$remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
    }
  }

  /// Gets the start time of the partial eclipse phase
  AstroTime get partialBegin => peak.addDays(-sdPartial / _minutesPerDay);

  /// Gets the start time of the total eclipse phase (if applicable)
  AstroTime? get totalBegin =>
      sdTotal > 0 ? peak.addDays(-sdTotal / _minutesPerDay) : null;

  /// Gets the end time of the total eclipse phase (if applicable)
  AstroTime? get totalEnd =>
      sdTotal > 0 ? peak.addDays(sdTotal / _minutesPerDay) : null;

  /// Gets the end time of the partial eclipse phase
  AstroTime get partialEnd => peak.addDays(sdPartial / _minutesPerDay);

  /// Gets the overall eclipse duration
  double get overallDuration => (2 * sdPenum +
      2 * sdPartial +
      2 * sdTotal); // Convert semi-durations to full durations.

  double get totalityDuration =>
      sdTotal * 2; // Convert semi-duration to full duration.

  /// Gets the obscuration percentage
  String get obscurationPercentage =>
      '${(this.obscuration! * 100).toStringAsFixed(1)}%';

  /// Calculates penumbral magnitude
  double get penumbraMagnitude =>
      magnitude ?? ((overallDuration / (_minutesPerDay * 2)) * 2.5);

  /// Creates a formatted string for an eclipse phase
  String _formatPhase(String phase, AstroTime time) =>
      '${_formatDateTime(time)} - $phase';

  @override
  String toString() {
    final buffer = StringBuffer();

    // Eclipse type and obscuration
    buffer.writeln('${kind.name} Lunar Eclipse');
    buffer.writeln('Peak Moon obscuration: $obscurationPercentage');
    buffer.writeln();

    // Timeline of events
    buffer.writeln('Timeline:');
    if (sdPenum > 0) {
      final penumbraBegin = peak.addDays(-sdPenum / _minutesPerDay);
      buffer.writeln(_formatPhase('Penumbral phase begins', penumbraBegin));
    }

    if (sdPartial > 0) {
      buffer.writeln(_formatPhase('Partial eclipse begins', partialBegin));
    }

    if (sdTotal > 0) {
      buffer.writeln(_formatPhase('Total eclipse begins', totalBegin!));
    }

    buffer.writeln(_formatPhase('Peak of eclipse', peak));

    if (sdTotal > 0) {
      buffer.writeln(_formatPhase('Total eclipse ends', totalEnd!));
    }

    if (sdPartial > 0) {
      buffer.writeln(_formatPhase('Partial eclipse ends', partialEnd));
    }

    if (sdPenum > 0) {
      final penumbraEnd = peak.addDays(sdPenum / _minutesPerDay);
      buffer.writeln(_formatPhase('Penumbral phase ends', penumbraEnd));
    }

    // Duration information

    buffer.writeln();
    // buffer.writeln('Duration:');
    // buffer.writeln('Overall: ${_formatDuration(overallDuration)}');
    // if (sdTotal > 0) {
    //   buffer.writeln('Total phase: ${(sdTotal * 2).toStringAsFixed(1)} minutes  | ${_formatDuration(sdTotal * 2)} ');
    // }
    // if (sdPartial > 0) {
    //   buffer.writeln('Partial phase: ${(sdPartial * 2).toStringAsFixed(1)} minutes | ${_formatDuration(sdPartial * 2)}');
    // }
    // if (sdPenum > 0) {
    //   buffer.writeln('Penumbral phase: ${(sdPenum * 2).toStringAsFixed(1)} minutes | ${_formatDuration(sdPenum  * 2)}');
    // }

    // Quick Facts
    buffer.writeln();
    buffer.writeln('**Quick Facts About This Eclipse**');
    buffer.writeln('Data | Value | Comments');
    buffer.writeln('--- | --- | ---');

    // Magnitude and Obscuration
    buffer.writeln(
        'Magnitude | ${magnitude?.toStringAsFixed(3) ?? 'N/A'} | Fraction of the Moon\'s diameter covered by Earth\'s umbra');
    buffer.writeln(
        'Obscuration | $obscurationPercentage | Percentage of the Moon\'s area covered by Earth\'s umbra');
    buffer.writeln(
        'Penumbral magnitude | ${penumbraMagnitude.toStringAsFixed(3)} | Fraction of the Moon\'s diameter covered by Earth\'s penumbra');

    // Duration details
    buffer.writeln();
    buffer.writeln(
        'Overall duration | ${_formatDuration(overallDuration)} | Period between the beginning and end of all eclipse phases');

    if (sdTotal > 0) {
      buffer.writeln(
          'Duration of totality | ${_formatDuration(sdTotal * 2)} | Period between the beginning and end of the total phase');
    }

    buffer.writeln(
        'Duration of partial phases | ${_formatDuration(sdPartial)} | Combined period of both partial phases');
    buffer.writeln(
        'Duration of penumbral phases | ${_formatDuration(sdPenum)} | Combined period of both penumbral phases');

    return buffer.toString();
  }
}

/// @brief Information about a solar eclipse as seen by an observer at a given time and geographic location.
///
/// Returned by {@link SearchLocalSolarEclipse} or {@link NextLocalSolarEclipse}
/// to report information about a solar eclipse as seen at a given geographic location.
///
/// When a solar eclipse is found, it is classified by setting `kind`
/// to `EclipseKind.Partial`, `EclipseKind.Annular`, or `EclipseKind.Total`.
/// A partial solar eclipse is when the Moon does not line up directly enough with the Sun
/// to completely block the Sun's light from reaching the observer.
/// An annular eclipse occurs when the Moon's disc is completely visible against the Sun
/// but the Moon is too far away to completely block the Sun's light; this leaves the
/// Sun with a ring-like appearance.
/// A total eclipse occurs when the Moon is close enough to the Earth and aligned with the
/// Sun just right to completely block all sunlight from reaching the observer.
///
/// The `obscuration` field reports what fraction of the Sun's disc appears blocked
/// by the Moon when viewed by the observer at the peak eclipse time.
/// This is a value that ranges from 0 (no blockage) to 1 (total eclipse).
/// The obscuration value will be between 0 and 1 for partial eclipses and annular eclipses.
/// The value will be exactly 1 for total eclipses. Obscuration gives an indication
/// of how dark the eclipse appears.
///
/// There are 5 "event" fields, each of which contains a time and a solar altitude.
/// Field `peak` holds the date and time of the center of the eclipse, when it is at its peak.
/// The fields `partial_begin` and `partial_end` are always set, and indicate when
/// the eclipse begins/ends. If the eclipse reaches totality or becomes annular,
/// `total_begin` and `total_end` indicate when the total/annular phase begins/ends.
/// When an event field is valid, the caller must also check its `altitude` field to
/// see whether the Sun is above the horizon at the time indicated by the `time` field.
/// See {@link EclipseEvent} for more information.
///
/// @property {EclipseKind} kind
///      The type of solar eclipse found: `EclipseKind.Partial`, `EclipseKind.Annular`, or `EclipseKind.Total`.
///
/// @property {number} obscuration
///      The fraction of the Sun's apparent disc area obscured by the Moon at the eclipse peak.
///
/// @property {EclipseEvent} partial_begin
///      The time and Sun altitude at the beginning of the eclipse.
///
/// @property {EclipseEvent | undefined} total_begin
///      If this is an annular or a total eclipse, the time and Sun altitude when annular/total phase begins; otherwise undefined.
///
/// @property {EclipseEvent} peak
///      The time and Sun altitude when the eclipse reaches its peak.
///
/// @property {EclipseEvent | undefined} total_end
///      If this is an annular or a total eclipse, the time and Sun altitude when annular/total phase ends; otherwise undefined.
///
/// @property {EclipseEvent} partial_end
///      The time and Sun altitude at the end of the eclipse.
class LocalSolarEclipseInfo extends EclipseInfo {
  // static const double _minutesPerDay = 24 * 60;

  final EclipseEvent partialBegin;
  final EclipseEvent? totalBegin;
  final EclipseEvent? totalEnd;
  final EclipseEvent partialEnd;

  LocalSolarEclipseInfo(
    super.kind,
    super.obscuration,
    this.partialBegin,
    this.totalBegin,
    super.peak,
    this.totalEnd,
    this.partialEnd,
  );

  /// Formats a number with leading zeros to match the specified width
  String _pad(num number, int width) {
    return number.toStringAsFixed(0).padLeft(width, '0');
  }

  /// Formats an AstroTime object into a readable UTC string
  String _formatDateTime(AstroTime time) {
    final date = time.date;
    return '${_pad(date.year, 4)}-${_pad(date.month, 2)}-${_pad(date.day, 2)} '
        '${_pad(date.hour, 2)}:${_pad(date.minute, 2)}:${_pad(date.second, 2)}'
        '.${_pad(date.millisecond, 3)} UTC';
  }

  /// Converts minutes to a human-readable duration string
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = (minutes % 60).round();

    if (hours > 0 && remainingMinutes > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}, $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      return '$remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
    }
  }

  /// Gets the duration of the totality phase
  Duration get totalityDuration {
    if (totalBegin != null && totalEnd != null) {
      return totalEnd!.time.date.difference(totalBegin!.time.date);
    }
    return Duration(); // Not a total or annular eclipse
  }

  /// Gets the duration of the partial phases
  Duration get partialDuration {
    return partialEnd.time.date.difference(partialBegin.time.date) -
        totalityDuration;
  }

  /// Gets the overall duration of the eclipse
  Duration get overallDuration {
    return partialEnd.time.date.difference(partialBegin.time.date);
  }

  /// Formats an eclipse event with altitude
  String _formatEvent(String phase, EclipseEvent event) {
    return '${_formatDateTime(event.time)} - $phase (Altitude: ${event.altitude.toStringAsFixed(1)}°)';
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    // Eclipse type and obscuration
    buffer.writeln('${kind.name} Solar Eclipse');
    buffer.writeln(
        'Peak Sun obscuration: ${(this.obscuration! * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    // Timeline of events
    buffer.writeln('Timeline:');
    buffer.writeln(_formatEvent('Partial eclipse begins', partialBegin));
    if (totalBegin != null) {
      buffer.writeln(_formatEvent('Total eclipse begins', totalBegin!));
    }
    buffer.writeln(_formatEvent(
        'Peak of eclipse', peak)); // Assuming altitude of 0° for peak
    if (totalEnd != null) {
      buffer.writeln(_formatEvent('Total eclipse ends', totalEnd!));
    }
    buffer.writeln(_formatEvent('Partial eclipse ends', partialEnd));
    buffer.writeln();

    // Duration information
    buffer.writeln('**Quick Facts About This Eclipse**');
    buffer.writeln('Data | Value | Comments');
    buffer.writeln('--- | --- | ---');
    buffer.writeln(
        'Overall duration | ${_formatDuration(overallDuration)} | Period between the beginning and end of all eclipse phases');
    if (totalityDuration > Duration()) {
      buffer.writeln(
          'Duration of totality | ${_formatDuration(totalityDuration)} | Period between the beginning and end of the total phase');
    }
    buffer.writeln(
        'Duration of partial phases | ${_formatDuration(partialDuration)} | Combined period of both partial phases');
    buffer.writeln(
        'Obscuration | ${(this.obscuration! * 100).toStringAsFixed(1)}% | Percentage of the Sun\'s area covered by the Moon');

    return buffer.toString();
  }
}

/// @brief Reports the time and geographic location of the peak of a solar eclipse.
///
/// Returned by {@link SearchGlobalSolarEclipse} or {@link NextGlobalSolarEclipse}
/// to report information about a solar eclipse event.
///
/// The eclipse is classified as partial, annular, or total, depending on the
/// maximum amount of the Sun's disc obscured, as seen at the peak location
/// on the surface of the Earth.
///
/// The `kind` field thus holds one of the values `EclipseKind.Partial`, `EclipseKind.Annular`, or `EclipseKind.Total`.
/// A total eclipse is when the peak observer sees the Sun completely blocked by the Moon.
/// An annular eclipse is like a total eclipse, but the Moon is too far from the Earth's surface
/// to completely block the Sun; instead, the Sun takes on a ring-shaped appearance.
/// A partial eclipse is when the Moon blocks part of the Sun's disc, but nobody on the Earth
/// observes either a total or annular eclipse.
///
/// If `kind` is `EclipseKind.Total` or `EclipseKind.Annular`, the `latitude` and `longitude`
/// fields give the geographic coordinates of the center of the Moon's shadow projected
/// onto the daytime side of the Earth at the instant of the eclipse's peak.
/// If `kind` has any other value, `latitude` and `longitude` are undefined and should
/// not be used.
///
/// For total or annular eclipses, the `obscuration` field holds the fraction (0, 1]
/// of the Sun's apparent disc area that is blocked from view by the Moon's silhouette,
/// as seen by an observer located at the geographic coordinates `latitude`, `longitude`
/// at the darkest time `peak`. The value will always be 1 for total eclipses, and less than
/// 1 for annular eclipses.
/// For partial eclipses, `obscuration` is undefined and should not be used.
/// This is because there is little practical use for an obscuration value of
/// a partial eclipse without supplying a particular observation location.
/// Developers who wish to find an obscuration value for partial solar eclipses should therefore use {@link SearchLocalSolarEclipse} and provide the geographic coordinates of an observer.
///
/// @property {EclipseKind} kind
///     One of the following enumeration values: `EclipseKind.Partial`, `EclipseKind.Annular`, `EclipseKind.Total`.
///
/// @property {number | undefined} obscuration
///      The peak fraction of the Sun's apparent disc area obscured by the Moon (total and annular eclipses only)
///
/// @property {AstroTime} peak
///     The date and time when the solar eclipse is darkest.
///     This is the instant when the axis of the Moon's shadow cone passes closest to the Earth's center.
///
/// @property {number} distance
///     The distance in kilometers between the axis of the Moon's shadow cone
///     and the center of the Earth at the time indicated by `peak`.
///
/// @property {number | undefined} latitude
///     If `kind` holds `EclipseKind.Total`, the geographic latitude in degrees
///     where the center of the Moon's shadow falls on the Earth at the
///     time indicated by `peak`; otherwise, `latitude` holds `undefined`.
///
/// @property {number | undefined} longitude
///     If `kind` holds `EclipseKind.Total`, the geographic longitude in degrees
///     where the center of the Moon's shadow falls on the Earth at the
///     time indicated by `peak`; otherwise, `longitude` holds `undefined`.
class GlobalSolarEclipseInfo extends EclipseInfo {
  late double distance;
  late double? latitude;
  late double? longitude;

  GlobalSolarEclipseInfo(
    super.kind,
    super.obscuration,
    super.peak,
    this.distance,
    this.latitude,
    this.longitude,
  );

  /// Formats a number with leading zeros to match the specified width
  String _pad(num number, int width) {
    return number.toStringAsFixed(0).padLeft(width, '0');
  }

  /// Formats an AstroTime object into a readable UTC string
  String _formatDateTime(AstroTime time) {
    final date = time.date;
    return '${_pad(date.year, 4)}-${_pad(date.month, 2)}-${_pad(date.day, 2)} '
        '${_pad(date.hour, 2)}:${_pad(date.minute, 2)}:${_pad(date.second, 2)}'
        '.${_pad(date.millisecond, 3)} UTC';
  }

  /// Formats coordinates as a readable string
  String _formatCoordinates(double? lat, double? lon) {
    if (lat == null || lon == null) return 'N/A';
    final latDirection = lat >= 0 ? 'N' : 'S';
    final lonDirection = lon >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(2)}° $latDirection, ${lon.abs().toStringAsFixed(2)}° $lonDirection';
  }

  /// Provides additional details about the eclipse type
  String get eclipseDescription {
    switch (kind) {
      case EclipseKind.Total:
        return 'A Total Solar Eclipse occurs when the Moon completely covers the Sun.';
      case EclipseKind.Annular:
        return 'An Annular Solar Eclipse occurs when the Moon appears smaller than the Sun, creating a ring-like appearance.';
      case EclipseKind.Partial:
        return 'A Partial Solar Eclipse occurs when the Moon only partially covers the Sun.';
      default:
        return 'Unknown Eclipse Type.';
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer();

    // Eclipse type and description
    buffer.writeln('${kind.name} Solar Eclipse');
    buffer.writeln(eclipseDescription);
    buffer.writeln();

    // Peak obscuration
    if (this.obscuration != null) {
      buffer.writeln(
          'Peak Sun obscuration: ${(this.obscuration! * 100).toStringAsFixed(1)}%');
    } else {
      buffer.writeln('Peak Sun obscuration: N/A (Partial Eclipse)');
    }

    // Timeline
    buffer.writeln();
    buffer.writeln('Timeline:');
    buffer.writeln('Peak Eclipse: ${_formatDateTime(peak)}');

    // Location information
    buffer.writeln();
    buffer.writeln('Location at Peak:');
    buffer.writeln(
        'Latitude/Longitude: ${_formatCoordinates(latitude, longitude)}');
    buffer
        .writeln('Distance to Earth Center: ${distance.toStringAsFixed(2)} km');

    // Quick facts
    buffer.writeln();
    buffer.writeln('**Quick Facts About This Eclipse**');
    buffer.writeln('Data | Value | Comments');
    buffer.writeln('--- | --- | ---');
    buffer.writeln('Eclipse Kind | ${kind.name} | Type of solar eclipse');
    buffer.writeln(
        'Obscuration | ${this.obscuration != null ? '${(this.obscuration! * 100).toStringAsFixed(1)}%' : 'N/A'} | Fraction of the Sun\'s area covered by the Moon');
    buffer.writeln(
        'Peak Time | ${_formatDateTime(peak)} | Instant of maximum eclipse');
    buffer.writeln(
        'Latitude | ${latitude != null ? '${latitude!.toStringAsFixed(2)}°' : 'N/A'} | Location of peak shadow center');
    buffer.writeln(
        'Longitude | ${longitude != null ? '${longitude!.toStringAsFixed(2)}°' : 'N/A'} | Location of peak shadow center');
    buffer.writeln(
        'Distance | ${distance.toStringAsFixed(2)} km | Shadow axis distance to Earth\'s center');

    return buffer.toString();
  }
}

class Eclipse {
  /// @brief Searches for a solar eclipse visible anywhere on the Earth's surface.
  ///
  /// This function finds the first solar eclipse that occurs after `startTime`.
  /// A solar eclipse may be partial, annular, or total.
  /// See {@link GlobalSolarEclipseInfo} for more information.
  /// To find a series of solar eclipses, call this function once,
  /// then keep calling {@link NextGlobalSolarEclipse} as many times as desired,
  /// passing in the `peak` value returned from the previous call.
  ///
  /// @param {FlexibleDateTime} startTime
  ///      The date and time for starting the search for a solar eclipse.
  ///
  /// @returns {GlobalSolarEclipseInfo}
  static GlobalSolarEclipseInfo searchGlobalSolarEclipse(dynamic startTime) {
    startTime = AstroTime(startTime);
    const double pruneLatitude =
        1.8; // Moon's ecliptic latitude beyond which eclipse is impossible

    // Iterate through consecutive new moons until we find a solar eclipse visible somewhere on Earth.
    var nmtime = startTime;
    for (var nmCount = 0; nmCount < 12; ++nmCount) {
      // Search for the next new moon. Any eclipse will be near it.
      var newmoon = searchMoonPhase(0.0, nmtime, 40.0);
      if (newmoon == null) {
        throw 'Cannot find new moon';
      }

      // Pruning: if the new moon's ecliptic latitude is too large, a solar eclipse is not possible.
      var eclipLat = Moon(newmoon).moonEclipticLatitudeDegrees();
      if (eclipLat.abs() < pruneLatitude) {
        // Search near the new moon for the time when the center of the Earth
        // is closest to the line passing through the centers of the Sun and Moon.
        var shadow = ShadowInfo.peakMoonShadow(newmoon);
        if (shadow.r < shadow.p + EARTH_MEAN_RADIUS_KM) {
          // This is at least a partial solar eclipse visible somewhere on Earth.
          // Try to find an intersection between the shadow axis and the Earth's oblate geoid.
          return geoidIntersect(shadow);
        }
      }

      // We didn't find an eclipse on this new moon, so search for the next one.
      nmtime = newmoon.addDays(10.0);
    }

    // Safety valve to prevent infinite loop.
    // This should never happen, because at least 2 solar eclipses happen per year.
    throw 'Failed to find solar eclipse within 12 full moons.';
  }

  /// @brief Searches for the next global solar eclipse in a series.
  ///
  /// After using {@link SearchGlobalSolarEclipse} to find the first solar eclipse
  /// in a series, you can call this function to find the next consecutive solar eclipse.
  /// Pass in the `peak` value from the {@link GlobalSolarEclipseInfo} returned by the
  /// previous call to `SearchGlobalSolarEclipse` or `NextGlobalSolarEclipse`
  /// to find the next solar eclipse.
  ///
  /// @param {FlexibleDateTime} prevEclipseTime
  ///      A date and time near a new moon. Solar eclipse search will start at the next new moon.
  ///
  /// @returns {GlobalSolarEclipseInfo}
  static GlobalSolarEclipseInfo nextGlobalSolarEclipse(
      dynamic prevEclipseTime) {
    prevEclipseTime = AstroTime(prevEclipseTime);
    var startTime = prevEclipseTime.addDays(10.0);
    return searchGlobalSolarEclipse(startTime);
  }

  /// @brief Searches for a lunar eclipse.
  ///
  /// This function finds the first lunar eclipse that occurs after `startTime`.
  /// A lunar eclipse may be penumbral, partial, or total.
  /// See {@link LunarEclipseInfo} for more information.
  /// To find a series of lunar eclipses, call this function once,
  /// then keep calling {@link NextLunarEclipse} as many times as desired,
  /// passing in the `peak` value returned from the previous call.
  ///
  /// @param {FlexibleDateTime} date
  ///      The date and time for starting the search for a lunar eclipse.
  ///
  /// @returns {LunarEclipseInfo}
  static LunarEclipseInfo searchLunarEclipse(dynamic date) {
    const double pruneLatitude =
        1.8; // full Moon's ecliptic latitude above which eclipse is impossible
    var fmTime = AstroTime(date);
    for (var fmCount = 0; fmCount < 12; ++fmCount) {
      // Search for the next full moon. Any eclipse will be near it.
      final fullMoon = searchMoonPhase(180, fmTime, 40);
      if (fullMoon == null) {
        throw 'Cannot find full moon.';
      }

      // Pruning: if the full Moon's ecliptic latitude is too large,
      // a lunar eclipse is not possible. Avoid needless work searching for the minimum moon distance.
      final eclipLat = Moon(fullMoon).moonEclipticLatitudeDegrees();
      if (eclipLat.abs() < pruneLatitude) {
        // Search near the full moon for the time when the center of the Moon
        // is closest to the line passing through the centers of the Sun and Earth.
        final shadow = ShadowInfo.peakEarthShadow(fullMoon);
        if (shadow.r < shadow.p + MOON_MEAN_RADIUS_KM) {
          // This is at least a penumbral eclipse. We will return a result.
          var kind = EclipseKind.Penumbral;
          var obscuration1 = 0.0;
          var sdTotal = 0.0;
          var sdPartial = 0.0;
          var sdPenum = ShadowInfo.shadowSemiDurationMinutes(
              shadow.time, shadow.p + MOON_MEAN_RADIUS_KM, 200.0);

          if (shadow.r < shadow.k + MOON_MEAN_RADIUS_KM) {
            // This is at least a partial eclipse.
            kind = EclipseKind.Partial;
            sdPartial = ShadowInfo.shadowSemiDurationMinutes(
                shadow.time, shadow.k + MOON_MEAN_RADIUS_KM, sdPenum);

            if (shadow.r + MOON_MEAN_RADIUS_KM < shadow.k) {
              // This is a total eclipse.
              kind = EclipseKind.Total;
              obscuration1 = 1.0;
              sdTotal = ShadowInfo.shadowSemiDurationMinutes(
                  shadow.time, shadow.k - MOON_MEAN_RADIUS_KM, sdPartial);
            } else {
              obscuration1 =
                  obscuration(MOON_MEAN_RADIUS_KM, shadow.k, shadow.r);
            }
          }
          return LunarEclipseInfo(
              kind, obscuration1, shadow.time, sdPenum, sdPartial, sdTotal);
        }
      }

      // We didn't find an eclipse on this full moon, so search for the next one.
      fmTime = fullMoon.addDays(10);
    }

    // This should never happen because there are always at least 2 full moons per year.
    throw 'Failed to find lunar eclipse within 12 full moons.';
  }

  /// @brief Searches for the next lunar eclipse in a series.
  ///
  /// After using {@link SearchLunarEclipse} to find the first lunar eclipse
  /// in a series, you can call this function to find the next consecutive lunar eclipse.
  /// Pass in the `peak` value from the {@link LunarEclipseInfo} returned by the
  /// previous call to `SearchLunarEclipse` or `NextLunarEclipse`
  /// to find the next lunar eclipse.
  ///
  /// @param {FlexibleDateTime} prevEclipseTime
  ///      A date and time near a full moon. Lunar eclipse search will start at the next full moon.
  ///
  /// @returns {LunarEclipseInfo}
  static LunarEclipseInfo nextLunarEclipse(dynamic prevEclipseTime) {
    var startTime = AstroTime(prevEclipseTime);
    startTime =
        startTime.addDays(10); // Add 10 days to the previous eclipse time
    return searchLunarEclipse(startTime);
  }

  /// @brief Searches for a solar eclipse visible at a specific location on the Earth's surface.
  ///
  /// This function finds the first solar eclipse that occurs after `startTime`.
  /// A solar eclipse may be partial, annular, or total.
  /// See {@link LocalSolarEclipseInfo} for more information.
  ///
  /// To find a series of solar eclipses, call this function once,
  /// then keep calling {@link NextLocalSolarEclipse} as many times as desired,
  /// passing in the `peak` value returned from the previous call.
  ///
  /// IMPORTANT: An eclipse reported by this function might be partly or
  /// completely invisible to the observer due to the time of day.
  /// See {@link LocalSolarEclipseInfo} for more information about this topic.
  ///
  /// @param {FlexibleDateTime} startTime
  ///      The date and time for starting the search for a solar eclipse.
  ///
  /// @param {Observer} observer
  ///      The geographic location of the observer.
  ///
  /// @returns {LocalSolarEclipseInfo}
  static LocalSolarEclipseInfo searchLocalSolarEclipse(
      dynamic startTime, Observer observer) {
    startTime = AstroTime(startTime);
    verifyObserver(observer);
    const pruneLatitude =
        1.8; // Moon's ecliptic latitude beyond which eclipse is impossible

    // Iterate through consecutive new moons until we find a solar eclipse visible somewhere on Earth.
    var nmtime = startTime;
    for (;;) {
      // Search for the next new moon. Any eclipse will be near it.
      final newmoon = searchMoonPhase(0.0, nmtime, 40.0);
      if (newmoon == null) {
        throw 'Cannot find next new moon';
      }

      // Pruning: if the new moon's ecliptic latitude is too large, a solar eclipse is not possible.
      final eclipLat = Moon(newmoon).moonEclipticLatitudeDegrees();
      if (eclipLat.abs() < pruneLatitude) {
        // Search near the new moon for the time when the observer
        // is closest to the line passing through the centers of the Sun and Moon.
        final shadow = ShadowInfo.peakLocalMoonShadow(newmoon, observer);
        if (shadow.r < shadow.p) {
          // This is at least a partial solar eclipse for the observer.
          final eclipse = localEclipse(shadow, observer);

          // Ignore any eclipse that happens completely at night.
          // More precisely, the center of the Sun must be above the horizon
          // at the beginning or the end of the eclipse, or we skip the event.
          if (eclipse.partialBegin.altitude > 0.0 ||
              eclipse.partialEnd.altitude > 0.0) {
            return eclipse;
          }
        }
      }

      // We didn't find an eclipse on this new moon, so search for the next one.
      nmtime = newmoon.addDays(10.0);
    }
  }

  /// @brief Searches for the next local solar eclipse in a series.
  ///
  /// After using {@link SearchLocalSolarEclipse} to find the first solar eclipse
  /// in a series, you can call this function to find the next consecutive solar eclipse.
  /// Pass in the `peak` value from the {@link LocalSolarEclipseInfo} returned by the
  /// previous call to `SearchLocalSolarEclipse` or `NextLocalSolarEclipse`
  /// to find the next solar eclipse.
  /// This function finds the first solar eclipse that occurs after `startTime`.
  /// A solar eclipse may be partial, annular, or total.
  /// See {@link LocalSolarEclipseInfo} for more information.
  ///
  /// @param {FlexibleDateTime} prevEclipseTime
  ///      The date and time for starting the search for a solar eclipse.
  ///
  /// @param {Observer} observer
  ///      The geographic location of the observer.
  ///
  /// @returns {LocalSolarEclipseInfo}
  static LocalSolarEclipseInfo nextLocalSolarEclipse(
      dynamic prevEclipseTime, Observer observer) {
    prevEclipseTime = AstroTime(prevEclipseTime);
    final startTime = prevEclipseTime.addDays(10.0);
    return searchLocalSolarEclipse(startTime, observer);
  }

  /// Searches for eclipses based on given parameters.
  ///
  /// [startTime] - The time to start searching from (defaults to current time)
  /// [eclipses] - Type of eclipses to search for (solar, lunar, or all)
  /// [observer] - Optional observer location for local solar eclipses
  /// [eclipseCount] - Number of eclipses to find (defaults to 5)
  static List<EclipseInfo> search(
      {dynamic startTime,
      Eclipses eclipses = Eclipses.all,
      Observer? observer,
      int eclipseCount = 5}) {
    // Initialize start time
    final searchStart = AstroTime(startTime ?? DateTime.now());
    List<EclipseInfo> eclipseResult = [];

    // Handle initial eclipse(s) based on type
    switch (eclipses) {
      case Eclipses.solar:
        final eclipse = observer != null
            ? searchLocalSolarEclipse(searchStart, observer)
            : searchGlobalSolarEclipse(searchStart);
        eclipseResult.add(eclipse);

        // Find subsequent solar eclipses
        for (var i = 1; i < eclipseCount; i++) {
          final nextEclipse = observer != null
              ? nextLocalSolarEclipse(
                  (eclipseResult.last.peak as EclipseEvent).time, observer)
              : nextGlobalSolarEclipse(eclipseResult.last.peak as AstroTime);
          eclipseResult.add(nextEclipse);
        }
        break;

      case Eclipses.lunar:
        var eclipse = searchLunarEclipse(searchStart);
        eclipseResult.add(eclipse);

        // Find subsequent lunar eclipses
        for (var i = 1; i < eclipseCount; i++) {
          eclipse = nextLunarEclipse(eclipse.peak as AstroTime);
          eclipseResult.add(eclipse);
        }
        break;

      case Eclipses.all:
        // Find both initial lunar and solar eclipses
        final lunarEclipse = searchLunarEclipse(searchStart);
        final solarEclipse = observer != null
            ? searchLocalSolarEclipse(searchStart, observer)
            : searchGlobalSolarEclipse(searchStart);

        // Add them in chronological order
        final lunarTime = (lunarEclipse.peak as AstroTime).date;
        final solarTime = observer != null
            ? (solarEclipse.peak as EclipseEvent).time.date
            : (solarEclipse.peak as AstroTime).date;

        if (lunarTime.isBefore(solarTime)) {
          eclipseResult.add(lunarEclipse);
          eclipseResult.add(solarEclipse);
        } else {
          eclipseResult.add(solarEclipse);
          eclipseResult.add(lunarEclipse);
        }

        // Continue finding alternating eclipses until we reach the count
        while (eclipseResult.length < eclipseCount) {
          final lastEclipse = eclipseResult.last;
          final isLastLunar = lastEclipse is LunarEclipseInfo;

          if (!isLastLunar) {
            final nextEclipse = observer != null
                ? nextLocalSolarEclipse(
                    (lastEclipse.peak as EclipseEvent).time, observer)
                : nextGlobalSolarEclipse(lastEclipse.peak as AstroTime);
            eclipseResult.add(nextEclipse);
          } else {
            final nextEclipse = nextLunarEclipse(observer != null
                ? (lastEclipse.peak as EclipseEvent).time
                : lastEclipse.peak as AstroTime);
            eclipseResult.add(nextEclipse);
          }
        }
        break;
    }

    return eclipseResult;
  }
}

/// Calculates the fraction of the area of one disc that is obscured by another disc.
///
/// This function calculates the fraction of the area of one disc that is obscured by another disc,
/// given the radii of the two discs and the distance between their centers.
///
/// @param a The radius of the first disc.
/// @param b The radius of the second disc.
/// @param c The distance between the centers of the two discs.
/// @returns The fraction of the area of the first disc that is obscured by the second disc, in the range [0, 1].
/// @throws If any of the input parameters are non-positive.
double obscuration(double a, double b, double c) {
  if (a <= 0.0) {
    throw 'Radius of first disc must be positive.';
  }

  if (b <= 0.0) {
    throw 'Radius of second disc must be positive.';
  }

  if (c < 0.0) {
    throw 'Distance between discs is not allowed to be negative.';
  }

  if (c >= a + b) {
    // The discs are too far apart to have any overlapping area.
    return 0.0;
  }

  if (c == 0.0) {
    // The discs have a common center. Therefore, one disc is inside the other.
    return (a <= b) ? 1.0 : (b * b) / (a * a);
  }

  final x = (a * a - b * b + c * c) / (2 * c);
  final radicand = a * a - x * x;
  if (radicand <= 0.0) {
    // The circumferences do not intersect, or are tangent.
    // We already ruled out the case of non-overlapping discs.
    // Therefore, one disc is inside the other.
    return (a <= b) ? 1.0 : (b * b) / (a * a);
  }

  // The discs overlap fractionally in a pair of lens-shaped areas.
  final y = sqrt(radicand);

  // Return the overlapping fractional area.
  // There are two lens-shaped areas, one to the left of x, the other to the right of x.
  // Each part is calculated by subtracting a triangular area from a sector's area.
  final lens1 = a * a * acos(x / a) - x * y;
  final lens2 = b * b * acos((c - x) / b) - (c - x) * y;

  // Find the fractional area with respect to the first disc.
  return (lens1 + lens2) / (pi * a * a);
}

EclipseKind eclipseKindFromUmbra(double k) {
  // The umbra radius tells us what kind of eclipse the observer sees.
  // If the umbra radius is positive, this is a total eclipse. Otherwise, it's annular.
  // HACK: I added a tiny bias (14 meters) to match Espenak test data.
  return (k > 0.014) ? EclipseKind.Total : EclipseKind.Annular;
}

double solarEclipseObscuration(AstroVector hm, AstroVector lo) {
  // Find heliocentric observer.
  final ho = AstroVector(hm.x + lo.x, hm.y + lo.y, hm.z + lo.z, hm.time);

  // Calculate the apparent angular radius of the Sun for the observer.
  final sunRadius = asin(SUN_RADIUS_AU / ho.length());

  // Calculate the apparent angular radius of the Moon for the observer.
  final moonRadius = asin(MOON_POLAR_RADIUS_AU / lo.length());

  // Calculate the apparent angular separation between the Sun's center and the Moon's center.
  final sunMoonSeparation = angleBetween(lo, ho);

  // Find the fraction of the Sun's apparent disc area that is covered by the Moon.
  final obscuration1 =
      obscuration(sunRadius, moonRadius, sunMoonSeparation * DEG2RAD);

  // HACK: In marginal cases, we need to clamp obscuration to less than 1.0.
  // This function is never called for total eclipses, so it should never return 1.0.
  return min(0.9999, obscuration1);
}

GlobalSolarEclipseInfo geoidIntersect(ShadowInfo shadow) {
  var kind = EclipseKind.Partial;
  var peak = shadow.time;
  var distance = shadow.r;
  dynamic latitude; // left undefined for partial eclipses
  dynamic longitude; // left undefined for partial eclipses

  // We want to calculate the intersection of the shadow axis with the Earth's geoid.
  // First we must convert EQJ (equator of J2000) coordinates to EQD (equator of date)
  // coordinates that are perfectly aligned with the Earth's equator at this
  // moment in time.
  final rot = RotationMatrix.rotationEQJtoEQD(shadow.time);
  final v = AstroVector.rotateVector(
      rot, shadow.dir); // shadow-axis vector in equator-of-date coordinates
  final e = AstroVector.rotateVector(
      rot, shadow.target); // lunacentric Earth in equator-of-date coordinates

  // Convert all distances from AU to km.
  // But dilate the z-coordinates so that the Earth becomes a perfect sphere.
  // Then find the intersection of the vector with the sphere.
  // See p 184 in Montenbruck & Pfleger's "Astronomy on the Personal Computer", second edition.
  v.x *= KM_PER_AU;
  v.y *= KM_PER_AU;
  v.z *= KM_PER_AU / EARTH_FLATTENING;
  e.x *= KM_PER_AU;
  e.y *= KM_PER_AU;
  e.z *= KM_PER_AU / EARTH_FLATTENING;

  // Solve the quadratic equation that finds whether and where
  // the shadow axis intersects with the Earth in the dilated coordinate system.
  final R = EARTH_EQUATORIAL_RADIUS_KM;
  final A = v.x * v.x + v.y * v.y + v.z * v.z;
  final B = -2.0 * (v.x * e.x + v.y * e.y + v.z * e.z);
  final C = (e.x * e.x + e.y * e.y + e.z * e.z) - R * R;
  final raDic = B * B - 4 * A * C;

  double? obscuration;

  if (raDic > 0.0) {
    // Calculate the closer of the two intersection points.
    // This will be on the day side of the Earth.
    final u = (-B - sqrt(raDic)) / (2 * A);

    // Convert lunacentric dilated coordinates to geocentric coordinates.
    final px = u * v.x - e.x;
    final py = u * v.y - e.y;
    final pz = (u * v.z - e.z) * EARTH_FLATTENING;

    // Convert cartesian coordinates into geodetic latitude/longitude.
    final proj = hypot(px, py) * EARTH_FLATTENING_SQUARED;
    if (proj == 0.0) {
      latitude = (pz > 0.0) ? 90.0 : -90.0;
    } else {
      latitude = RAD2DEG * atan(pz / proj);
    }

    // Adjust longitude for Earth's rotation at the given UT.
    final gast = sidereal_time(peak);
    longitude = (RAD2DEG * atan2(py, px) - (15 * gast)) % 360.0;
    if (longitude <= -180.0) {
      longitude += 360.0;
    } else if (longitude > 180.0) {
      longitude -= 360.0;
    }

    // We want to determine whether the observer sees a total eclipse or an annular eclipse.
    // We need to perform a series of vector calculations...
    // Calculate the inverse rotation matrix, so we can convert EQD to EQJ.
    final inv = RotationMatrix.inverseRotation(rot);

    // Put the EQD geocentric coordinates of the observer into the vector 'o'.
    // Also convert back from kilometers to astronomical units.
    var o = AstroVector(
        px / KM_PER_AU, py / KM_PER_AU, pz / KM_PER_AU, shadow.time);

    // Rotate the observer's geocentric EQD back to the EQJ system.
    o = AstroVector.rotateVector(inv, o);

    // Convert geocentric vector to lunacentric vector.
    o.x += shadow.target.x;
    o.y += shadow.target.y;
    o.z += shadow.target.z;

    // Recalculate the shadow using a vector from the Moon's center toward the observer.
    final surface =
        ShadowInfo.calcShadow(MOON_POLAR_RADIUS_KM, shadow.time, o, shadow.dir);

    // If we did everything right, the shadow distance should be very close to zero.
    // That's because we already determined the observer 'o' is on the shadow axis!
    if (surface.r > 1.0e-9 || surface.r < 0.0) {
      throw 'Unexpected shadow distance from geoid intersection = ${surface.r}';
    }

    kind = eclipseKindFromUmbra(surface.k);
    obscuration = (kind == EclipseKind.Total)
        ? 1.0
        : solarEclipseObscuration(shadow.dir, o);
  } else {
    // This is a partial solar eclipse. It does not make practical sense to calculate obscuration.
    // Anyone who wants obscuration should use Astronomy.searchLocalSolarEclipse for a specific location on the Earth.
    obscuration = null;
  }

  return GlobalSolarEclipseInfo(
      kind, obscuration, peak, distance, latitude, longitude);
}

double localPartialDistance(ShadowInfo shadow) {
  return shadow.p - shadow.r;
}

double localTotalDistance(ShadowInfo shadow) {
  // Must take the absolute value of the umbra radius 'k'
  // because it can be negative for an annular eclipse.
  return (shadow.k.abs()) - shadow.r;
}

double sunAltitude(AstroTime time, Observer observer) {
  final equ = equator(Body.Sun, time, observer, true,
      true); // Adjust Body.Sun to your actual implementation
  final hor = HorizontalCoordinates.horizon(time, observer, equ.ra, equ.dec,
      'normal'); // Adjust 'normal' to your actual implementation
  return hor.altitude;
}

EclipseEvent calcEvent(Observer observer, AstroTime time) {
  final altitude = sunAltitude(time, observer);
  return EclipseEvent(time, altitude);
}

EclipseEvent localEclipseTransition(Observer observer, double direction,
    ShadowFunc func, AstroTime t1, AstroTime t2) {
  double evaluate(AstroTime time) {
    final shadow = ShadowInfo.localMoonShadow(time, observer);
    return direction * func(shadow);
  }

  final searchResult = search(evaluate, t1, t2);
  if (searchResult == null) {
    throw "Local eclipse transition search failed.";
  }
  return calcEvent(observer, searchResult);
}

LocalSolarEclipseInfo localEclipse(ShadowInfo shadow, Observer observer) {
  const partialWindow = 0.2;
  const totalWindow = 0.01;
  final peak = calcEvent(observer, shadow.time);
  var t1 = shadow.time.addDays(-partialWindow);
  var t2 = shadow.time.addDays(partialWindow);
  final partialBegin = localEclipseTransition(
      observer, 1.0, localPartialDistance, t1, shadow.time);
  final partialEnd = localEclipseTransition(
      observer, -1.0, localPartialDistance, shadow.time, t2);
  EclipseEvent? totalBegin;
  EclipseEvent? totalEnd;
  late EclipseKind kind;

  if (shadow.r < shadow.k.abs()) {
    // take absolute value of 'k' to handle annular eclipses too.
    t1 = shadow.time.addDays(-totalWindow);
    t2 = shadow.time.addDays(totalWindow);
    totalBegin = localEclipseTransition(
        observer, 1.0, localTotalDistance, t1, shadow.time);
    totalEnd = localEclipseTransition(
        observer, -1.0, localTotalDistance, shadow.time, t2);
    kind = eclipseKindFromUmbra(shadow.k);
  } else {
    kind = EclipseKind.Partial;
  }

  final obscuration = (kind == EclipseKind.Total)
      ? 1.0
      : solarEclipseObscuration(shadow.dir, shadow.target);

  return LocalSolarEclipseInfo(
      kind, obscuration, partialBegin, totalBegin, peak, totalEnd, partialEnd);
}

/// @brief Returns apparent geocentric true ecliptic coordinates of date for the Sun.
///
/// This function is used for calculating the times of equinoxes and solstices.
///
/// <i>Geocentric</i> means coordinates as the Sun would appear to a hypothetical observer
/// at the center of the Earth.
/// <i>Ecliptic coordinates of date</i> are measured along the plane of the Earth's mean
/// orbit around the Sun, using the
/// <a href="https://en.wikipedia.org/wiki/Equinox_(celestial_coordinates)">equinox</a>
/// of the Earth as adjusted for precession and nutation of the Earth's
/// axis of rotation on the given date.
///
/// @param {FlexibleDateTime} date
///      The date and time at which to calculate the Sun's apparent location as seen from
///      the center of the Earth.
///
/// @returns {EclipticCoordinates}
EclipticCoordinates sunPosition(dynamic date) {
  // Correct for light travel time from the Sun.
  // This is really the same as correcting for aberration.
  // Otherwise season calculations (equinox, solstice) will all be early by about 8 minutes!
  AstroTime time = AstroTime(date).addDays(-1 / C_AUDAY);

  // Get heliocentric cartesian coordinates of Earth in J2000.
  AstroVector earth2000 = calcVsop(vsopTable["Earth"]!, time);

  // Convert to geocentric location of the Sun.
  List<double> sun2000 = [-earth2000.x, -earth2000.y, -earth2000.z];

  // Convert to equator-of-date equatorial cartesian coordinates.
  List<double> gyrationResult =
      gyration(sun2000, time, PrecessDirection.From2000);

  // Convert to ecliptic coordinates of date.
  double trueObliq = DEG2RAD * eTilt(time).tobl;
  double cosOb = cos(trueObliq);
  double sinOb = sin(trueObliq);

  AstroVector vec = AstroVector(
      gyrationResult[0], gyrationResult[1], gyrationResult[2], time);
  EclipticCoordinates sunEcliptic =
      EclipticCoordinates.rotateEquatorialToEcliptic(vec, cosOb, sinOb);
  return sunEcliptic;
}

/// @brief Searches for when the Sun reaches a given ecliptic longitude.
///
/// Searches for the moment in time when the center of the Sun reaches a given apparent
/// ecliptic longitude, as seen from the center of the Earth, within a given range of dates.
/// This function can be used to determine equinoxes and solstices.
/// However, it is usually more convenient and efficient to call {@link Seasons}
/// to calculate equinoxes and solstices for a given calendar year.
/// `SearchSunLongitude` is more general in that it allows searching for arbitrary longitude values.
///
/// @param {number} targetLon
///      The desired ecliptic longitude of date in degrees.
///      This may be any value in the range [0, 360), although certain
///      values have conventional meanings:
///
///      When `targetLon` is 0, finds the March equinox,
///      which is the moment spring begins in the northern hemisphere
///      and the beginning of autumn in the southern hemisphere.
///
///      When `targetLon` is 180, finds the September equinox,
///      which is the moment autumn begins in the northern hemisphere and
///      spring begins in the southern hemisphere.
///
///      When `targetLon` is 90, finds the northern solstice, which is the
///      moment summer begins in the northern hemisphere and winter
///      begins in the southern hemisphere.
///
///      When `targetLon` is 270, finds the southern solstice, which is the
///      moment winter begins in the northern hemisphere and summer
///      begins in the southern hemisphere.
///
/// @param {FlexibleDateTime} dateStart
///      A date and time known to be earlier than the desired longitude event.
///
/// @param {number} limitDays
///      A floating point number of days, which when added to `dateStart`,
///      yields a date and time known to be after the desired longitude event.
///
/// @returns {AstroTime | null}
///      The date and time when the Sun reaches the apparent ecliptic longitude `targetLon`
///      within the range of times specified by `dateStart` and `limitDays`.
///      If the Sun does not reach the target longitude within the specified time range, or the
///      time range is excessively wide, the return value is `null`.
///      To avoid a `null` return value, the caller must pick a time window around
///      the event that is within a few days but not so small that the event might fall outside the window.
AstroTime? searchSunLongitude(
    double targetLon, dynamic dateStart, double limitDays) {
  double sunOffset(AstroTime t) {
    final pos = sunPosition(t);

    return LongitudeOffset(pos.eLon - targetLon);
  }

  verifyNumber(targetLon);
  verifyNumber(limitDays);

  final t1 = AstroTime(dateStart);
  final t2 = t1.addDays(limitDays);

  return search(sunOffset, t1, t2,
      options: SearchOptions(dtToleranceSeconds: 0.01));
}
