import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/add_field_screen.dart';
import 'screens/nearby_fields_screen.dart';
import 'screens/fields_list_screen.dart';

void main() {
  runApp(const VillageMappingApp());
}

class VillageMappingApp extends StatelessWidget {
  const VillageMappingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ज़मीन नक्शा',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D6A4F),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF16213E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF16213E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D6A4F),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(),
        '/add-field': (context) => const AddFieldScreen(),
        '/nearby': (context) => const NearbyFieldsScreen(),
        '/fields': (context) => const FieldsListScreen(),
      },
    );
  }
}
