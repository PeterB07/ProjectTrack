import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DynamicLinkGenerator {
  static Future<String> generateJobLink({
    required String driverId,
    required String jobId,
    required String src,
    required String dest,
    required String pay,
    required String details,
  }) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://myapp.page.link',
      link: Uri.parse('https://myapp.com/job?driverId=$driverId&jobId=$jobId&src=$src&dest=$dest&pay=$pay&details=$details'),
      androidParameters: const AndroidParameters(
        packageName: 'org.traccar.client',
        minimumVersion: 0,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'org.traccar.client',
        minimumVersion: '0',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: 'New Job Available!',
        description: 'Job ID: $jobId from $src to $dest',
      ),
    );

    final ShortDynamicLink shortDynamicLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    return shortDynamicLink.shortUrl.toString();
  }
}