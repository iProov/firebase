library iproov_firebase;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iproov_firebase/privacy_policy_page.dart';
import 'package:iproov_flutter/iproov_flutter.dart';

export 'package:iproov_flutter/events.dart';

/// Successful Firebase Authentication event
class IProovEventAuthenticationSuccess implements IProovEvent {
  /// Firebase user credential
  final UserCredential credential;

  const IProovEventAuthenticationSuccess(this.credential);

  @override
  bool get isFinal => true;
}

class IProovEventUserDeclinedPrivacyPolicy implements IProovEvent {
  const IProovEventUserDeclinedPrivacyPolicy();

  @override
  bool get isFinal => true;
}

enum AssuranceType {
  genuinePresence('genuine_presence'),
  liveness('liveness');

  final String value;
  const AssuranceType(this.value);
}

enum ClaimType { enrol, verify }

extension IProovFirebaseAuthExtension on FirebaseAuth {
  IProovFirebaseAuth iProov({String? region, String? extensionId}) =>
      IProovFirebaseAuth._(auth: this, extensionId: extensionId, region: region);
}

class IProovFirebaseAuth {
  static const _defaultExtensionId = 'auth-iproov';
  final String extensionId;
  final FirebaseFunctions functions;
  final FirebaseAuth auth;

  IProovFirebaseAuth._({String? extensionId, required this.auth, String? region})
      : functions = FirebaseFunctions.instanceFor(app: auth.app, region: region),
        extensionId = extensionId ?? _defaultExtensionId;

  Stream<IProovEvent> signIn({
    required BuildContext context,
    required String userId,
    AssuranceType assuranceType = AssuranceType.genuinePresence,
    Options options = const Options(),
  }) =>
      _launchIProov(context, userId, assuranceType, ClaimType.verify, options);

  Stream<IProovEvent> createUser({
    required BuildContext context,
    String? userId,
    AssuranceType assuranceType = AssuranceType.genuinePresence,
    Options options = const Options(),
  }) =>
      _launchIProov(context, userId, assuranceType, ClaimType.enrol, options);

  Stream<IProovEvent> _launchIProov(
    BuildContext context,
    String? userId,
    AssuranceType assuranceType,
    ClaimType claimType,
    Options options,
  ) async* {
    final response = await functions.httpsCallable('ext-$extensionId-getToken')({
      'userId': userId,
      'claimType': claimType.name,
      'assuranceType': assuranceType.value,
    });

    final data = response.data as Map<String, dynamic>;

    final region = data['region'];
    final token = data['token'];
    final privacyPolicyUrl = Uri.tryParse(data['privacyPolicyUrl']);

    if (privacyPolicyUrl != null && context.mounted) {
      final didAccept = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PrivacyPolicyPage(url: privacyPolicyUrl), fullscreenDialog: true),
          ) ??
          false;

      if (!didAccept) {
        yield const IProovEventUserDeclinedPrivacyPolicy();
        return;
      }
    }

    final stream = IProov.launch(
      streamingUrl: 'wss://$region.rp.secure.iproov.me/ws',
      token: token,
      options: options,
    );

    await for (IProovEvent event in stream) {
      yield event;
      if (event is IProovEventSuccess) {
        final credential = await _validateUser(
          userId: userId,
          token: token,
          claimType: claimType,
        );
        yield IProovEventAuthenticationSuccess(credential);
      }
    }
  }

  Future<UserCredential> _validateUser({String? userId, required String token, required ClaimType claimType}) async {
    final response = await functions.httpsCallable('ext-$extensionId-validate')(
      {
        'userId': userId,
        'token': token,
        'claimType': claimType.name,
      },
    );

    final jwt = response.data as String;
    return auth.signInWithCustomToken(jwt);
  }
}
