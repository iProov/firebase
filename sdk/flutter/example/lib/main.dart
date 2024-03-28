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

  @override
  void initState() {
    _subscription = FirebaseAuth.instance.authStateChanges().listen((event) => setState(() => _user = event));
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
  }

  User? _user;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Auth Example')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Center(
          child: Builder(builder: (context) {
            if (isLoading) return const CircularProgressIndicator.adaptive();

            if (_user == null) return FilledButton(onPressed: _onRegisterPressed, child: const Text('Enrol'));

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text('You have successfully authenticated', textAlign: TextAlign.center),
                const SizedBox(height: 5),
                Text('Firebase UID: ${_user!.uid}', textAlign: TextAlign.center),
                const SizedBox(height: 15),
                FilledButton(onPressed: () => FirebaseAuth.instance.signOut(), child: const Text('Sign out')),
              ],
            );
          }),
        ),
      ),
    );
  }

  Future<void> _onRegisterPressed() async {
    setState(() => isLoading = true);

    final userId = const UuidV4().generate();
    final stream = FirebaseAuth.instance.iProov(region: 'europe-central2').createUser(
          userId: userId,
          assuranceType: AssuranceType.genuinePresence,
        );

    return _handleIProov(stream);
  }

  Future<void> _handleIProov(Stream<IProovEvent> stream) async {
    try {
      final event = await stream.last;
      if (event is IProovEventError) {
        _presentError(title: event.error.title, message: event.error.message);
      } else if (event is IProovEventFailure) {
        _presentError(title: 'IProov Failed', message: event.reason);
      }
    } catch (e) {
      _presentError(title: 'Unknown Error', message: e.toString());
    }

    if (isLoading) {
      setState(() => isLoading = false);
    }
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
