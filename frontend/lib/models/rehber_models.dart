class RehberModels {
  final String id;
  final String kategori;
  final String baslik;
  final String ozet;
  final String detayMetni;
  final String resimUrl;
  final String graphicUrl;
  RehberModels({
    required this.id,
    required this.kategori,
    required this.baslik,
    required this.ozet,
    required this.detayMetni,
    required this.resimUrl,
    required this.graphicUrl,
  });


  factory RehberModels.fromMap(Map<String, dynamic> map) {
    return RehberModels(
      id: map['id'],
      kategori: map['kategori'],
      baslik: map['baslik'],
      ozet: map['ozet'],
      detayMetni: map['detay_metni'],
      resimUrl: map['resim_url'],
      graphicUrl: map['graphic_url'],
    );
  }

}