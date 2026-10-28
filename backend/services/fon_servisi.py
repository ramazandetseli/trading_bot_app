import uuid
import requests
import time
import json
import re
import yfinance as yf
from concurrent.futures import ThreadPoolExecutor

# --- TEFAS SABİTLERİ ---
TEFAS_HEADERS = {
    "Accept": "*/*",
    "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
    "Authorization": "Bearer ST-tefaswebwse3irfmSBj4iRAzGPbAlS94Se",
    "Content-Type": "application/json",
    "Origin": "https://www.tefas.gov.tr",
    "Referer": "https://www.tefas.gov.tr/tr",
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
}

PERIYOT_MAP = {"1ay": 1, "3ay": 3, "6ay": 6, "1yil": 12, "3yil": 36, "5yil": 60, "varsayilan": 3}
FON_TIP_ACIKLAMA = {"F": "Yatırım Fonu", "E": "Emeklilik Fonu", "B": "Borsa Yatırım Fonu", "Y": "Yabancı Yatırım Fonu"}
FON_TREND_CACHE = {"son_guncelleme": 0, "data": None}
CACHE_SURESI_SANIYE = 900
VITRIN_CACHE = {"zaman": 0, "veri": None}
VITRIN_CACHE_SURESI = 30

# --- TEFAS SERVİSLERİ ---

def fetch_tum_fonlar(fon_tip: str = None):
    try:
        url = "https://www.tefas.gov.tr/api/funds/fonUnvanAra"
        headers = TEFAS_HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())
        payload = {"dil": "TR", "aramaMetni": "", "fonTip": fon_tip}

        response = requests.post(url, json=payload, headers=headers, timeout=15)
        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        result_list = response.json().get("resultList", [])
        fonlar = [{"kod": item.get("fonKodu"), "unvan": item.get("fonUnvan")} for item in result_list]
        return {"islem_durumu": "basarili", "toplam_fon_sayisi": len(fonlar), "fonlar": fonlar}
    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}

def fetch_fon_detay(fon_kodu: str, aralik: str):
    try:
        url = "https://www.tefas.gov.tr/api/funds/fonFiyatBilgiGetir"
        headers = TEFAS_HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())
        payload = {"fonKodu": fon_kodu.upper(), "dil": "TR", "periyod": PERIYOT_MAP.get(aralik.lower(), 3)}

        response = requests.post(url, json=payload, headers=headers, timeout=10)
        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        result_list = response.json().get("resultList", [])
        if not result_list:
            return {"islem_durumu": "hata", "mesaj": f"{fon_kodu.upper()} için fiyat verisi bulunamadı."}

        result_list.sort(key=lambda x: x.get("tarih", ""))
        grafik_verisi = [{"date": i.get("tarih"), "price": round(float(i.get("fiyat", 0)), 6)} for i in result_list]

        ilk_fiyat = grafik_verisi[0]["price"]
        son_fiyat = grafik_verisi[-1]["price"]
        donemsel_getiri = ((son_fiyat - ilk_fiyat) / ilk_fiyat) * 100 if ilk_fiyat > 0 else 0
        son_kayit = result_list[-1]

        return {
            "islem_durumu": "basarili", "fon_kodu": son_kayit.get("fonKodu"), "fon_unvani": son_kayit.get("fonUnvan"),
            "secilen_aralik": aralik, "son_fiyat": son_fiyat, "donemsel_getiri_yuzde": round(donemsel_getiri, 2),
            "kategori_derecesi": son_kayit.get("kategoriDerece"), "kategori_toplam_fon": son_kayit.get("kategoriFonSay"),
            "veri_noktasi_sayisi": len(grafik_verisi), "grafik_verileri": grafik_verisi
        }
    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}

def fetch_fon_kiyaslama(fon_kodu: str, periyod: str):
    try:
        url = "https://www.tefas.gov.tr/api/funds/fonProfilDtyGetir"
        headers = TEFAS_HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())
        headers["Referer"] = f"https://www.tefas.gov.tr/tr/fon-detayli-analiz/{fon_kodu.upper()}"
        payload = {"dil": "TR", "fonKodu": fon_kodu.upper(), "periyod": str(periyod)}

        response = requests.post(url, json=payload, headers=headers, timeout=10)
        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        result_list = response.json().get("resultList", [])
        kiyaslama_listesi, fon_bilgisi = [], None

        for item in result_list:
            veri = {"enstruman": item.get("fonUnvan"), "kod": item.get("fonKodu"), "getiri_yuzde": round((item.get("fonTurGetiri") or 0.0) * 100, 2)}
            if item.get("fonKodu", "").upper() == fon_kodu.upper():
                fon_bilgisi = veri
            else:
                kiyaslama_listesi.append(veri)

        kiyaslama_listesi.sort(key=lambda x: x["getiri_yuzde"], reverse=True)
        return {"islem_durumu": "basarili", "fon": fon_bilgisi, "kiyaslama_araclari": kiyaslama_listesi}
    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}

