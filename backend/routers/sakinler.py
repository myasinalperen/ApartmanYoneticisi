from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models, schemas

router = APIRouter(prefix="/sakinler", tags=["sakinler"])


@router.get("/", response_model=List[schemas.SakinOut])
def list_sakinler(db: Session = Depends(get_db)):
    return db.query(models.Sakin).order_by(models.Sakin.ad).all()


@router.post("/", response_model=schemas.SakinOut)
def create_sakin(sakin: schemas.SakinCreate, db: Session = Depends(get_db)):
    daire = db.query(models.Daire).filter(models.Daire.id == sakin.daire_id).first()
    if not daire:
        raise HTTPException(status_code=404, detail="Daire bulunamadı")
    db_sakin = models.Sakin(**sakin.model_dump())
    db.add(db_sakin)
    db.commit()
    db.refresh(db_sakin)
    return db_sakin


@router.get("/{sakin_id}", response_model=schemas.SakinOut)
def get_sakin(sakin_id: int, db: Session = Depends(get_db)):
    sakin = db.query(models.Sakin).filter(models.Sakin.id == sakin_id).first()
    if not sakin:
        raise HTTPException(status_code=404, detail="Sakin bulunamadı")
    return sakin


@router.put("/{sakin_id}", response_model=schemas.SakinOut)
def update_sakin(sakin_id: int, sakin_update: schemas.SakinUpdate, db: Session = Depends(get_db)):
    sakin = db.query(models.Sakin).filter(models.Sakin.id == sakin_id).first()
    if not sakin:
        raise HTTPException(status_code=404, detail="Sakin bulunamadı")
    for key, value in sakin_update.model_dump(exclude_none=True).items():
        setattr(sakin, key, value)
    db.commit()
    db.refresh(sakin)
    return sakin


@router.delete("/{sakin_id}")
def delete_sakin(sakin_id: int, db: Session = Depends(get_db)):
    sakin = db.query(models.Sakin).filter(models.Sakin.id == sakin_id).first()
    if not sakin:
        raise HTTPException(status_code=404, detail="Sakin bulunamadı")
    db.delete(sakin)
    db.commit()
    return {"ok": True}
