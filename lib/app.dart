import 'package:flutter/material.dart';

import 'core/utils/snackbar_service.dart';
import 'features/auth/presentation/widgets/auth_wrapper.dart';
import 'features/schedule/presentation/pages/schedule_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inspire Admin Portal',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: SnackbarService.scaffoldMessengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00ACC1), // Cyan - matches Inspire icon
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(child: SchedulePage()),
    );
  }
}
