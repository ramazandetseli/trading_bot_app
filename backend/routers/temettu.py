from fastapi import APIRouter, HTTPException
from services.temettu_service import fetch_temettu_takvimi

router = APIRouter(prefix="/temettu", tags=["Temettü Takvimi"])

@router.get("/takvim")
async def get_temettu_takvimi():
    try:
        veriler = fetch_temettu_takvimi()
        return {
            "durum": "basarili",
            "toplam_kayit": len(veriler),
            "data": veriler
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))