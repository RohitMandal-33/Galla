import 'package:url_launcher/url_launcher.dart';

/// The official web version of Galla.
const String kGallaWebUrl = 'https://gallaweb.vercel.app';
const String kGallaWebDomain = 'gallaweb.vercel.app';

/// Launches the Galla web app in an external browser.
Future<bool> launchGallaWeb() async {
  final uri = Uri.parse(kGallaWebUrl);
  try {
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    return false;
  }
}
