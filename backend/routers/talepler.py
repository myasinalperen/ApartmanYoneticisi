from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
from database import get_db
import models, schemas

router = APIRouter(prefix="/talepler", tags=["talepler"])


@router.get("/", response_model=List[schemas.TalepOut])
def list_talepler(durum: Optional[str] = None, db: Session = Depends(get_db)):
    q = db.query(models.Talep)
    if durum:
        q = q.filter(models.Talep.durum == durum)
    return q.order_by(models.Talep.created_at.desc()).all()


@router.post("/", response_model=schemas.TalepOut)
def create_talep(talep: schemas.TalepCreate, db: Session = Depends(get_db)):
    db_talep = models.Talep(**talep.model_dump())
    db.add(db_talep)
    db.commit()
    db.refresh(db_talep)
    return db_talep


@router.put("/{talep_id}", response_model=schemas.TalepOut)
def update_talep(talep_id: int, talep_update: schemas.TalepUpdate, db: Session = Depends(get_db)):
    talep = db.query(models.Talep).filter(models.Talep.id == talep_id).first()
    if not talep:
        raise HTTPException(status_code=404, detail="Talep bulunamadı")
    update_data = talep_update.model_dump(exclude_none=True)
    if update_data.get("durum") == "tamamlandi" and not talep.tamamlanma_tarihi:
        update_data["tamamlanma_tarihi"] = datetime.utcnow()
    for key, value in update_data.items():
        setattr(talep, key, value)
    db.commit()
    db.refresh(talep)
    return talep


@router.delete("/{talep_id}")
def delete_talep(talep_id: int, db: Session = Depends(get_db)):
    talep = db.query(models.Talep).filter(models.Talep.id == talep_id).first()
    if not talep:
        raise HTTPException(status_code=404, detail="Talep bulunamadı")
    db.delete(talep)
    db.commit()
    return {"ok": True}
