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
    // Fail gracefully on environments without native dialer
  }
  return false;
}
