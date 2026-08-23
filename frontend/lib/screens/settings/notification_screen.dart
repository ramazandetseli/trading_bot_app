import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool isEnabled = false;
  bool isAlarmEnabled = false;
  bool isStockHunterEnabled = false;
  bool isNewsEnabled = false;
  @override
  Widget build(BuildContext context) {
    final textColor= Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bildirim Ayarları"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text("Bildirimleri Aç/Kapat",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.amber),),
              value: isEnabled,
              onChanged: (value) {
                setState(() {
                  isAlarmEnabled = value;
                  isEnabled = value;
                  isStockHunterEnabled = value;
                  isNewsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text("Alarm bildirimleri"),
              value: isAlarmEnabled,
              onChanged: (value) {
                setState(() {
                  if(isEnabled){
                    isAlarmEnabled = value;
                  }
                 
                });
              },
            ),
            SwitchListTile(
              title: const Text("Hisse avcısı bildirimleri"),
              value: isStockHunterEnabled,
              onChanged: (value) {
                setState(() {
                  if(isEnabled){
                  isStockHunterEnabled = value;
                  }
                });
              },
            ),
            SwitchListTile(
              title: const Text("Hisse haber bildirimleri"),
              value: isNewsEnabled,
              onChanged: (value) {
                setState(() {
                  if(isEnabled){
                  isNewsEnabled = value;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}