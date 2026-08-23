import requests

def get_scan_results():
    url = "https://scanner.tradingview.com/turkey/scan"
    
    payload = {
        "filter": [{"left": "type", "operation": "in_range", "right": ["stock"]}],
        "options": {"lang": "tr"},
        "markets": ["turkey"],
        # SADECE API'NİN KABUL ETTİĞİ GERÇEK KOLONLAR
        "columns": [
            "name",                     # [0] İsim
            "close",                    # [1] Fiyat
            "change",                   # [2] Günlük Değişim %
            "volume",                   # [3] Anlık Hacim
            "RSI",                      # [4] RSI (14)
            "relative_volume_10d_calc", # [5] Göreceli Hacim
            "average_volume_10d_calc",  # [6] 10 Günlük Ortalama Hacim
            "SMA50",                    # [7] 50 Günlük Ortalama
            "SMA200",                   # [8] 200 Günlük Ortalama
            "BB.lower",                 # [9] Bollinger Alt Bant
            "BB.upper",                 # [10] Bollinger Üst Bant
            "EMA20",                    # [11] 20 Günlük Ortalama (Eski kodundaki)
            "open",                     # [12] Açılış Fiyatı (Çorbacı için)
            "description"               # [13] Şirket Adı
        ], 
        "sort": {"sortBy": "name", "sortOrder": "asc"},
        "range": [0, 550]
    }

    try:
        response = requests.post(url, json=payload, timeout=20)
        
        # Eğer TradingView API'si bizi reddederse hatayı görelim diye ekledim
        if response.status_code != 200:
            print(f"TradingView API Hatası: {response.text}")
            return []
            
        data = response.json()
        
        results = []
        for item in data.get('data', []):
            d = item['d']
            
            # --- GÜVENLİ DEĞİŞKEN ATAMASI (None Gelirse 0 Yapar) ---
            price    = d[1] or 0
            change   = d[2] or 0
            vol      = d[3] or 0
            rsi      = d[4] or 50
            rel_vol  = d[5] or 0
            avg_vol  = d[6] or 1
            sma50    = d[7] or 0
            sma200   = d[8] or 0
            bb_low   = d[9] or 0
            bb_up    = d[10] or 0
            ema20    = d[11] or 0
            open_p   = d[12] or 0
            
            # --- SENİN ESKİ ÇALIŞAN SİNYAL MANTIĞIN ---
            is_collecting = rel_vol > 2.0 and abs(change) < 1.5
            on_support = False
            if price and ema20:
                on_support = 1.0 < (price / ema20) < 1.02

            signal = ""
            if is_collecting:
                signal = "VIP: TAHTACI TOPLUYOR OLABİLİR"
            elif rel_vol > 3.0 and change > 2:
                signal = "AGRESİF ALIM (KURUMSAL)"
            elif rsi < 30:
                signal = "AŞIRI SATIM (TEPKİ BEKLENİR)"
            elif on_support:
                signal = "DESTEK BÖLGESİ (EMA20)"

            # --- FLUTTER'A VE MAIN.PY'A GİDECEK PAKET ---
            results.append({
                "symbol": item['s'].split(":")[1],
                "price": round(price, 2),
                "change": round(change, 2),
                "rsi": round(rsi, 2),
                "signal": signal,
                "rel_vol": round(rel_vol, 2),
                "full_name": d[13] if d[13] else "",
                
                # Main.py'daki filtreler için eklediklerimiz:
                "volume": vol,
                "avg_vol": avg_vol,
                "sma50": sma50,
                "sma200": sma200,
                "bb_low": bb_low,
                "bb_up": bb_up,
                "ema20": ema20,
                "open": open_p
            })
            
        print(f"Toplam {len(results)} hisse radara girdi.")
        return results

    except Exception as e:
        print(f"Hata: {e}")
        return []