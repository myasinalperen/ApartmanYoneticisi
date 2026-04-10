import { useEffect, useState } from 'react';
import { getTalepler, getDaireler, createTalep, updateTalep, deleteTalep } from '../services/api';
import { Talep, Daire } from '../types';
import { Plus, Wrench, Pencil, Trash2 } from 'lucide-react';

const KATEGORILER = [
  { value: 'teknik', label: 'Teknik' },
  { value: 'tadilat', label: 'Tadilat' },
  { value: 'temizlik', label: 'Temizlik' },
  { value: 'guvenlik', label: 'Güvenlik' },
  { value: 'diger', label: 'Diğer' },
];
const ONCELIKLER = [
  { value: 'dusuk', label: 'Düşük', cls: 'badge-gray' },
  { value: 'orta', label: 'Orta', cls: 'badge-blue' },
  { value: 'yuksek', label: 'Yüksek', cls: 'badge-yellow' },
  { value: 'acil', label: 'Acil', cls: 'badge-red' },
];
const DURUMLAR = [
  { value: 'beklemede', label: 'Beklemede', cls: 'badge-yellow' },
  { value: 'isleniyor', label: 'İşleniyor', cls: 'badge-blue' },
  { value: 'tamamlandi', label: 'Tamamlandı', cls: 'badge-green' },
  { value: 'iptal', label: 'İptal', cls: 'badge-gray' },
];

const empty = { daire_id: 0, baslik: '', aciklama: '', kategori: 'teknik', oncelik: 'orta', durum: 'beklemede' };

