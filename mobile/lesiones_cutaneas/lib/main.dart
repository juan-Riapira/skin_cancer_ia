import 'package:flutter/material.dart';
import 'screens/inicio_screen.dart';
import 'utils/app_colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lesiones Cutáneas',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primario),
        useMaterial3: true,
      ),
      initialRoute: '/inicio',
      routes: {'/inicio': (_) => const InicioScreen()},
    );
  }
}