def fetch_fon_tipi(fon_kodu: str):
    try:
        url = "https://www.tefas.gov.tr/api/funds/fonTipiGetir"
        headers = TEFAS_HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())
        headers["Referer"] = f"https://www.tefas.gov.tr/tr/fon-detayli-analiz/{fon_kodu.upper()}"
        payload = {"fonKodu": fon_kodu.upper()}

        response = requests.post(url, json=payload, headers=headers, timeout=10)
        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        fon_tip_kodu = response.json().get("fonTipi", "")
        return {"islem_durumu": "basarili", "fon_kodu": fon_kodu.upper(), "fon_tipi_kodu": fon_tip_kodu, "fon_tipi_aciklama": FON_TIP_ACIKLAMA.get(fon_tip_kodu, "Diğer Fon")}
    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}
def fetch_one_cikanlar():
    simdi = time.time()
    if FON_TREND_CACHE["data"] and (simdi - FON_TREND_CACHE["son_guncelleme"] < CACHE_SURESI_SANIYE):
        return {"islem_durumu": "basarili", "kaynak": "cache", **FON_TREND_CACHE["data"]}

    try:
        url = "https://www.tefas.gov.tr/api/funds/fonTurDnmGetiriGetir"
        headers = TEFAS_HEADERS.copy()
        headers["x-request-id"] = str(uuid.uuid4())
        payload = {"dil": "TR", "donem": 1}

        response = requests.post(url, json=payload, headers=headers, timeout=12)
        if response.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"TEFAS API hatası: {response.status_code}"}

        result_list = response.json().get("resultList", [])
        islenmis_fonlar = []
        
        # --- GÜNCELLEME: TEFAS API YANIT YAPISI DEĞİŞTİ ---
        for item in result_list:
            kategori = item.get("fonTurAciklama") or item.get("kategori") or "Yatırım Fonu"
            obje1_list = item.get("obje1List", [])
            
            for obje in obje1_list:
                fon_data = obje.get("data", [])
                for fon in fon_data:
                    kod = fon.get("name")      # Yeni yapıda fon kodu 'name' alanında
                    unvan = fon.get("id")      # Yeni yapıda fon unvanı 'id' alanında
                    getiri_ham = fon.get("y")  # Yeni yapıda getiri 'y' alanında
                    
                    if kod and unvan and getiri_ham is not None:
                        try:
                            islenmis_fonlar.append({
                                "kod": str(kod).strip().upper(),
                                "unvan": str(unvan).strip(),
                                "getiri_haftalik": round(float(getiri_ham), 2),
                                "kategori": kategori
                            })
                        except (ValueError, TypeError):
                            continue

        if not islenmis_fonlar:
            return {"islem_durumu": "hata", "mesaj": "TEFAS API'den fon verisi alınamadı (liste boş)."}

        islenmis_fonlar.sort(key=lambda x: x["getiri_haftalik"], reverse=True)
        haftanin_yukselenleri = islenmis_fonlar[:10]

        populer_kodlar = {"MAC", "TI3", "TTE", "IIH", "AFT", "YAS", "BIO", "TTA", "PPZ", "TCD", "NRC"}
        populer_fonlar = [f for f in islenmis_fonlar if f["kod"] in populer_kodlar]
        if len(populer_fonlar) < 5:
            populer_fonlar = islenmis_fonlar[10:20]

        trend_data = {"haftanin_yukselenleri": haftanin_yukselenleri, "populer_fonlar": populer_fonlar}
        FON_TREND_CACHE.update({"son_guncelleme": simdi, "data": trend_data})

        return {"islem_durumu": "basarili", "kaynak": "canli", **trend_data}
    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}
# --- FVT SERVİSİ ---


