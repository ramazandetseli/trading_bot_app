from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
import veriTabani

router = APIRouter()

# veriTabani.py içindeki supabase istemcisini bağlıyoruz
supabase = veriTabani.supabase

# --- Modeller ---
class FavoriIstek(BaseModel):
    user_id: str
    symbol: str

class AlarmIstek(BaseModel):
    user_id: str
    symbol: str
    target_price: float
    current_price: float

class AlarmSilIstek(BaseModel):
    user_id: str
    symbol: str
    
class AlarmDuzenleIstek(BaseModel):
    user_id: str
    symbol: str
    target_price: float

class PortfolioEkleRequest(BaseModel):
    user_id: str
    symbol: str
    lot_quantity: float
    buy_price: float

class PortfolioSilRequest(BaseModel):
    portfolio_id: str
    user_id: str

# --- Favori İşlemleri ---
@router.post("/favori-ekle")
def favori_ekle(istek: FavoriIstek):
    return veriTabani.favoriYonetici.ekle(user_id=istek.user_id, symbol=istek.symbol)

@router.post("/favori-sil")
def favori_sil(istek: FavoriIstek):
    return veriTabani.favoriYonetici.sil(user_id=istek.user_id, symbol=istek.symbol)

@router.get("/favoriler/{user_id}")
def favorileri_listele(user_id: str):
    return veriTabani.favoriYonetici.listele(user_id=user_id)

# --- Alarm İşlemleri ---
@router.post("/alarm-kur")
def alarm_kur(istek: AlarmIstek):
    return veriTabani.alarmYonetici.ekle(
        user_id=istek.user_id, 
        symbol=istek.symbol, 
        target_price=istek.target_price,
        current_price=istek.current_price
    )

@router.get("/alarmlar/{user_id}")
def alarmlari_listele(user_id: str):
    return veriTabani.alarmYonetici.listele(user_id=user_id)

@router.post("/alarm-sil")
def alarm_sil(istek: AlarmSilIstek):
    return veriTabani.alarmYonetici.sil(user_id=istek.user_id, symbol=istek.symbol)

@router.post("/alarm-duzenle")
def alarm_duzenle(istek: AlarmDuzenleIstek):
    return veriTabani.alarmYonetici.duzenle(
        user_id=istek.user_id, 
        symbol=istek.symbol, 
        target_price=istek.target_price
    )

# --- Portfolio İşlemleri ---
@router.get("/portfolio/{user_id}")
async def get_portfolio(user_id: str):
    try:
        res = supabase.table("portfolio").select("*").eq("user_id", user_id).order("created_at", desc=True).execute()
        return {"status": "success", "data": res.data or []}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/portfolio-ekle")
async def add_to_portfolio(req: PortfolioEkleRequest):
    sym = req.symbol.strip().upper()

    # Kriptolar (BTCUSDT: 7, AVAXUSDT: 8) ve ABD hisseleri (BRK.B) için esnek kontrol:
    import re
    if not (2 <= len(sym) <= 12 and re.match(r'^[A-Z0-9.-]+$', sym)):
        raise HTTPException(
            status_code=400, 
            detail="Geçersiz sembol formatı. Sembol 2-12 karakterli olmalıdır."
        )

    try:
        # 1. Kullanıcının bu varlıkta mevcut bir kaydı var mı kontrol et
        mevcut = supabase.table("portfolio") \
            .select("*") \
            .eq("user_id", req.user_id) \
            .eq("symbol", sym) \
            .execute()

        if mevcut.data and len(mevcut.data) > 0:
            eski = mevcut.data[0]
            eski_lot = float(eski["lot_quantity"])
            eski_maliyet = float(eski["buy_price"])

            yeni_toplam_lot = eski_lot + req.lot_quantity
            yeni_ortalama_maliyet = (
                (eski_lot * eski_maliyet) + (req.lot_quantity * req.buy_price)
            ) / yeni_toplam_lot

            res = supabase.table("portfolio").update({
                "lot_quantity": yeni_toplam_lot,
                "buy_price": round(yeni_ortalama_maliyet, 4)
            }).eq("id", eski["id"]).execute()
        else:
            veri = {
                "user_id": req.user_id,
                "symbol": sym,
                "lot_quantity": req.lot_quantity,
                "buy_price": req.buy_price
            }
            res = supabase.table("portfolio").insert(veri).execute()

        return {"status": "success", "data": res.data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
        
@router.post("/portfolio-sil")
async def delete_from_portfolio(req: PortfolioSilRequest):
    try:
        res = supabase.table("portfolio").delete().eq("id", req.portfolio_id).eq("user_id", req.user_id).execute()
        return {"status": "success", "message": "Varlık silindi"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))