import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';

import '../firebase_options.dart';
import 'firestore_seeder.dart';

/// One-off entrypoint to populate the NurseUp Firestore project with initial
/// `plans` data.
///
/// Run with:
///   C:\src\flutter\bin\flutter.bat run -d DEVICE_ID -t lib/tools/seed_main.dart
///
/// After it prints "Seeding complete" you can stop the app — the data is now
/// live in Firestore and the main app will consume it automatically.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirestoreSeeder.seedAll();
  runApp(const _SeederDone());
}

class _SeederDone extends StatelessWidget {
  const _SeederDone();

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFFEAF4FF),
        child: Center(
          child: Text(
            'Firestore seeding complete.\n'
            'You may close this screen and run the main app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              color: Color(0xFF0F2A44),
            ),
          ),
        ),
      ),
    );
  }
}
