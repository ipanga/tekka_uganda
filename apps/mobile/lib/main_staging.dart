import 'package:flutter/foundation.dart';

import 'core/config/environment.dart';
import 'main.dart' as app;

void main() {
  EnvironmentConfig.init(Environment.staging);
  debugPrint('=== TEKKA STAGING MODE ===');
  app.main();
}
