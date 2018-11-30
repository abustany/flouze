import 'package:flutter/services.dart';

import 'package:uni_links/uni_links.dart';

import 'package:flouze/utils/uuid.dart' as uuid;

abstract class LinkAction{}

class LinkActionClone extends LinkAction {
  final List<int> accountUuid;

  LinkActionClone(this.accountUuid);
}

const String URI_PREFIX = '/mobile/';

LinkAction _parseAction(Uri uri) {
  if (uri == null || !uri.path.startsWith(URI_PREFIX)) {
    return null;
  }

  final action = uri.path.substring(URI_PREFIX.length);

  if (action == 'clone') {
    final accountId = uri.queryParameters['accountId'];

    if (accountId == null) {
      print('No accountId in clone action');
      return null;
    }

    return LinkActionClone(uuid.parse(accountId));
  } else {
    print('Unknown URI action: ' + action);
  }

  return null;
}

Stream<LinkAction> linkActions() async* {
  try {
      final initial = _parseAction(await getInitialUri());
      final linksStream = getUriLinksStream();

      if (initial != null) {
        yield initial;
      }

      await for (var uri in linksStream) {
        final action = _parseAction(uri);

        if (action != null) {
          yield action;
        }
      }
  } on PlatformException catch (e) {
    print('Failed to retrieve intent link: ${e.message}');
    return;
  }
}
