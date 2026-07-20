import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  static Future<Map<String, dynamic>?> getCurrentAddress() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Dịch vụ định vị đang tắt. Vui lòng bật GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Quyền truy cập vị trí bị từ chối.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Quyền vị trí bị từ chối vĩnh viễn, không thể yêu cầu lại.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String addressText = '${place.street}, ${place.subAdministrativeArea}, ${place.administrativeArea}';

        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'addressText': addressText,
        };
      }
    } catch (e) {
      return Future.error('Không thể dịch tọa độ sang địa chỉ.');
    }

    return null;
  }
}