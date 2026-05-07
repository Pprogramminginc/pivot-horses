import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/backend/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final bootstrap = await AppBootstrap.initialize();
  runApp(PivotHorsesApp(bootstrap: bootstrap));
}
