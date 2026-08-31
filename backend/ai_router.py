
from fastapi import APIRouter
import requests
import json
import yfinance as yf
import pandas as pd

router = APIRouter(prefix="/ai", tags=["Yapay Zeka Analizi"])

GROQ_API_KEY = "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"
GROQ_MODEL = "openai/gpt-oss-20b"

# ---------------------------------------------------------
# 🟢 BASIC ANALİZ (KISA, ÖZET, HIZLI)
# ---------------------------------------------------------
@router.get("/basic-analiz")
def get_basic_analiz(symbol: str, price: str, rsi: str):
    clean_symbol = symbol.strip().upper()
    ticker_symbol = clean_symbol.replace("BIST:", "") + ".IS" if not clean_symbol.endswith(".IS") else clean_symbol

    haberler_metni = "Önemli bir haber akışı bulunamadı."
    try:
        ticker = yf.Ticker(ticker_symbol)
        news = ticker.news[:2]
        if news:
            haberler_metni = "\n".join([f"- {n['title']}" for n in news])
    except:
        pass

    # 🔥 KISITLAYICI PROMPT: Maksimum 2-3 cümle.
    prompt = f"""Sen bir borsa yorumcususun. Hisse: {clean_symbol}, Fiyat: {price}, RSI: {rsi}. 
    Haberler: {haberler_metni}
    Bana SADECE 2 veya 3 cümlelik, çok kısa ve net bir piyasa özeti ver. Kesinlikle uzun paragraf yazma. Destek direnç verme.
    
    ÇOK ÖNEMLİ KURAL: ÇIKTIN KESİNLİKLE VE TAMAMEN TÜRKÇE OLMALIDIR! İNGİLİZCE KELİME KULLANMA."""

    payload = {
        "model": GROQ_MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.5
    }

    try:
        res = requests.post("https://api.groq.com/openai/v1/chat/completions", json=payload, headers={"Authorization": f"Bearer {GROQ_API_KEY}"})
        if res.status_code == 200:
            yorum = res.json()['choices'][0]['message']['content']
            return {"status": "success", "analiz_tipi": "basic", "yorum": yorum}
        return {"status": "error", "message": f"Hata: {res.text}"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# ---------------------------------------------------------
# 👑 DEEP ANALİZ (SEÇİLİ GRAFİK PERİYODU + PİVOT DESTEK/DİRENÇ + HACİM)
# ---------------------------------------------------------
@router.get("/deep-analiz")
def get_deep_analiz(symbol: str, rsi: str, vol: str, price: str, change: str, period: str = "1mo"):
    clean_symbol = symbol.strip().upper()
    ticker_symbol = clean_symbol.replace("BIST:", "") + ".IS" if not clean_symbol.endswith(".IS") else clean_symbol

    try:
        price_val = float(str(price).replace(",", "."))
        rsi_val = float(str(rsi).replace(",", "."))
        change_val = float(str(change).replace(",", "."))
    except:
        return {"status": "error", "message": "Veri formatı hatalı."}

    # 1. 🚀 GERÇEK GRAFİK VERİSİNİ OKUMA VE PİVOT HESAPLAMA
    teknik_ozet = "Veri eksik"
    hesaplanan_destek = price_val * 0.95
    hesaplanan_direnc = price_val * 1.05

    try:
        ticker = yf.Ticker(ticker_symbol)
        # Kullanıcının ekranda seçtiği periyodu (1mo, 1y vs) çekiyoruz
        df = ticker.history(period=period) 
        
        if not df.empty:
            en_yuksek = df['High'].max()
            en_dusuk = df['Low'].min()
            ort_hacim = df['Volume'].mean()
            son_hacim = df['Volume'].iloc[-1]
            
            # Hacim Kıyaslaması (Ortalamaya göre ne kadar yüksek?)
            hacim_durumu = "Ortalamanın altında"
            if son_hacim > (ort_hacim * 1.5):
                hacim_durumu = f"Ortalamanın %{int((son_hacim/ort_hacim)*100 - 100)} üzerinde CİDDİ PATLAMA"
            
            # Pivot Noktası (Klasik Teknik Analiz Formülü)
            pivot = (en_yuksek + en_dusuk + price_val) / 3
            hesaplanan_direnc = round((2 * pivot) - en_dusuk, 2)
            hesaplanan_destek = round((2 * pivot) - en_yuksek, 2)
            
            # Güvenlik (Fiyatın altına/üstüne taşmasın)
            if hesaplanan_destek >= price_val: hesaplanan_destek = round(price_val * 0.96, 2)
            if hesaplanan_direnc <= price_val: hesaplanan_direnc = round(price_val * 1.04, 2)

            teknik_ozet = f"Son {period} içinde en yüksek {en_yuksek:.2f}, en düşük {en_dusuk:.2f} görülmüş. Güncel hacim: {hacim_durumu}."
    except Exception as e:
        print("Geçmiş veri hatası:", e)

    # 2. Tahtacı Algoritması
    if change_val > 3.0 and float(vol) > 2.0:
        strateji_etiketi, fon_akisi = "Kurumsal Ralli Başlangıcı", "Agresif Para Girişi"
    elif change_val < -2.0 and float(vol) > 2.0:
        strateji_etiketi, fon_akisi = "Sert Silkeleme (Ayı Tuzağı)", "Panik Satışı / Tahtacı Karşılama"
    else:
        strateji_etiketi, fon_akisi = "Yatay Akümülasyon", "Dengeli Akış"

    risk_skoru = min(20.0 + (30 if rsi_val > 70 or rsi_val < 35 else 0), 95.0)

    # 3. 🔥 UZUN VE DETAYLI DEEP PROMPT
    prompt = f"""Sen Kıdemli bir Borsa Analistisin. Kullanıcı Premium analiz istedi.
    {clean_symbol} hissesi için seçili ({period}) periyoduna özel, derin ve kurumsal bir rapor hazırla.
    
    VERİLER:
    Fiyat: {price_val} TL | RSI: {rsi_val} | Günlük Değişim: %{change_val}
    Seçili Grafik ({period}) Özeti: {teknik_ozet}
    Algoritmik Durum: Strateji={strateji_etiketi}, Fon={fon_akisi}
    Matematiksel Destek: {hesaplanan_destek} | Matematiksel Direnç: {hesaplanan_direnc}
    
    ÖNEMLİ KURALLAR:
    1. Çıktın SADECE AŞAĞIDAKİ JSON OLMALIDIR. Markdown (```json) kullanma.
    2. JSON İÇİNDEKİ TÜM METİNLER KESİNLİKLE TÜRKÇE OLMALIDIR! Asla İngilizce yanıt verme.
    
    {{
    "ozet": "Seçilen periyottaki hacim ve fiyat hareketini detaylı anlatan geniş 2-3 cümle.",
    "teknik_durum": "RSI ve {period} grafiğindeki zirve/dip noktalarına göre teknik risk/fırsat analizi (uzun cümleler kullan).",
    "tahtaci_analizi": "Hacimdeki ({teknik_ozet}) patlamaya veya düşüşe göre tahtacının asıl amacı nedir? Detaylı açıkla.",
    "destek": {hesaplanan_destek},
    "direnc": {hesaplanan_direnc}
    }}"""

    payload = {
        "model": GROQ_MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "response_format": {"type": "json_object"}, 
        "temperature": 0.2
    }

    try:
        res = requests.post("https://api.groq.com/openai/v1/chat/completions", json=payload, headers={"Authorization": f"Bearer {GROQ_API_KEY}"})
        if res.status_code == 200:
            raw = res.json()['choices'][0]['message']['content'].replace("```json", "").replace("```", "").strip()
            data = json.loads(raw)
            data.update({"strateji_etiketi": strateji_etiketi, "risk_skoru": risk_skoru, "fon_akisi": fon_akisi})
            return {"status": "success", "analiz_tipi": "deep", "data": data}
        return {"status": "error", "message": res.text}
    except Exception as e:
        return {"status": "error", "message": str(e)}