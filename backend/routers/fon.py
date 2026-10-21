from fastapi import APIRouter, Query
from services.fon_servisi import (
    fetch_tum_fonlar,
    fetch_fon_detay,
    fetch_fon_kiyaslama,
    fetch_fon_tipi,
    fetch_one_cikanlar,
    fetch_fvt_portfoy,
    fetch_fon_tahmini,
    fetch_fon_vitrini
)

router = APIRouter()

@router.get("/tum-fonlar")
def get_tum_fonlar(fon_tip: str = None):
    return fetch_tum_fonlar(fon_tip)

@router.get("/detay/{fon_kodu}")
def get_fon_detay(fon_kodu: str, aralik: str = Query(default="3ay")):
    return fetch_fon_detay(fon_kodu, aralik)

@router.get("/profil/{fon_kodu}")
def get_fon_profil(fon_kodu: str, periyod: str = "12"):
    return fetch_fon_kiyaslama(fon_kodu, periyod)

@router.get("/tip/{fon_kodu}")
def get_fon_tipi(fon_kodu: str):
    return fetch_fon_tipi(fon_kodu)

@router.get("/kiyaslama/{fon_kodu}")
def get_fon_kiyaslama(fon_kodu: str, periyod: str = "12"):
    return fetch_fon_kiyaslama(fon_kodu, periyod)

@router.get("/one-cikanlar")
def get_one_cikan_fonlar():
    return fetch_one_cikanlar()

@router.get("/portfoy/{fon_kodu}")
def get_fon_portfoy(fon_kodu: str):
    return fetch_fvt_portfoy(fon_kodu)

@router.get("/tahmin/{fon_kodu}")
def get_fon_tahmini(fon_kodu: str):
    return fetch_fon_tahmini(fon_kodu)

# Sadece servisi tetikliyor.
@router.get("/vitrin")
def fon_vitrini_getir():
    return fetch_fon_vitrini()