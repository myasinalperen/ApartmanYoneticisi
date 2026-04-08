from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models, schemas

router = APIRouter(prefix="/toplantilar", tags=["toplantilar"])


@router.get("/", response_model=List[schemas.ToplantiOut])
def list_toplantilar(db: Session = Depends(get_db)):
    return db.query(models.Toplanti).order_by(models.Toplanti.tarih.desc()).all()


@router.post("/", response_model=schemas.ToplantiOut)
def create_toplanti(toplanti: schemas.ToplantiCreate, db: Session = Depends(get_db)):
    db_toplanti = models.Toplanti(**toplanti.model_dump())
    db.add(db_toplanti)
    db.commit()
    db.refresh(db_toplanti)
    return db_toplanti


@router.put("/{toplanti_id}", response_model=schemas.ToplantiOut)
def update_toplanti(toplanti_id: int, toplanti_update: schemas.ToplantiUpdate, db: Session = Depends(get_db)):
    toplanti = db.query(models.Toplanti).filter(models.Toplanti.id == toplanti_id).first()
    if not toplanti:
        raise HTTPException(status_code=404, detail="Toplantı bulunamadı")
    for key, value in toplanti_update.model_dump(exclude_none=True).items():
        setattr(toplanti, key, value)
    db.commit()
    db.refresh(toplanti)
    return toplanti


@router.delete("/{toplanti_id}")
def delete_toplanti(toplanti_id: int, db: Session = Depends(get_db)):
    toplanti = db.query(models.Toplanti).filter(models.Toplanti.id == toplanti_id).first()
    if not toplanti:
        raise HTTPException(status_code=404, detail="Toplantı bulunamadı")
    db.delete(toplanti)
    db.commit()
    return {"ok": True}
