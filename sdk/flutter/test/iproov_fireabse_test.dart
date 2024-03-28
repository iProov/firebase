import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iproov_firebase/iproov_firebase.dart';
import 'package:mockito/mockito.dart';

class MockFirebaseApp extends Mock implements FirebaseApp {
  @override
  String get name => '$MockFirebaseApp';
}

void main() {
  late FirebaseAuth auth;

  setUp(() {
    auth = FirebaseAuth.instanceFor(app: MockFirebaseApp());
  });

  group('$IProovFirebaseAuth', () {
    test("Custom region is used", () {
      const customRegion = 'europe-west1';

      final iProov = auth.iProov(region: customRegion);

      expect(iProov.functions.delegate.region, customRegion);
    });
  });
}
