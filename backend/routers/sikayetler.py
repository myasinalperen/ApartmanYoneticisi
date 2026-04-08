from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models, schemas

router = APIRouter(prefix="/sikayetler", tags=["sikayetler"])


@router.get("/", response_model=List[schemas.SikayetOut])
def list_sikayetler(durum: Optional[str] = None, db: Session = Depends(get_db)):
    q = db.query(models.Sikayet)
    if durum:
        q = q.filter(models.Sikayet.durum == durum)
    return q.order_by(models.Sikayet.created_at.desc()).all()


@router.post("/", response_model=schemas.SikayetOut)
def create_sikayet(sikayet: schemas.SikayetCreate, db: Session = Depends(get_db)):
    db_sikayet = models.Sikayet(**sikayet.model_dump())
    db.add(db_sikayet)
    db.commit()
    db.refresh(db_sikayet)
    return db_sikayet


@router.put("/{sikayet_id}", response_model=schemas.SikayetOut)
def update_sikayet(sikayet_id: int, sikayet_update: schemas.SikayetUpdate, db: Session = Depends(get_db)):
    sikayet = db.query(models.Sikayet).filter(models.Sikayet.id == sikayet_id).first()
    if not sikayet:
        raise HTTPException(status_code=404, detail="Şikayet bulunamadı")
    for key, value in sikayet_update.model_dump(exclude_none=True).items():
        setattr(sikayet, key, value)
    db.commit()
    db.refresh(sikayet)
    return sikayet


@router.delete("/{sikayet_id}")
def delete_sikayet(sikayet_id: int, db: Session = Depends(get_db)):
    sikayet = db.query(models.Sikayet).filter(models.Sikayet.id == sikayet_id).first()
    if not sikayet:
        raise HTTPException(status_code=404, detail="Şikayet bulunamadı")
    db.delete(sikayet)
    db.commit()
    return {"ok": True}
