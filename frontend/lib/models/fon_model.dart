import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trading_bot_app/constants/app_constants.dart';

class FonOzetModel {
  final String kod;
  final String unvan;
  final double getiriHaftalik;
  final String kategori;

  FonOzetModel({required this.kod, required this.unvan, required this.getiriHaftalik, required this.kategori});

  factory FonOzetModel.fromJson(Map<String, dynamic> json) {
    return FonOzetModel(
      kod: json['kod'] ?? '',
      unvan: json['unvan'] ?? '',
      getiriHaftalik: (json['getiri_haftalik'] as num?)?.toDouble() ?? 0.0,
      kategori: json['kategori'] ?? '',
    );
  }
}

class FonFiyatNoktasi {
  final DateTime date;
  final double price;

  FonFiyatNoktasi({required this.date, required this.price});

  factory FonFiyatNoktasi.fromJson(Map<String, dynamic> json) {
    return FonFiyatNoktasi(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FonDetayModel {
  final String fonKodu;
  final String fonUnvani;
  final String secilenAralik;
  final double sonFiyat;
  final double donemselGetiriYuzde;
  final int? kategoriDerecesi;
  final int? kategoriToplamFon;
  final List<FonFiyatNoktasi> grafikVerileri;

  FonDetayModel({
    required this.fonKodu,
    required this.fonUnvani,
    required this.secilenAralik,
    required this.sonFiyat,
    required this.donemselGetiriYuzde,
    this.kategoriDerecesi,
    this.kategoriToplamFon,
    required this.grafikVerileri,
  });

  factory FonDetayModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['grafik_verileri'] as List? ?? [];
    return FonDetayModel(
      fonKodu: json['fon_kodu'] ?? '',
      fonUnvani: json['fon_unvani'] ?? '',
      secilenAralik: json['secilen_aralik'] ?? '3ay',
      sonFiyat: (json['son_fiyat'] as num?)?.toDouble() ?? 0.0,
      donemselGetiriYuzde: (json['donemsel_getiri_yuzde'] as num?)?.toDouble() ?? 0.0,
      kategoriDerecesi: json['kategori_derecesi'],
      kategoriToplamFon: json['kategori_toplam_fon'],
      grafikVerileri: rawList.map((e) => FonFiyatNoktasi.fromJson(e)).toList(),
    );
  }
}

class FonKiyaslamaItem {
  final String enstruman;
  final String kod;
  final double getiriYuzde;

  FonKiyaslamaItem({
    required this.enstruman,
    required this.kod,
    required this.getiriYuzde,
  });

  factory FonKiyaslamaItem.fromJson(Map<String, dynamic> json) {
    return FonKiyaslamaItem(
      enstruman: json['enstruman'] ?? json['kod'] ?? '',
      kod: json['kod'] ?? '',
      getiriYuzde: (json['getiri_yuzde'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class FonKiyaslamaModel {
  final FonKiyaslamaItem? fon;
  final List<FonKiyaslamaItem> kiyaslamaAraclari;

  FonKiyaslamaModel({
    this.fon,
    required this.kiyaslamaAraclari,
  });

  factory FonKiyaslamaModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['kiyaslama_araclari'] as List? ?? [];
    return FonKiyaslamaModel(
      fon: json['fon'] != null ? FonKiyaslamaItem.fromJson(json['fon']) : null,
      kiyaslamaAraclari: rawList.map((e) => FonKiyaslamaItem.fromJson(e)).toList(),
    );
  }


  Future<Map<String, List<FonOzetModel>>> getOneCikanFonlar() async {
    try {
      final response = await http
      .get(AppConstants.oneCikanFonlarUri)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['islem_durumu'] == 'basarili') {
          final yukselenler = (data['haftanin_yukselenleri'] as List? ?? [])
              .map((e) => FonOzetModel.fromJson(e))
              .toList();
          final populer = (data['populer_fonlar'] as List? ?? [])
              .map((e) => FonOzetModel.fromJson(e))
              .toList();

          return {
            'yukselenler': yukselenler,
            'populer': populer,
          };
        }
      }
    } catch (e) {
      debugPrint("Öne çıkan fonlar çekilirken hata: $e");
    }
    return {'yukselenler': [], 'populer': []};
  }
}