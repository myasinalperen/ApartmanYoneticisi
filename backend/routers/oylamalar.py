from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from database import get_db
import models, schemas

router = APIRouter(prefix="/oylamalar", tags=["oylamalar"])


@router.get("/", response_model=List[schemas.OylamaOut])
def list_oylamalar(db: Session = Depends(get_db)):
    oylamalar = db.query(models.Oylama).order_by(models.Oylama.created_at.desc()).all()
    result = []
    for oylama in oylamalar:
        secenekler_out = []
        for s in oylama.secenekler:
            oy_sayisi = db.query(models.Oy).filter(models.Oy.secenek_id == s.id).count()
            secenekler_out.append(schemas.OySecenekOut(id=s.id, metin=s.metin, oy_sayisi=oy_sayisi))
        toplam_oy = sum(s.oy_sayisi for s in secenekler_out)
        result.append(schemas.OylamaOut(
            id=oylama.id,
            baslik=oylama.baslik,
            aciklama=oylama.aciklama,
            baslangic=oylama.baslangic,
            bitis=oylama.bitis,
            durum=oylama.durum,
            created_at=oylama.created_at,
            secenekler=secenekler_out,
            toplam_oy=toplam_oy
        ))
    return result


@router.post("/", response_model=schemas.OylamaOut)
def create_oylama(oylama: schemas.OylamaCreate, db: Session = Depends(get_db)):
    db_oylama = models.Oylama(
        baslik=oylama.baslik,
        aciklama=oylama.aciklama,
        bitis=oylama.bitis,
        durum=oylama.durum
    )
    db.add(db_oylama)
    db.flush()
    secenekler_out = []
    for metin in oylama.secenekler:
        s = models.OySecenek(oylama_id=db_oylama.id, metin=metin)
        db.add(s)
        db.flush()
        secenekler_out.append(schemas.OySecenekOut(id=s.id, metin=s.metin, oy_sayisi=0))
    db.commit()
    db.refresh(db_oylama)
    return schemas.OylamaOut(
        id=db_oylama.id,
        baslik=db_oylama.baslik,
        aciklama=db_oylama.aciklama,
        baslangic=db_oylama.baslangic,
        bitis=db_oylama.bitis,
        durum=db_oylama.durum,
        created_at=db_oylama.created_at,
        secenekler=secenekler_out,
        toplam_oy=0
    )


@router.post("/oy-ver")
def oy_ver(oy: schemas.OyCreate, db: Session = Depends(get_db)):
    oylama = db.query(models.Oylama).filter(models.Oylama.id == oy.oylama_id).first()
    if not oylama:
        raise HTTPException(status_code=404, detail="Oylama bulunamadı")
    if oylama.durum != "aktif":
        raise HTTPException(status_code=400, detail="Bu oylama aktif değil")
    existing = db.query(models.Oy).filter(
        models.Oy.oylama_id == oy.oylama_id,
        models.Oy.daire_id == oy.daire_id
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="Bu daire zaten oy kullandı")
    db_oy = models.Oy(**oy.model_dump())
    db.add(db_oy)
    db.commit()
    return {"ok": True}


@router.put("/{oylama_id}", response_model=schemas.OylamaOut)
def update_oylama(oylama_id: int, oylama_update: schemas.OylamaUpdate, db: Session = Depends(get_db)):
    oylama = db.query(models.Oylama).filter(models.Oylama.id == oylama_id).first()
    if not oylama:
        raise HTTPException(status_code=404, detail="Oylama bulunamadı")
    for key, value in oylama_update.model_dump(exclude_none=True).items():
        setattr(oylama, key, value)
    db.commit()
    db.refresh(oylama)
    secenekler_out = []
    for s in oylama.secenekler:
        oy_sayisi = db.query(models.Oy).filter(models.Oy.secenek_id == s.id).count()
        secenekler_out.append(schemas.OySecenekOut(id=s.id, metin=s.metin, oy_sayisi=oy_sayisi))
    toplam_oy = sum(s.oy_sayisi for s in secenekler_out)
    return schemas.OylamaOut(
        id=oylama.id, baslik=oylama.baslik, aciklama=oylama.aciklama,
        baslangic=oylama.baslangic, bitis=oylama.bitis, durum=oylama.durum,
        created_at=oylama.created_at, secenekler=secenekler_out, toplam_oy=toplam_oy
    )


@router.delete("/{oylama_id}")
def delete_oylama(oylama_id: int, db: Session = Depends(get_db)):
    oylama = db.query(models.Oylama).filter(models.Oylama.id == oylama_id).first()
    if not oylama:
        raise HTTPException(status_code=404, detail="Oylama bulunamadı")
    db.delete(oylama)
    db.commit()
    return {"ok": True}