def fetch_fvt_portfoy(fon_kodu: str):
    fon_kodu = fon_kodu.strip().upper()
    url = f"https://fvt.com.tr/fonlar/yatirim-fonlari/{fon_kodu}"
    headers = {
        "accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36",
    }

    try:
        res = requests.get(url, headers=headers, timeout=10)
        res.encoding = 'utf-8'
        if res.status_code != 200:
            return {"islem_durumu": "hata", "mesaj": f"FVT bulunamadı. HTTP: {res.status_code}"}

        metin_ham = res.text

        sonuc = {
            "islem_durumu": "basarili", 
            "fon_kodu": fon_kodu, 
            "fon_adi": "Bilinmiyor", 
            "kategori": "Bilinmiyor", 
            "toplam_deger": "0", 
            "risk": "N/A", 
            "portfoy_ozeti": None,
            "portfoy_listesi": []
        }

        # 1. Künye Bilgileri
        idx = metin_ham.find('initialDetail":')
        if idx != -1:
            alt_metin = metin_ham[idx + 15:]
            start_brace = alt_metin.find('{')
            if start_brace != -1:
                parantez = 0
                end_idx = start_brace
                for i, char in enumerate(alt_metin[start_brace:]):
                    if char == '{': parantez += 1
                    elif char == '}': parantez -= 1
                    if parantez == 0:
                        end_idx = start_brace + i + 1
                        break
                try:
                    fund = json.loads(alt_metin[start_brace:end_idx]).get("fund", {})
                    sonuc.update({
                        "fon_adi": fund.get('fonAdi', 'Bilinmiyor'), 
                        "kategori": fund.get('kategori', 'Bilinmiyor'), 
                        "toplam_deger": fund.get('toplamDeger', '0')
                    })
                    risk_val = fund.get('risk')
                    if not risk_val or risk_val == "0":
                        rmatch = re.search(r'risk değeri 7 üzerinden (\d)', metin_ham, re.IGNORECASE)
                        risk_val = rmatch.group(1) if rmatch else "N/A"
                    sonuc["risk"] = risk_val
                except:
                    pass

        # 2. Portföy Hisseleri ve Oranları
        hisse_kaliplari = re.findall(r'([^.!?]*?hisseler:[^.!?]*?[.!?])', metin_ham, re.IGNORECASE)
        hedef_metin = ""
        for kalip in hisse_kaliplari:
            temiz_kalip = kalip.encode().decode('utf-8', errors='ignore')
            if fon_kodu in temiz_kalip or "hisse" in temiz_kalip.lower():
                hedef_metin = temiz_kalip.strip()
                sonuc["portfoy_ozeti"] = hedef_metin
                break
                
        if not hedef_metin:
            genel_match = re.search(r'fonunun portföyünde.*?(bulunmaktadır\..*?\.)', metin_ham)
            if genel_match: 
                hedef_metin = genel_match.group(0)
                sonuc["portfoy_ozeti"] = hedef_metin

        if hedef_metin:
            regex_kalibi = r'([A-Z]{4,5})\s*(?:\([^)]+\))?\s*%\s*(\d+(?:[,.]\d+)?)'
            eslesmeler = re.findall(regex_kalibi, hedef_metin)
            for hisse, oran in eslesmeler:
                try:
                    sonuc["portfoy_listesi"].append({
                        "symbol": hisse,
                        "weight": float(oran.replace(',', '.'))
                    })
                except:
                    continue

        return sonuc
    except Exception as e:
        return {"islem_durumu": "hata", "mesaj": str(e)}

# --- TAHMİN MOTORU ---
TAHMIN_CACHE = {}
CACHE_SURESI_SN = 30 

