import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:trading_bot_app/services/api_service.dart'; // ApiService'i import et

class AlarmKur {
  static void goster({
    required BuildContext context,
    required String symbol,
    required double anlikFiyat,
  }) {
    TextEditingController fiyatController = TextEditingController(text: anlikFiyat.toStringAsFixed(2));
    final ApiService apiService = ApiService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[950],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$symbol İçin Fiyat Alarmı Kur", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)
              ),
              const SizedBox(height: 15),
              TextField(
                controller: fiyatController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Hedef Fiyat (₺)",
                  labelStyle: const TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey[800]!)),
                  focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.greenAccent)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final String? userId = Supabase.instance.client.auth.currentUser?.id;
                    if (userId == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Alarm kurmak için giriş yapmalısınız!"), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    double? hedefFiyat = double.tryParse(fiyatController.text.replaceAll(',', '.'));
                    if (hedefFiyat == null) return;

                    // 🚀 Backend'e istek atıyoruz
                    bool basarili = await apiService.alarmEkleApi(userId, symbol, hedefFiyat, anlikFiyat);

                    Navigator.pop(context); // Bottom sheet'i kapat

                    if (basarili) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("$symbol için $hedefFiyat ₺ seviyesine alarm kuruldu!"),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Alarm kurulamadı, sunucu hatası!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text("Alarmı Aktif Et", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}