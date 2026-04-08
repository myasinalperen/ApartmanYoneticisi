from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models, schemas

router = APIRouter(prefix="/duyurular", tags=["duyurular"])


@router.get("/", response_model=List[schemas.DuyuruOut])
def list_duyurular(db: Session = Depends(get_db)):
    return db.query(models.Duyuru).order_by(models.Duyuru.created_at.desc()).all()


@router.post("/", response_model=schemas.DuyuruOut)
def create_duyuru(duyuru: schemas.DuyuruCreate, db: Session = Depends(get_db)):
    db_duyuru = models.Duyuru(**duyuru.model_dump())
    db.add(db_duyuru)
    db.commit()
    db.refresh(db_duyuru)
    return db_duyuru


@router.put("/{duyuru_id}", response_model=schemas.DuyuruOut)
def update_duyuru(duyuru_id: int, duyuru_update: schemas.DuyuruUpdate, db: Session = Depends(get_db)):
    duyuru = db.query(models.Duyuru).filter(models.Duyuru.id == duyuru_id).first()
    if not duyuru:
        raise HTTPException(status_code=404, detail="Duyuru bulunamadı")
    for key, value in duyuru_update.model_dump(exclude_none=True).items():
        setattr(duyuru, key, value)
    db.commit()
    db.refresh(duyuru)
    return duyuru


@router.delete("/{duyuru_id}")
def delete_duyuru(duyuru_id: int, db: Session = Depends(get_db)):
    duyuru = db.query(models.Duyuru).filter(models.Duyuru.id == duyuru_id).first()
    if not duyuru:
        raise HTTPException(status_code=404, detail="Duyuru bulunamadı")
    db.delete(duyuru)
    db.commit()
    return {"ok": True}
