import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:iproov_firebase/iproov_firebase.dart';
import 'package:uuid/v4.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MaterialApp(debugShowCheckedModeBanner: true, home: const HomePage(), theme: ThemeData(useMaterial3: true)),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  StreamSubscription? _subscription;
  final _userIdController = TextEditingController();

  @override
  void initState() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((event) => setState(() => _user = event));
    _userIdController.text = const UuidV4().generate();
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _userIdController.dispose();
    super.dispose();
  }

  User? _user;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('iProov Firebase Flutter SDK Example App')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Center(
          child: Builder(builder: (context) {
            if (isLoading) return const CircularProgressIndicator.adaptive();

            return Column(
              children: [
                TextFormField(
                  controller: _userIdController,
                  decoration: const InputDecoration(
                    border: UnderlineInputBorder(),
                    labelText: 'User ID',
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    _onRegisterPressed(AssuranceType.genuinePresence);
                  },
                  child: const Text('Register with Genuine Presence Assurance'),
                ),
                FilledButton(
                  onPressed: () {
                    _onRegisterPressed(AssuranceType.liveness);
                  },
                  child: const Text('Register with Liveness Assurance'),
                ),
                FilledButton(
                  onPressed: () {
                    _onLoginPressed(AssuranceType.genuinePresence);
                  },
                  child: const Text('Login with Genuine Presence Assurance'),
                ),
                FilledButton(
                  onPressed: () {
                    _onLoginPressed(AssuranceType.liveness);
                  },
                  child: const Text('Login with Liveness Assurance'),
                ),
                if (_user != null) ...[
                  const Text('You have successfully authenticated', textAlign: TextAlign.center),
                  const SizedBox(height: 5),
                  Text('Firebase UID: ${_user!.uid}', textAlign: TextAlign.center),
                  const SizedBox(height: 15),
                  FilledButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('Sign out')),
                ]
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _onLoginPressed(AssuranceType assuranceType) async {
    setState(() => isLoading = true);

    final stream = FirebaseAuth.instance.iProov(extensionId: 'auth-iproov-3262').signIn(
          context: context,
          assuranceType: assuranceType,
          userId: _userIdController.text,
        );

    return _handleIProov(stream);
  }

  Future<void> _onRegisterPressed(AssuranceType assuranceType) async {
    setState(() => isLoading = true);

    final stream = FirebaseAuth.instance.iProov(extensionId: 'auth-iproov-3262').createUser(
          context: context,
          assuranceType: assuranceType,
          userId: _userIdController.text,
        );

    return _handleIProov(stream);
  }

  Future<void> _handleIProov(Stream<IProovEvent> stream) async {
    try {
      final event = await stream.last;
      switch (event) {
        case IProovEventUserDeclinedPrivacyPolicy _:
          _presentError(
            title: 'Privacy Policy Declined',
            message: "You must accept the privacy policy to sign in with iProov.",
          );
          break;
        case IProovEventFailure failure:
          _presentError(title: 'IProov Failed', message: failure.reason);
          break;
        case IProovEventError event:
          _presentError(title: event.error.title, message: event.error.message);
          break;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'NOT_FOUND') {
        _presentError(
            title: 'Function not setup',
            message:
                'Please check you have installed the Firebase extension to the correct project and specified the correct region.');
      }
    } catch (e) {
      _presentError(title: 'Unknown Error', message: e.toString());
    }

    if (isLoading) setState(() => isLoading = false);
  }

  void _presentError({required String title, String? message}) => showAdaptiveDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => AlertDialog.adaptive(
          title: Text(title),
          content: Text(message ?? 'Unknown Error'),
        ),
      );
}
