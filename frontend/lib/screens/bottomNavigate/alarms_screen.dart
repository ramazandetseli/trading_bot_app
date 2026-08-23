import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {

  List<dynamic> alarmliHisseler = [];
  bool yukleniyor = true;

@override
  void initState() {
    super.initState();
    alarmlariGetir(); // Ekran açılır açılmaz verileri çek
  }

  Future<void> alarmlariGetir() async {
    try {
      final response = await http.get(Uri.parse('https://trading-bot-backend-2pyt.onrender.com/alarmlar'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          alarmliHisseler = data['alarmlar']; // Python'daki anahtar ismiyle aynı
          yukleniyor = false;
        });
      }
    } catch (e) {
      print("Alarmlar çekilemedi: $e");
      setState(() => yukleniyor = false);
    }
  }

  Future<void> alarmSil(int index) async {
    try {
      final response = await http.delete(Uri.parse('https://trading-bot-backend-2pyt.onrender.com/alarm-sil/$index'));
      if (response.statusCode == 200) {
        setState(() {
          alarmliHisseler.removeAt(index);
        });
      }
    } catch (e) {
      print("Silme hatası: $e");
    }
  }
Future<void> alarmGuncelleApiCall(int index, String newPrice) async {
  double? price = double.tryParse(newPrice);
  if (price == null) return;

  try {
    final response = await http.put(
      Uri.parse('https://trading-bot-backend-2pyt.onrender.com/alarm-duzenle/$index?new_price=$price'),
    );

    if (response.statusCode == 200) {
      
      alarmlariGetir(); // Listeyi tazele
    }
  } catch (e) {
    print("Güncelleme hatası: $e");
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Alarmlarım"),
      ),
      body: alarmliHisseler.isEmpty
      ?Center(child: Text("Henüz herhangi bir hisse için alarm kurmadınız."),)
      : ListView.builder(
        itemCount: alarmliHisseler.length,
        itemBuilder:(context, index) {
          final Map<String, dynamic> alarm = alarmliHisseler[index];
          return ListTile(
            title: Text(
                alarm["symbol"] ?? "Belirsiz", 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
            subtitle: Text(
                "Hedef: ${alarm['target_price']} TL", 
                style: const TextStyle(color: Colors.grey)
                ),
            trailing: IconButton(
                onPressed: () => alarmSil(index), 
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                ),
              leading: IconButton(
    icon: const Icon(Icons.edit, color: Colors.blueAccent),
    onPressed: () {
      // 1. Kutunun içine mevcut fiyatı yazdırıyoruz
      TextEditingController editController = TextEditingController(
        text: alarm['target_price'].toString()
      );

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: Text("${alarm['symbol']} Düzenle", style: TextStyle(color: Colors.white)),
          content: TextField(
            maxLength: 7,
            controller: editController,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: "Yeni Hedef Fiyat"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () {
                // 3. Python'a güncelleme emrini gönderiyoruz
                alarmGuncelleApiCall(index, editController.text);
                Navigator.pop(context);
              },
              child: const Text("Güncelle"),
            ),
          ],
        ),
      );
    },
  ),
          );
        },
        )
    );


  }

  
}