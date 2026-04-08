from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models, schemas

router = APIRouter(prefix="/aidatlar", tags=["aidatlar"])


@router.get("/", response_model=List[schemas.AidatOut])
def list_aidatlar(ay: Optional[int] = None, yil: Optional[int] = None, db: Session = Depends(get_db)):
    q = db.query(models.Aidat)
    if ay:
        q = q.filter(models.Aidat.ay == ay)
    if yil:
        q = q.filter(models.Aidat.yil == yil)
    return q.order_by(models.Aidat.yil.desc(), models.Aidat.ay.desc()).all()


@router.post("/", response_model=schemas.AidatOut)
def create_aidat(aidat: schemas.AidatCreate, db: Session = Depends(get_db)):
    existing = db.query(models.Aidat).filter(
        models.Aidat.daire_id == aidat.daire_id,
        models.Aidat.ay == aidat.ay,
        models.Aidat.yil == aidat.yil
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Bu daire için bu ay/yıl aidatı zaten mevcut")
    db_aidat = models.Aidat(**aidat.model_dump())
    db.add(db_aidat)
    db.commit()
    db.refresh(db_aidat)
    return db_aidat


@router.post("/toplu-olustur")
def toplu_olustur(yil: int, ay: int, tutar: float, db: Session = Depends(get_db)):
    daireler = db.query(models.Daire).filter(models.Daire.durum == "dolu").all()
    olusturulan = 0
    for daire in daireler:
        existing = db.query(models.Aidat).filter(
            models.Aidat.daire_id == daire.id,
            models.Aidat.ay == ay,
            models.Aidat.yil == yil
        ).first()
        if not existing:
            db_aidat = models.Aidat(daire_id=daire.id, ay=ay, yil=yil, tutar=tutar)
            db.add(db_aidat)
            olusturulan += 1
    db.commit()
    return {"olusturulan": olusturulan}


@router.put("/{aidat_id}", response_model=schemas.AidatOut)
def update_aidat(aidat_id: int, aidat_update: schemas.AidatUpdate, db: Session = Depends(get_db)):
    aidat = db.query(models.Aidat).filter(models.Aidat.id == aidat_id).first()
    if not aidat:
        raise HTTPException(status_code=404, detail="Aidat bulunamadı")
    for key, value in aidat_update.model_dump(exclude_none=True).items():
        setattr(aidat, key, value)
    db.commit()
    db.refresh(aidat)
    return aidat


@router.delete("/{aidat_id}")
def delete_aidat(aidat_id: int, db: Session = Depends(get_db)):
    aidat = db.query(models.Aidat).filter(models.Aidat.id == aidat_id).first()
    if not aidat:
        raise HTTPException(status_code=404, detail="Aidat bulunamadı")
    db.delete(aidat)
    db.commit()
    return {"ok": True}
