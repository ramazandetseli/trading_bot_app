from fastapi import APIRouter
import httpx
from datetime import datetime, timezone, timedelta

router = APIRouter(prefix="/takvim", tags=["Ekonomik Takvim"])



def _ingilizce_terimleri_cevir(metin: str) -> str:
    if not metin:
        return ""
    
    terimler = {
        "YoY": "(Yıllık)",
        "MoM": "(Aylık)",
        "QoQ": "(Çeyreklik)",
        "NSA": "(Mevsimsellikten Arındırılmamış)",
        "s.a.": "(Mevsimsellikten Arındırılmış)",
        "Prel": "(Öncü)",
        "Final": "(Kesin)",
        "Core": "Çekirdek",
        "Inflation Rate": "Enflasyon Oranı",
        "Interest Rate": "Faiz Oranı",
        "GDP Growth Rate": "GSYİH Büyüme Oranı",
        "GDP": "GSYİH",
        "PPI": "ÜFE",
        "CPI": "TÜFE",
        "Balance of Trade": "Dış Ticaret Dengesi",
        "Industrial Production": "Sanayi Üretimi",
        "Retail Sales": "Perakende Satışlar",
        "Initial Jobless Claims": "İşsizlik Maaşı Başvuruları",
        "Unemployment Rate": "İşsizlik Oranı",
        "Manufacturing PMI": "İmalat PMI",
        "Services PMI": "Hizmet PMI",
        "Current Account": "Cari Denge",
        "Exports": "İhracat",
        "Imports": "İthalat",
        "Foreign Exchange Reserves": "Döviz Rezervleri",
        "Consumer Confidence": "Tüketici Güveni",
        "Household Spending": "Hanehalkı Harcamaları",
        "Broad Money": "Geniş Para Arzı",
        "Money Supply M2": "M2 Para Arzı",
        "Existing Home Sales": "Mevcut Konut Satışları"
    }
    
    yeni_metin = metin
    for ing, tr in terimler.items():
        yeni_metin = yeni_metin.replace(ing, tr)
        
    return yeni_metin

def _format_takvim_verisi(item: dict) -> dict:
    country = str(item.get("country", "")).upper()

    ulke_haritasi = {
        "TR": {"ad": "Türkiye", "bayrak": "🇹🇷"},
        "US": {"ad": "ABD", "bayrak": "🇺🇸"},
        "EU": {"ad": "Euro Bölgesi", "bayrak": "🇪🇺"},
        "DE": {"ad": "Almanya", "bayrak": "🇩🇪"},
        "GB": {"ad": "İngiltere", "bayrak": "🇬🇧"},
        "CN": {"ad": "Çin", "bayrak": "🇨🇳"},
        "JP": {"ad": "Japonya", "bayrak": "🇯🇵"},
    }
    meta = ulke_haritasi.get(country, {"ad": country, "bayrak": "🌐"})

    raw_importance = item.get("importance", 0)
    if raw_importance >= 1:
        onem_seviyesi = "YÜKSEK"
        onem_puan = 3
    elif raw_importance == 0:
        onem_seviyesi = "ORTA"
        onem_puan = 2
    else:
        onem_seviyesi = "DÜŞÜK"
        onem_puan = 1

    return {
        "id": item.get("id"),
        "title": _ingilizce_terimleri_cevir(item.get("title", "")),
        "country_code": country,
        "country_name": meta["ad"],
        "flag": meta["bayrak"],
        "date_utc": item.get("date"),
        "period": item.get("period", ""),
        "actual": item.get("actual"),
        "forecast": item.get("forecast"),
        "previous": item.get("previous"),
        "scale": item.get("scale", ""),
        "unit": item.get("unit", ""),
        "importance_level": onem_seviyesi,
        "importance_score": onem_puan,
        "is_local": country == "TR",
    }


@router.get("/olaylar")
async def get_ekonomik_takvim(days_forward: int = 7, min_importance: int = 0):
    """TradingView üzerinden yerel (TR) ve global kritik ekonomik olayları çeker."""
    url = "https://economic-calendar.tradingview.com/events"

    now = datetime.now(timezone.utc)
    f_date = (now - timedelta(days=1)).strftime("%Y-%m-%dT00:00:00.000Z")
    t_date = (now + timedelta(days=days_forward)).strftime("%Y-%m-%dT23:59:59.000Z")

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
            " (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ),
        "Origin": "https://tr.tradingview.com",
        "Referer": "https://tr.tradingview.com/",
        "Accept": "application/json",
    }

    params = {
        "from": f_date,
        "to": t_date,
        "countries": "TR,US,EU,DE,GB,CN,JP",
        "minImportance": str(min_importance),
    }

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            res = await client.get(url, headers=headers, params=params)

        if res.status_code != 200:
            return {
                "islem_durumu": "hata",
                "mesaj": f"TradingView status: {res.status_code}",
                "yerel": [],
                "global": [],
            }

        raw_events = res.json().get("result", [])

        yerel = []
        global_olaylar = []

        for ev in raw_events:
            parsed = _format_takvim_verisi(ev)
            if parsed["is_local"]:
                yerel.append(parsed)
            else:
                global_olaylar.append(parsed)

        yerel.sort(key=lambda x: x["date_utc"] or "")
        global_olaylar.sort(key=lambda x: x["date_utc"] or "")

        return {
            "islem_durumu": "basarili",
            "toplam_olay": len(raw_events),
            "yerel": yerel,
            "global": global_olaylar,
        }

    except Exception as e:
        return {
            "islem_durumu": "hata",
            "hata_detayi": str(e),
            "yerel": [],
            "global": [],
        }