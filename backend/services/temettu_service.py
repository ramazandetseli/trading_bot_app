from curl_cffi import requests
from bs4 import BeautifulSoup
import re

def parse_float(val: str):
    if not val:
        return 0.0
    temiz = re.sub(r"[^\d,\.]", "", val).replace(".", "").replace(",", ".")
    try:
        return float(temiz)
    except ValueError:
        return 0.0

def fetch_temettu_takvimi():
    url = "https://yatirimci.ai/temettu"
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7",
    }

    response = requests.get(url, headers=headers, impersonate="chrome", timeout=15)
    
    if response.status_code != 200:
        raise Exception(f"Yatirimci.ai yanıt vermedi: {response.status_code}")

    soup = BeautifulSoup(response.text, "html.parser")
    tablolar = soup.find_all("table")
    
    if not tablolar:
        return []

    tablo = tablolar[0]
    satirlar = tablo.find_all("tr")[1:]
    
    temettuler = []
    for tr in satirlar:
        tds = tr.find_all("td")
        if len(tds) >= 6:
            # Sitede kod link içinde veya metin olarak yer alır: örn 'LILIDERLDR Turizm'
            hisse_td = tds[0]
            link = hisse_td.find("a")
            
            # Eğer <a> etiketi varsa href='/hisse/TUPRS' gibi gelir
            sembol = ""
            if link and link.get("href"):
                sembol = link.get("href").strip("/").split("/")[-1].upper()
            
            # Link yoksa regex ile temizle (Örn: LILIDER -> LIDER)
            raw_text = hisse_td.text.strip()
            if not sembol:
                # Başta tekrarlanan ilk 2 harfi atla
                m = re.match(r"^[A-Z]{2}([A-Z0-9]{4,5})", raw_text)
                sembol = m.group(1) if m else raw_text[:5]

            # Şirket unvanını temizle
            unvan = raw_text.replace(sembol, "").strip()
            if unvan.startswith(sembol[:2]):
                unvan = unvan[2:].strip()
            if not unvan:
                unvan = sembol

            tarih = tds[1].text.strip()
            pay_basina_brut = tds[2].text.strip()
            brut_oran = tds[3].text.strip()
            verim = tds[4].text.strip()
            son_fiyat = tds[5].text.strip()

            temettuler.append({
                "sembol": sembol,
                "unvan": unvan,
                "tarih": tarih,
                "pay_basina_brut": pay_basina_brut,
                "pay_basina_brut_sayisal": parse_float(pay_basina_brut),
                "brut_oran": brut_oran,
                "verim": verim,
                "verim_sayisal": parse_float(verim),
                "son_fiyat": son_fiyat
            })

    return temettuler