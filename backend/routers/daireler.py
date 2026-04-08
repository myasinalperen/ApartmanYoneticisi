from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models, schemas

router = APIRouter(prefix="/daireler", tags=["daireler"])


@router.get("/", response_model=List[schemas.DaireOut])
def list_daireler(db: Session = Depends(get_db)):
    return db.query(models.Daire).order_by(models.Daire.blok, models.Daire.kat, models.Daire.daire_no).all()


@router.post("/", response_model=schemas.DaireOut)
def create_daire(daire: schemas.DaireCreate, db: Session = Depends(get_db)):
    db_daire = models.Daire(**daire.model_dump())
    db.add(db_daire)
    db.commit()
    db.refresh(db_daire)
    return db_daire


@router.get("/{daire_id}", response_model=schemas.DaireOut)
def get_daire(daire_id: int, db: Session = Depends(get_db)):
    daire = db.query(models.Daire).filter(models.Daire.id == daire_id).first()
    if not daire:
        raise HTTPException(status_code=404, detail="Daire bulunamadı")
    return daire


@router.put("/{daire_id}", response_model=schemas.DaireOut)
def update_daire(daire_id: int, daire_update: schemas.DaireUpdate, db: Session = Depends(get_db)):
    daire = db.query(models.Daire).filter(models.Daire.id == daire_id).first()
    if not daire:
        raise HTTPException(status_code=404, detail="Daire bulunamadı")
    for key, value in daire_update.model_dump(exclude_none=True).items():
        setattr(daire, key, value)
    db.commit()
    db.refresh(daire)
    return daire


@router.delete("/{daire_id}")
def delete_daire(daire_id: int, db: Session = Depends(get_db)):
    daire = db.query(models.Daire).filter(models.Daire.id == daire_id).first()
    if not daire:
        raise HTTPException(status_code=404, detail="Daire bulunamadı")
    db.delete(daire)
    db.commit()
    return {"ok": True}
