library iproov_firebase;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

enum AssuranceType {
  genuinePresence('genuine_presence'),
  liveness('liveness');

  final String value;
  const AssuranceType(this.value);
}

enum ClaimType { enrol, verify }

const _defaultExtensionId = 'auth-iproov';

extension IProovFirebaseAuthExtension on FirebaseAuth {
  Stream<IProovEvent> signInWithIProov({
    required String userId,
    AssuranceType assuranceType = AssuranceType.genuinePresence,
    Options iproovOptions = const Options(),
    String extensionId = _defaultExtensionId,
  }) =>
      _doIProov(
        userId,
        assuranceType,
        ClaimType.verify,
        iproovOptions,
        extensionId,
      );

  Stream<IProovEvent> createIProovUser({
    String? userId,
    AssuranceType assuranceType = AssuranceType.genuinePresence,
    Options iproovOptions = const Options(),
    String extensionId = _defaultExtensionId,
  }) =>
      _doIProov(
        userId,
        assuranceType,
        ClaimType.enrol,
        iproovOptions,
        extensionId,
      );

  Stream<IProovEvent> _doIProov(
    String? userId,
    AssuranceType assuranceType,
    ClaimType claimType,
    Options options,
    String extensionId,
  ) async* {
    final response = await FirebaseFunctions.instance.httpsCallable('ext-$extensionId-getToken')({
      'userId': userId,
      'claimType': claimType.name,
      'assuranceType': assuranceType.value,
    });

    final data = response.data as Map<String, dynamic>;

    final region = data['region'];
    final token = data['token'];

    final stream = IProov.launch(
      streamingUrl: 'wss://$region.rp.secure.iproov.me/ws',
      token: token,
      options: options,
    );

    await for (IProovEvent event in stream) {
      yield event;
      if (event is IProovEventSuccess) {
        final credential = await _validateIProovUser(
          userId: userId,
          token: token,
          claimType: claimType,
          extensionId: extensionId,
        );
        yield IProovEventAuthenticationSuccess(credential);
      }
    }
  }

  Future<UserCredential> _validateIProovUser({
    String? userId,
    required String token,
    required ClaimType claimType,
    required String extensionId,
  }) async {
    final response = await FirebaseFunctions.instance.httpsCallable('ext-$extensionId-validate')(
      {
        'userId': userId,
        'token': token,
        'claimType': claimType.name,
      },
    );

    final jwt = response.data as String;
    return signInWithCustomToken(jwt);
  }
}
