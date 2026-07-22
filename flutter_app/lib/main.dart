import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/api_client.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(VipraSetuApp(api: ApiClient()));
}
