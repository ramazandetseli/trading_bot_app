import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:trading_bot_app/portfolio/portfolio_bottom_sheet.dart';
import 'package:trading_bot_app/screens/alarms/alarms_screen.dart';
import 'package:trading_bot_app/screens/auth/auth_screen.dart';
import 'package:trading_bot_app/screens/dashboard/dashboard_screen.dart';
import 'package:trading_bot_app/screens/rehber/rehber_screen.dart';
import 'package:trading_bot_app/screens/dashboard/scanner_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
final supabase = Supabase.instance.client;

class ThemeManager {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

  static void toggleTheme() {
    themeNotifier.value = themeNotifier.value == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pslgppeawgjpwnhqcqtn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBzbGdwcGVhd2dqcHduaHFjcXRuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzczMjIzNTIsImV4cCI6MjA5Mjg5ODM1Mn0.Ed_vGrbEuvUuUUZXTIdMkEq09AiFaqmp9bvctVrfjTE',
  );

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("8c35a1ad-4a63-49ab-a857-c167d16beb00"); // OneSignal'dan alacağımız kod
  OneSignal.Notifications.requestPermission(true);

  runApp(const TradingBotApp());
}


class TradingBotApp extends StatelessWidget {
  const TradingBotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (_, ThemeMode currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(), // Açık tema ayarları
          darkTheme: ThemeData.dark(), // Koyu tema ayarları
          themeMode: currentMode, // İşte sihirli dokunuş!
          home: Supabase.instance.client.auth.currentSession == null 
              ? const AuthScreen() 
              : const MainNavigationScreen(),
        );
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 2) {
      // 2. index (Portföy) tıklandığında sayfayı değiştirmek yerine sheet'i aç
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PortfolioBottomSheet(
          userId: userId,
          anlikFiyatlar: const {},
        ),
      );
      return; // _selectedIndex'i 2 yapma, kullanıcı hangi sekmedeyse orada kalsın
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Aktif oturum açmış kullanıcının ID'sini alıyoruz
    final String currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const DashboardScreen(),
          ScannerScreen(),
          // Boş string yerine gerçek kullanıcı ID'si
          PortfolioBottomSheet(
            userId: currentUserId,
            anlikFiyatlar: const {}, // Ekran içinde kendi çekiyorsa sorun yok
          ),
          const AlarmScreen(),
          const RehberScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Piyasa'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tarama'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Portföy'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Alarmlar'),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Rehber'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.greenAccent,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}