def fetch_fon_tahmini(fon_kodu: str):
    fon_kodu = fon_kodu.strip().upper()
    simdi = time.time()
    
    if fon_kodu in TAHMIN_CACHE:
        gecen_sure = simdi - TAHMIN_CACHE[fon_kodu]["zaman"]
        if gecen_sure < CACHE_SURESI_SN:
            return TAHMIN_CACHE[fon_kodu]["veri"]
            
    portfoy_verisi = fetch_fvt_portfoy(fon_kodu)
    if portfoy_verisi.get("islem_durumu") != "basarili" or not portfoy_verisi.get("portfoy_listesi"):
        return {"islem_durumu": "hata", "mesaj": "Portföy listesi alınamadı veya boş."}
        
    hisseler = portfoy_verisi["portfoy_listesi"]
    
    yabanci_listesi = ["MSFT", "NVDA", "AAPL", "GOOGL", "AMZN", "META", "TSLA", "AMD", "NFLX", "INTC"]
    semboller = []
    for h in hisseler:
        sym = h['symbol'].strip().upper()
        if sym in yabanci_listesi:
            semboller.append(sym)
        else:
            semboller.append(f"{sym}.IS" if not sym.endswith(".IS") else sym)
    
    toplam_katki = 0.0
    
    hesaplanan_hisseler = {
        h["symbol"]: {
            "symbol": h["symbol"], 
            "weight": h["weight"], 
            "hisse_getirisi": 0.0, 
            "katki": 0.0
        } for h in hisseler
    }
    
    art_list = []
    az_list = []

    try:
        data = yf.download(semboller, period="5d", progress=False)
        
        for hisse_obj in hisseler:
            sembol_saf = hisse_obj["symbol"].strip().upper()
            sembol_yf = sembol_saf if sembol_saf in yabanci_listesi else f"{sembol_saf}.IS"
            agirlik = hisse_obj["weight"]
            
            try:
                if len(semboller) == 1:
                    kapanislar = data['Close']
                else:
                    kapanislar = data['Close'][sembol_yf]
                    
                kapanislar = kapanislar.dropna()
                
                if len(kapanislar) >= 2:
                    dunku_kapanis = float(kapanislar.iloc[-2])
                    anlik_fiyat = float(kapanislar.iloc[-1])
                    
                    hisse_getirisi = ((anlik_fiyat - dunku_kapanis) / dunku_kapanis) * 100
                    fona_katkisi = (hisse_getirisi * agirlik) / 100
                    
                    toplam_katki += fona_katkisi
                    
                    hesaplanan_hisseler[sembol_saf]["hisse_getirisi"] = round(hisse_getirisi, 2)
                    hesaplanan_hisseler[sembol_saf]["katki"] = round(fona_katkisi, 4)
            except Exception:
                continue 

        detay_listesi = list(hesaplanan_hisseler.values())
        
        # Döngü bittikten sonra tüm liste üzerinden sıralama yapılıyor
        art_list = sorted(
            [h["symbol"] for h in detay_listesi if h["hisse_getirisi"] > 0], 
            key=lambda x: next(item["hisse_getirisi"] for item in detay_listesi if item["symbol"] == x), 
            reverse=True
        )
                        
        az_list = sorted(
            [h["symbol"] for h in detay_listesi if h["hisse_getirisi"] < 0], 
            key=lambda x: next(item["hisse_getirisi"] for item in detay_listesi if item["symbol"] == x)
        )

        print(f"DEBUG {fon_kodu} -> Artanlar: {art_list[:5]}, Azalanlar: {az_list[:5]}")
                
    except Exception:
        pass 
        
    sonuc = {
        "islem_durumu": "basarili",
        "fon_kodu": fon_kodu,
        "tahmini_getiri": round(toplam_katki, 2),
        "detaylar": list(hesaplanan_hisseler.values()),
        "artanlar": art_list[:5],
        "azalanlar": az_list[:5],
        "eklenenler": portfoy_verisi.get("eklenenler", []),
        "cikanlar": portfoy_verisi.get("cikanlar", [])
    }
    
    TAHMIN_CACHE[fon_kodu] = {
        "zaman": simdi,
        "veri": sonuc
    }
    
    return sonuc

def fetch_fon_vitrini():
    simdi = time.time()
    
    if VITRIN_CACHE["veri"] and (simdi - VITRIN_CACHE["zaman"] < VITRIN_CACHE_SURESI):
        return VITRIN_CACHE["veri"]

    try:
        otomatik_populer_kodlar = ["THF", "PHE", "DOH", "DFI", "TLY", "PBR"]
        
        def tek_fon_islet(p_kod):
            ai_getiri = 0.0
            fon_adi = f"{p_kod} Yatırım Fonu"
            try:
                tahmin_sonuc = fetch_fon_tahmini(p_kod)
                if tahmin_sonuc.get("islem_durumu") == "basarili":
                    ai_getiri = tahmin_sonuc.get("tahmini_getiri", 0.0)
            except:
                pass
            
            return {
                "kod": p_kod,
                "unvan": fon_adi,
                "ai_tahmini": ai_getiri
            }

        with ThreadPoolExecutor(max_workers=6) as executor:
            popular_ai = list(executor.map(tek_fon_islet, otomatik_populer_kodlar))

        sonuc = {
            "islem_durumu": "basarili",
            "popular_ai": popular_ai
        }

        VITRIN_CACHE["zaman"] = simdi
        VITRIN_CACHE["veri"] = sonuc

        return sonuc
    except Exception as e:
        print("VİTRİN HATA:", str(e))
        return {"islem_durumu": "hata", "mesaj": str(e)}