export default function Talepler() {
  const [talepler, setTalepler] = useState<Talep[]>([]);
  const [daireler, setDaireler] = useState<Daire[]>([]);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState<Talep | null>(null);
  const [form, setForm] = useState({ ...empty });
  const [filterDurum, setFilterDurum] = useState('');

  const load = async () => {
    const [t, d] = await Promise.all([getTalepler(filterDurum || undefined), getDaireler()]);
    setTalepler(t.data);
    setDaireler(d.data);
  };

  useEffect(() => { load(); }, [filterDurum]);

  const daireLabel = (id: number) => {
    const d = daireler.find(x => x.id === id);
    return d ? `${d.blok}${d.daire_no}` : '—';
  };

  const oncelikInfo = (v: string) => ONCELIKLER.find(o => o.value === v) || ONCELIKLER[1];
  const durumInfo = (v: string) => DURUMLAR.find(d => d.value === v) || DURUMLAR[0];

  const openNew = () => { setEditing(null); setForm({ ...empty, daire_id: daireler[0]?.id || 0 }); setModal(true); };
  const openEdit = (t: Talep) => {
    setEditing(t);
    setForm({ daire_id: t.daire_id, baslik: t.baslik, aciklama: t.aciklama, kategori: t.kategori, oncelik: t.oncelik, durum: t.durum });
    setModal(true);
  };

  const save = async () => {
    if (!form.baslik || !form.daire_id) return alert('Başlık ve daire zorunludur');
    if (editing) await updateTalep(editing.id, form);
    else await createTalep(form);
    setModal(false);
    load();
  };

  const remove = async (id: number) => {
    if (!confirm('Talebi silmek istediğinize emin misiniz?')) return;
    await deleteTalep(id);
    load();
  };

  const hızliDurumGuncelle = async (id: number, durum: string) => {
    await updateTalep(id, { durum });
    load();
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-2xl font-bold text-gray-900">Bakım & Talepler</h1>
        <button onClick={openNew} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Yeni Talep
        </button>
      </div>

      <div className="flex gap-2 flex-wrap">
        <button onClick={() => setFilterDurum('')} className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${!filterDurum ? 'bg-gray-900 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
          Tümü ({talepler.length})
        </button>
        {DURUMLAR.map(d => (
          <button key={d.value} onClick={() => setFilterDurum(d.value)}
            className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${filterDurum === d.value ? 'bg-gray-900 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
            {d.label}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {talepler.map(t => {
          const o = oncelikInfo(t.oncelik);
          const d = durumInfo(t.durum);
          return (
            <div key={t.id} className={`card hover:shadow-md transition-shadow ${t.oncelik === 'acil' ? 'border-red-200 bg-red-50/30' : ''}`}>
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-3 flex-1 min-w-0">
                  <div className={`mt-1 w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0 ${t.oncelik === 'acil' ? 'bg-red-100' : 'bg-blue-50'}`}>
                    <Wrench className={`w-4 h-4 ${t.oncelik === 'acil' ? 'text-red-600' : 'text-blue-500'}`} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="font-semibold text-gray-900">{t.baslik}</h3>
                      <span className={o.cls}>{o.label}</span>
                      <span className={d.cls}>{d.label}</span>
                    </div>
                    <p className="text-sm text-gray-500 mt-0.5">Daire {daireLabel(t.daire_id)} · {KATEGORILER.find(k => k.value === t.kategori)?.label}</p>
                    {t.aciklama && <p className="text-sm text-gray-600 mt-1">{t.aciklama}</p>}
                    <p className="text-xs text-gray-400 mt-1">{new Date(t.created_at).toLocaleDateString('tr-TR')}</p>
                  </div>
                </div>
                <div className="flex gap-1 flex-shrink-0">
                  <button onClick={() => openEdit(t)} className="p-1.5 text-blue-500 hover:bg-blue-50 rounded">
                    <Pencil className="w-4 h-4" />
                  </button>
                  <button onClick={() => remove(t.id)} className="p-1.5 text-red-500 hover:bg-red-50 rounded">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Hızlı Durum Güncelle */}
              {t.durum !== 'tamamlandi' && t.durum !== 'iptal' && (
                <div className="flex gap-2 mt-3 pt-3 border-t border-gray-100">
                  {t.durum === 'beklemede' && (
                    <button onClick={() => hızliDurumGuncelle(t.id, 'isleniyor')}
                      className="text-xs font-medium text-blue-600 hover:text-blue-800 px-2 py-1 hover:bg-blue-50 rounded">
                      → İşleme Al
                    </button>
                  )}
                  <button onClick={() => hızliDurumGuncelle(t.id, 'tamamlandi')}
                    className="text-xs font-medium text-green-600 hover:text-green-800 px-2 py-1 hover:bg-green-50 rounded">
                    ✓ Tamamlandı
                  </button>
                  <button onClick={() => hızliDurumGuncelle(t.id, 'iptal')}
                    className="text-xs font-medium text-gray-500 hover:text-gray-700 px-2 py-1 hover:bg-gray-100 rounded">
                    ✕ İptal
                  </button>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {talepler.length === 0 && (
        <div className="card text-center py-12 text-gray-400">
          <Wrench className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>Talep bulunamadı</p>
        </div>
      )}

      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b"><h2 className="font-bold text-gray-900">{editing ? 'Talep Düzenle' : 'Yeni Talep'}</h2></div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Daire</label>
                <select className="input" value={form.daire_id} onChange={e => setForm({ ...form, daire_id: +e.target.value })}>
                  <option value={0}>Seçiniz</option>
                  {daireler.map(d => <option key={d.id} value={d.id}>{d.blok}{d.daire_no} - Kat {d.kat}</option>)}
                </select>
              </div>
              <div>
                <label className="label">Başlık</label>
                <input className="input" value={form.baslik} onChange={e => setForm({ ...form, baslik: e.target.value })} />
              </div>
              <div>
                <label className="label">Açıklama</label>
                <textarea className="input" rows={3} value={form.aciklama} onChange={e => setForm({ ...form, aciklama: e.target.value })} />
              </div>
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label className="label">Kategori</label>
                  <select className="input" value={form.kategori} onChange={e => setForm({ ...form, kategori: e.target.value })}>
                    {KATEGORILER.map(k => <option key={k.value} value={k.value}>{k.label}</option>)}
                  </select>
                </div>
                <div>
                  <label className="label">Öncelik</label>
                  <select className="input" value={form.oncelik} onChange={e => setForm({ ...form, oncelik: e.target.value })}>
                    {ONCELIKLER.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                  </select>
                </div>
                <div>
                  <label className="label">Durum</label>
                  <select className="input" value={form.durum} onChange={e => setForm({ ...form, durum: e.target.value })}>
                    {DURUMLAR.map(d => <option key={d.value} value={d.value}>{d.label}</option>)}
                  </select>
                </div>
              </div>
            </div>
            <div className="px-6 py-4 border-t flex justify-end gap-2">
              <button onClick={() => setModal(false)} className="btn-secondary">İptal</button>
              <button onClick={save} className="btn-primary">Kaydet</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
