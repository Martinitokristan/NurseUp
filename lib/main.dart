import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/services/cloudinary_service.dart';

export 'app.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    CloudinaryService.instance.initialize();
  } catch (_) {
    // .env missing or malformed — Cloudinary uploads will fail with a
    // friendly error at call-time instead of crashing app startup.
  }

  try {
    await Firebase.initializeApp();
  } catch (_) {}

  runApp(const ProviderScope(child: MyApp()));
}

