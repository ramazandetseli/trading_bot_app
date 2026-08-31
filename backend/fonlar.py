from fastapi import APIRouter, Query
import uuid
import requests
import time

router = APIRouter()

HEADERS = {
    "Accept": "*/*",
    "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
    "Authorization": "Bearer ST-tefaswebwse3irfmSBj4iRAzGPbAlS94Se",
    "Content-Type": "application/json",
    "Origin": "https://www.tefas.gov.tr",
    "Referer": "https://www.tefas.gov.tr/tr",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

PERIYOT_MAP = {
    "1ay": 1,
    "3ay": 3,
    "6ay": 6,
    "1yil": 12,
    "3yil": 36,
    "5yil": 60,
    "varsayilan": 3
}

FON_TIP_ACIKLAMA = {
    "F": "Yatırım Fonu",
    "E": "Emeklilik Fonu",
    "B": "Borsa Yatırım Fonu",
    "Y": "Yabancı Yatırım Fonu"
}

@router.get("/tum-fonlar")
def get_tum_fonlar(fon_tip: str = None):
    """
    Tüm aktif fonların listesini çeker.
    """
    try:
        url = "https://www.tefas.gov.tr/api/funds/fonUnvanAra"
        
        headers = HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())

        payload = {
            "dil": "TR",
            "aramaMetni": "",
            "fonTip": fon_tip
        }

        response = requests.post(url, json=payload, headers=headers, timeout=15)

        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        res_data = response.json()
        result_list = res_data.get("resultList", [])

        fonlar = [
            {
                "kod": item.get("fonKodu"),
                "unvan": item.get("fonUnvan")
            }
            for item in result_list
        ]

        return {
            "islem_durumu": "basarili",
            "toplam_fon_sayisi": len(fonlar),
            "fonlar": fonlar
        }

    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}


@router.get("/detay/{fon_kodu}")
def get_fon_detay(fon_kodu: str, aralik: str = Query(default="3ay")):
    """
    Fonun tarihsel fiyatlarını ve grafik verisini çeker.
    """
    try:
        url = "https://www.tefas.gov.tr/api/funds/fonFiyatBilgiGetir"
        
        headers = HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())

        periyod_kodu = PERIYOT_MAP.get(aralik.lower(), 3)

        payload = {
            "fonKodu": fon_kodu.upper(),
            "dil": "TR",
            "periyod": periyod_kodu
        }

        response = requests.post(url, json=payload, headers=headers, timeout=10)

        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        res_data = response.json()
        result_list = res_data.get("resultList", [])

        if not result_list:
            return {"islem_durumu": "hata", "mesaj": f"{fon_kodu.upper()} için fiyat verisi bulunamadı."}

        result_list.sort(key=lambda x: x.get("tarih", ""))

        grafik_verisi = []
        for item in result_list:
            grafik_verisi.append({
                "date": item.get("tarih"),
                "price": round(float(item.get("fiyat", 0)), 6)
            })

        ilk_fiyat = grafik_verisi[0]["price"]
        son_fiyat = grafik_verisi[-1]["price"]
        donemsel_getiri = ((son_fiyat - ilk_fiyat) / ilk_fiyat) * 100 if ilk_fiyat > 0 else 0

        son_kayit = result_list[-1]

        return {
            "islem_durumu": "basarili",
            "fon_kodu": son_kayit.get("fonKodu"),
            "fon_unvani": son_kayit.get("fonUnvan"),
            "secilen_aralik": aralik,
            "son_fiyat": son_fiyat,
            "donemsel_getiri_yuzde": round(donemsel_getiri, 2),
            "kategori_derecesi": son_kayit.get("kategoriDerece"),
            "kategori_toplam_fon": son_kayit.get("kategoriFonSay"),
            "veri_noktasi_sayisi": len(grafik_verisi),
            "grafik_verileri": grafik_verisi
        }

    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}


@router.get("/profil/{fon_kodu}")
def get_fon_profil(fon_kodu: str, periyod: str = "12"):
    """
    Fonun Altın, BIST, Mevduat ve Enflasyon ile kıyaslama analizini çeker.
    """
    try:
        url = "https://www.tefas.gov.tr/api/funds/fonProfilDtyGetir"
        
        headers = HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())
        headers["Referer"] = f"https://www.tefas.gov.tr/tr/fon-detayli-analiz/{fon_kodu.upper()}"

        payload = {
            "dil": "TR",
            "fonKodu": fon_kodu.upper(),
            "periyod": str(periyod)
        }

        response = requests.post(url, json=payload, headers=headers, timeout=10)

        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        res_data = response.json()
        result_list = res_data.get("resultList", [])

        kiyaslama_listesi = []
        fon_bilgisi = None

        for item in result_list:
            getiri_ham = item.get("fonTurGetiri") or 0.0
            getiri_yuzde = round(getiri_ham * 100, 2)
            
            veri = {
                "enstruman": item.get("fonUnvan"),
                "kod": item.get("fonKodu"),
                "getiri_yuzde": getiri_yuzde
            }

            if item.get("fonKodu", "").upper() == fon_kodu.upper():
                fon_bilgisi = veri
            else:
                kiyaslama_listesi.append(veri)

        kiyaslama_listesi.sort(key=lambda x: x["getiri_yuzde"], reverse=True)

        return {
            "islem_durumu": "basarili",
            "fon": fon_bilgisi,
            "kiyaslama_araclari": kiyaslama_listesi
        }

    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}


