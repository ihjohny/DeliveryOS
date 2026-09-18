import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

String cleanPhoneNumber(String phoneNumber) {
  return phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
}

Future<bool> makeDirectPhoneCall(String phoneNumber) async {
  final cleanNumber = cleanPhoneNumber(phoneNumber);
  final Uri launchUri = Uri(
    scheme: 'tel',
    path: cleanNumber,
  );
  try {
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      return true;
    }
  } catch (_) {
    // Fail gracefully on desktop/test environments
  }
  return false;
}

Future<bool> openNativeTurnByTurnNavigation(double lat, double lng) async {
  final Uri googleMapsUri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
  final Uri appleMapsUri = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
  final Uri webMapsUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');

  try {
    if (Platform.isAndroid && await canLaunchUrl(googleMapsUri)) {
      await launchUrl(googleMapsUri);
      return true;
    } else if (Platform.isIOS && await canLaunchUrl(appleMapsUri)) {
      await launchUrl(appleMapsUri);
      return true;
    } else if (await canLaunchUrl(webMapsUri)) {
      await launchUrl(webMapsUri);
      return true;
    }
  } catch (_) {
    // Fail gracefully on test/unsupported environments
  }
  return false;
}
