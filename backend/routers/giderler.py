from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models, schemas

router = APIRouter(prefix="/giderler", tags=["giderler"])


@router.get("/", response_model=List[schemas.GiderOut])
def list_giderler(db: Session = Depends(get_db)):
    return db.query(models.Gider).order_by(models.Gider.tarih.desc()).all()


@router.post("/", response_model=schemas.GiderOut)
def create_gider(gider: schemas.GiderCreate, db: Session = Depends(get_db)):
    db_gider = models.Gider(**gider.model_dump())
    db.add(db_gider)
    db.commit()
    db.refresh(db_gider)
    return db_gider


@router.put("/{gider_id}", response_model=schemas.GiderOut)
def update_gider(gider_id: int, gider_update: schemas.GiderUpdate, db: Session = Depends(get_db)):
    gider = db.query(models.Gider).filter(models.Gider.id == gider_id).first()
    if not gider:
        raise HTTPException(status_code=404, detail="Gider bulunamadı")
    for key, value in gider_update.model_dump(exclude_none=True).items():
        setattr(gider, key, value)
    db.commit()
    db.refresh(gider)
    return gider


@router.delete("/{gider_id}")
def delete_gider(gider_id: int, db: Session = Depends(get_db)):
    gider = db.query(models.Gider).filter(models.Gider.id == gider_id).first()
    if not gider:
        raise HTTPException(status_code=404, detail="Gider bulunamadı")
    db.delete(gider)
    db.commit()
    return {"ok": True}