@router.get("/tip/{fon_kodu}")
def get_fon_tipi(fon_kodu: str):
    """
    Fonun tür kodunu (F=Yatırım Fonu, E=Emeklilik Fonu vb.) çeker.
    """
    try:
        url = "https://www.tefas.gov.tr/api/funds/fonTipiGetir"
        
        headers = HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())
        headers["Referer"] = f"https://www.tefas.gov.tr/tr/fon-detayli-analiz/{fon_kodu.upper()}"

        payload = {
            "fonKodu": fon_kodu.upper()
        }

        response = requests.post(url, json=payload, headers=headers, timeout=10)

        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        res_data = response.json()
        fon_tip_kodu = res_data.get("fonTipi", "")

        return {
            "islem_durumu": "basarili",
            "fon_kodu": fon_kodu.upper(),
            "fon_tipi_kodu": fon_tip_kodu,
            "fon_tipi_aciklama": FON_TIP_ACIKLAMA.get(fon_tip_kodu, "Diğer Fon")
        }

    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}



@router.get("/kiyaslama/{fon_kodu}")
def get_fon_kiyaslama(fon_kodu: str, periyod: str = "12"):
    """
    Fonun getirisini Altın, BIST100, Mevduat, Dolar ve Enflasyon ile kıyaslar.
    """
    try:
        url = "https://www.tefas.gov.tr/api/funds/fonProfilDtyGetir"
        
        headers = HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())
        headers["Referer"] = f"https://www.tefas.gov.tr/tr/fon-detayli-analiz/{fon_kodu.upper()}"

        payload = {
            "dil": "TR",
            "fonKodu": fon_kodu.upper(),
            "periyod": str(periyod)
        }

        response = requests.post(url, json=payload, headers=headers, timeout=10)

        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        res_data = response.json()
        result_list = res_data.get("resultList", [])

        kiyaslama_listesi = []
        fon_bilgisi = None

        for item in result_list:
            getiri_ham = item.get("fonTurGetiri") or 0.0
            getiri_yuzde = round(getiri_ham * 100, 2)
            
            veri = {
                "enstruman": item.get("fonUnvan"),
                "kod": item.get("fonKodu"),
                "getiri_yuzde": getiri_yuzde
            }

            if item.get("fonKodu", "").upper() == fon_kodu.upper():
                fon_bilgisi = veri
            else:
                kiyaslama_listesi.append(veri)

        # Getiriye göre yüksekten düşüğe sırala
        kiyaslama_listesi.sort(key=lambda x: x["getiri_yuzde"], reverse=True)

        return {
            "islem_durumu": "basarili",
            "fon": fon_bilgisi,
            "kiyaslama_araclari": kiyaslama_listesi
        }

    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}






FON_TREND_CACHE = {
    "son_guncelleme": 0,
    "data": None
}
CACHE_SURESI_SANIYE = 900

@router.get("/one-cikanlar")
def get_one_cikan_fonlar():
    """
    TEFAS fonTurDnmGetiriGetir servisini kullanarak haftalık en çok yükselenleri ve popüler fonları getirir.
    """
    simdi = time.time()
    
    # 1. Önbellek kontrolü
    if FON_TREND_CACHE["data"] and (simdi - FON_TREND_CACHE["son_guncelleme"] < CACHE_SURESI_SANIYE):
        return {
            "islem_durumu": "basarili",
            "kaynak": "cache",
            **FON_TREND_CACHE["data"]
        }

    try:
        url = "https://www.tefas.gov.tr/api/funds/fonTurDnmGetiriGetir"
        
        headers = HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())

        # donem: 1 -> 1 Haftalık getiri verisi
        payload = {
            "dil": "TR",
            "donem": 1
        }

        response = requests.post(url, json=payload, headers=headers, timeout=12)

        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        res_data = response.json()
        result_list = res_data.get("resultList", [])

        if not result_list:
            return {"islem_durumu": "hata", "mesaj": "Veri listesi boş döndü."}

        # Verileri ayrıştır ve sayısal getiriye göre sırala
        islenmis_fonlar = []
        for item in result_list:
            kod = item.get("fonKodu") or item.get("kod")
            unvan = item.get("fonUnvan") or item.get("unvan")
            getiri_ham = item.get("getiri") or item.get("fonGetiri") or item.get("getiriOran") or 0.0
            kategori = item.get("fonTuruAciklama") or item.get("kategori") or "Yatırım Fonu"

            if kod and unvan:
                try:
                    getiri_val = round(float(str(getiri_ham).replace(",", ".")), 2)
                    islenmis_fonlar.append({
                        "kod": kod.strip().upper(),
                        "unvan": unvan.strip(),
                        "getiri_haftalik": getiri_val,
                        "kategori": kategori
                    })
                except (ValueError, TypeError):
                    continue

        # 1. Haftanın En Çok Kazandıranları (En yüksek getiriden azalan sıraya)
        islenmis_fonlar.sort(key=lambda x: x["getiri_haftalik"], reverse=True)
        haftanin_yukselenleri = islenmis_fonlar[:10]

        # 2. Popüler / Bilinen Güçlü Fonlar
        populer_kodlar = {"MAC", "TI3", "TTE", "IIH", "AFT", "YAS", "BIO", "TTA", "PPZ", "TCD", "NRC"}
        populer_fonlar = [f for f in islenmis_fonlar if f["kod"] in populer_kodlar]
        
        # Popüler fonlardan eşleşmeyen olursa ilk 10'dan sonrakileri ekle
        if len(populer_fonlar) < 5:
            populer_fonlar = islenmis_fonlar[10:20]

        trend_data = {
            "haftanin_yukselenleri": haftanin_yukselenleri,
            "populer_fonlar": populer_fonlar
        }

        # Önbelleğe kaydet
        FON_TREND_CACHE["son_guncelleme"] = simdi
        FON_TREND_CACHE["data"] = trend_data

        return {
            "islem_durumu": "basarili",
            "kaynak": "canli",
            **trend_data
        }

    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}