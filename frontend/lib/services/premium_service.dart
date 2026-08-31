// lib/services/user_state.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserState {
  static final UserState _instance = UserState._internal();
  factory UserState() => _instance;
  UserState._internal();

  // Herkesin ulaşabileceği premium durumu
  bool isPremium = false;
  
  // Günlük AI analiz hakkı (Bunu da burada tutarsak süper olur)
  int dailyAiRights = 3;

  // Supabase'den güncel durumu çeken fonksiyon
  Future<void> fetchPremiumStatus() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      try {
        final data = await supabase
            .from("profiles")
            .select("premium_status")
            .eq('id', user.id)
            .single();

        isPremium = data['premium_status'] ?? false;
      } catch (e) {
        debugPrint("Premium durumu çekilirken hata: $e");
        isPremium = false;
      }
    }
  }
}