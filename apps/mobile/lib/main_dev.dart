import 'package:flutter/foundation.dart';

import 'core/config/environment.dart';
import 'main.dart' as app;

void main() {
  EnvironmentConfig.init(Environment.dev);
  debugPrint('=== TEKKA DEV MODE ===');
  app.main();
}
