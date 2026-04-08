from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from database import get_db
import models, schemas

router = APIRouter(prefix="/faturalar", tags=["faturalar"])


@router.get("/", response_model=List[schemas.FaturaOut])
def list_faturalar(ay: Optional[int] = None, yil: Optional[int] = None, db: Session = Depends(get_db)):
    q = db.query(models.Fatura)
    if ay:
        q = q.filter(models.Fatura.ay == ay)
    if yil:
        q = q.filter(models.Fatura.yil == yil)
    return q.order_by(models.Fatura.yil.desc(), models.Fatura.ay.desc()).all()


@router.post("/", response_model=schemas.FaturaOut)
def create_fatura(fatura: schemas.FaturaCreate, db: Session = Depends(get_db)):
    db_fatura = models.Fatura(**fatura.model_dump())
    db.add(db_fatura)
    db.commit()
    db.refresh(db_fatura)
    return db_fatura


@router.put("/{fatura_id}", response_model=schemas.FaturaOut)
def update_fatura(fatura_id: int, fatura_update: schemas.FaturaUpdate, db: Session = Depends(get_db)):
    fatura = db.query(models.Fatura).filter(models.Fatura.id == fatura_id).first()
    if not fatura:
        raise HTTPException(status_code=404, detail="Fatura bulunamadı")
    for key, value in fatura_update.model_dump(exclude_none=True).items():
        setattr(fatura, key, value)
    db.commit()
    db.refresh(fatura)
    return fatura


@router.delete("/{fatura_id}")
def delete_fatura(fatura_id: int, db: Session = Depends(get_db)):
    fatura = db.query(models.Fatura).filter(models.Fatura.id == fatura_id).first()
    if not fatura:
        raise HTTPException(status_code=404, detail="Fatura bulunamadı")
    db.delete(fatura)
    db.commit()
    return {"ok": True}
