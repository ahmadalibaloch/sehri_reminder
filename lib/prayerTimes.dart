import 'package:geolocator/geolocator.dart';
import 'package:libpray/libpray.dart';

Future<Map<String, dynamic>> getPrayerTimes() async {
  Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
  final PrayerCalculationSettings settings =
      PrayerCalculationSettings((PrayerCalculationSettingsBuilder b) => b
        ..calculationMethod.replace(CalculationMethod.fromPreset(
            preset: CalculationMethodPreset.universityOfIslamicSciencesKarachi))
        ..imsakParameter.replace(PrayerCalculationParameter(
            (PrayerCalculationParameterBuilder c) => c
              ..value = 0
              ..type = PrayerCalculationParameterType.minutesAdjust))
        ..juristicMethod.replace(JuristicMethod((JuristicMethodBuilder e) => e
          ..preset = JuristicMethodPreset.hanafi
          ..timeOfShadow = 2))
        ..highLatitudeAdjustment = HighLatitudeAdjustment.angleBased
        ..imsakMinutesAdjustment = 0
        ..fajrMinutesAdjustment = 0
        ..sunriseMinutesAdjustment = 0
        ..dhuhaMinutesAdjustment = 0
        ..dhuhrMinutesAdjustment = 0
        ..asrMinutesAdjustment = 0
        ..maghribMinutesAdjustment = 0
        ..ishaMinutesAdjustment = 0);

  // Init location info.
  final Geocoordinate geo = Geocoordinate((GeocoordinateBuilder b) => b
        ..latitude = 31.451481 //position.latitude
        ..longitude = 74.2531461 // position.longitude
        ..altitude = 208 // position.altitude
      );
  DateTime date = DateTime.now();
  double timeZone = 5.0;
  // double timeZone = double.parse(
  //     '${date.timeZoneOffset.inMinutes ~/ 60}.${date.timeZoneOffset.inMinutes % 60}');

  final Prayers prayers = Prayers.on(
      date: date, settings: settings, coordinate: geo, timeZone: timeZone);

  Map<String, dynamic> dynamicPrayers = {};
  dynamicPrayers['fajr'] = prayers.fajr;
  dynamicPrayers['dhuhr'] = prayers.dhuhr;
  dynamicPrayers['asr'] = prayers.asr;
  dynamicPrayers['maghrib'] = prayers.maghrib;
  dynamicPrayers['imsak'] = prayers.imsak;
  dynamicPrayers['isha'] = prayers.isha;
  dynamicPrayers['sunrise'] = prayers.sunrise;
  dynamicPrayers['sunset'] = prayers.sunset;
  dynamicPrayers['dhuha'] = prayers.dhuha;
  dynamicPrayers['midnight'] = prayers.midnight;
  return dynamicPrayers;
}
