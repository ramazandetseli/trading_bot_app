import 'package:flutter/material.dart';

class AlarmKur {
  // 🎯 İstediğin yerden AlarmKur.goster() diyerek çağırabilirsin
  static void goster({
    required BuildContext context,
    required String symbol,
    required double anlikFiyat,
  }) {
    TextEditingController fiyatController = TextEditingController(text: anlikFiyat.toStringAsFixed(2));

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
                keyboardType: const TextInputType.numberWithOptions(decimal: true), // Virgüllü sayılar için klavye amk
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
                    // TODO: İleride Python /alarm-kur bittiğinde buraya HTTP postu çakacağız amk
                    Navigator.pop(context); // Bottom sheet'i kapat
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("$symbol için ${fiyatController.text} ₺ seviyesine alarm kuruldu!"),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
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