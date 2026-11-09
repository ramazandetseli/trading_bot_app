import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../../../models/ekonomik_takvim_model.dart';
import '../ekonomik_takvim_screen.dart';

class EkonomikTakvimOzetCard extends StatefulWidget {
  const EkonomikTakvimOzetCard({super.key});

  @override
  State<EkonomikTakvimOzetCard> createState() => _EkonomikTakvimOzetCardState();
}

class _EkonomikTakvimOzetCardState extends State<EkonomikTakvimOzetCard> {
  bool _isLoading = true;
  List<EkonomikOlay> _oncelikliOlaylar = [];

  @override
  void initState() {
    super.initState();
    _ozetVeriCek();
  }

  Future<void> _ozetVeriCek() async {
    try {
      final res = await http
          .get(Uri.parse(AppConstants.ekonomikTakvimUrl))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = TakvimResponse.fromJson(json.decode(utf8.decode(res.bodyBytes)));
        
        // Önce yerel (TR) olayları, ardından küresel yüksek önemlileri birleştirip ilk 3 tanesini al
        List<EkonomikOlay> havuz = [];
        havuz.addAll(data.yerel);
        havuz.addAll(data.global.where((e) => e.importanceScore >= 2));
        havuz.sort((a, b) => a.date.compareTo(b.date));

        if (mounted) {
          setState(() {
            _oncelikliOlaylar = havuz.take(3).toList();
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _onemRengi(int score) {
    if (score >= 3) return Colors.redAccent;
    if (score == 2) return Colors.amber;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Ekonomik Takvim",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EkonomikTakvimScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        "Tümü",
                        style: TextStyle(color: Colors.blueAccent, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.chevron_right, color: Colors.blueAccent, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                ),
              ),
            )
          else if (_oncelikliOlaylar.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Yakın zamanda kritik veri akışı yok.",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            )
          else
            Column(
              children: _oncelikliOlaylar.map((olay) {
                final saat = DateFormat('dd MMM HH:mm').format(olay.date);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _onemRengi(olay.importanceScore),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(olay.flag, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              olay.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              "$saat • Beklenti: ${olay.formatDeger(olay.forecast)}",
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}