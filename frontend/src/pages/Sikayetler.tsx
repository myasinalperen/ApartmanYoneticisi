import { useEffect, useState } from 'react';
import { getSikayetler, getDaireler, createSikayet, updateSikayet, deleteSikayet } from '../services/api';
import { Sikayet, Daire } from '../types';
import { Plus, MessageSquareWarning, Pencil, Trash2 } from 'lucide-react';

const KATEGORILER = [
  { value: 'gurultu', label: 'Gürültü' },
  { value: 'temizlik', label: 'Temizlik' },
  { value: 'park', label: 'Park' },
  { value: 'evcil_hayvan', label: 'Evcil Hayvan' },
  { value: 'diger', label: 'Diğer' },
];
const DURUMLAR = [
  { value: 'acik', label: 'Açık', cls: 'badge-red' },
  { value: 'inceleniyor', label: 'İnceleniyor', cls: 'badge-yellow' },
  { value: 'cozuldu', label: 'Çözüldü', cls: 'badge-green' },
  { value: 'kapandi', label: 'Kapandı', cls: 'badge-gray' },
];

const empty = { sikayet_eden_daire_id: 0, sikayet_edilen_daire_id: 0, baslik: '', aciklama: '', kategori: 'diger', durum: 'acik' };

export default function Sikayetler() {
  const [sikayetler, setSikayetler] = useState<Sikayet[]>([]);
  const [daireler, setDaireler] = useState<Daire[]>([]);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState<Sikayet | null>(null);
  const [form, setForm] = useState({ ...empty });
  const [filterDurum, setFilterDurum] = useState('');

  const load = async () => {
    const [s, d] = await Promise.all([getSikayetler(filterDurum || undefined), getDaireler()]);
    setSikayetler(s.data);
    setDaireler(d.data);
  };

  useEffect(() => { load(); }, [filterDurum]);

  const daireLabel = (id: number | null) => {
    if (!id) return 'Genel';
    const d = daireler.find(x => x.id === id);
    return d ? `Daire ${d.blok}${d.daire_no}` : '—';
  };

  const durumInfo = (v: string) => DURUMLAR.find(d => d.value === v) || DURUMLAR[0];

  const openNew = () => {
    setEditing(null);
    setForm({ ...empty, sikayet_eden_daire_id: daireler[0]?.id || 0 });
    setModal(true);
  };

  const openEdit = (s: Sikayet) => {
    setEditing(s);
    setForm({
      sikayet_eden_daire_id: s.sikayet_eden_daire_id,
      sikayet_edilen_daire_id: s.sikayet_edilen_daire_id || 0,
      baslik: s.baslik, aciklama: s.aciklama, kategori: s.kategori, durum: s.durum
    });
    setModal(true);
  };

  const save = async () => {
    if (!form.baslik || !form.sikayet_eden_daire_id) return alert('Başlık ve şikayet eden daire zorunludur');
    const payload = { ...form, sikayet_edilen_daire_id: form.sikayet_edilen_daire_id || null };
    if (editing) await updateSikayet(editing.id, payload);
    else await createSikayet(payload);
    setModal(false);
    load();
  };

  const hızliDurum = async (id: number, durum: string) => {
    await updateSikayet(id, { durum });
    load();
  };

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-2xl font-bold text-gray-900">Şikayetler</h1>
        <button onClick={openNew} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Yeni Şikayet
        </button>
      </div>

      <div className="flex gap-2 flex-wrap">
        <button onClick={() => setFilterDurum('')}
          className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${!filterDurum ? 'bg-gray-900 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
          Tümü
        </button>
        {DURUMLAR.map(d => (
          <button key={d.value} onClick={() => setFilterDurum(d.value)}
            className={`px-3 py-1.5 rounded-full text-xs font-medium transition-colors ${filterDurum === d.value ? 'bg-gray-900 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200'}`}>
            {d.label}
          </button>
        ))}
      </div>

      <div className="space-y-3">
        {sikayetler.map(s => {
          const d = durumInfo(s.durum);
          const kat = KATEGORILER.find(k => k.value === s.kategori)?.label || s.kategori;
          return (
            <div key={s.id} className="card hover:shadow-md transition-shadow">
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-3 flex-1">
                  <div className="mt-1 w-9 h-9 rounded-lg bg-orange-50 flex items-center justify-center flex-shrink-0">
                    <MessageSquareWarning className="w-4 h-4 text-orange-500" />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="font-semibold text-gray-900">{s.baslik}</h3>
                      <span className={d.cls}>{d.label}</span>
                      <span className="badge-orange">{kat}</span>
                    </div>
                    <div className="flex items-center gap-2 mt-1 text-sm text-gray-500 flex-wrap">
                      <span>{daireLabel(s.sikayet_eden_daire_id)} → {daireLabel(s.sikayet_edilen_daire_id)}</span>
                    </div>
                    {s.aciklama && <p className="text-sm text-gray-600 mt-1">{s.aciklama}</p>}
                    <p className="text-xs text-gray-400 mt-1">{new Date(s.created_at).toLocaleDateString('tr-TR')}</p>
                  </div>
                </div>
                <div className="flex gap-1 flex-shrink-0">
                  <button onClick={() => openEdit(s)} className="p-1.5 text-blue-500 hover:bg-blue-50 rounded"><Pencil className="w-4 h-4" /></button>
                  <button onClick={async () => { if (confirm('Silmek istiyor musunuz?')) { await deleteSikayet(s.id); load(); } }} className="p-1.5 text-red-500 hover:bg-red-50 rounded"><Trash2 className="w-4 h-4" /></button>
                </div>
              </div>

              {s.durum !== 'cozuldu' && s.durum !== 'kapandi' && (
                <div className="flex gap-2 mt-3 pt-3 border-t border-gray-100">
                  {s.durum === 'acik' && (
                    <button onClick={() => hızliDurum(s.id, 'inceleniyor')} className="text-xs font-medium text-yellow-600 hover:text-yellow-800 px-2 py-1 hover:bg-yellow-50 rounded">
                      → İncelemeye Al
                    </button>
                  )}
                  <button onClick={() => hızliDurum(s.id, 'cozuldu')} className="text-xs font-medium text-green-600 hover:text-green-800 px-2 py-1 hover:bg-green-50 rounded">
                    ✓ Çözüldü
                  </button>
                  <button onClick={() => hızliDurum(s.id, 'kapandi')} className="text-xs font-medium text-gray-500 hover:text-gray-700 px-2 py-1 hover:bg-gray-100 rounded">
                    ✕ Kapat
                  </button>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {sikayetler.length === 0 && (
        <div className="card text-center py-12 text-gray-400">
          <MessageSquareWarning className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>Şikayet bulunamadı</p>
        </div>
      )}

      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b"><h2 className="font-bold text-gray-900">{editing ? 'Şikayet Düzenle' : 'Yeni Şikayet'}</h2></div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Şikayet Eden Daire</label>
                <select className="input" value={form.sikayet_eden_daire_id} onChange={e => setForm({ ...form, sikayet_eden_daire_id: +e.target.value })}>
                  <option value={0}>Seçiniz</option>
                  {daireler.map(d => <option key={d.id} value={d.id}>{d.blok}{d.daire_no} - Kat {d.kat}</option>)}
                </select>
              </div>
              <div>
                <label className="label">Şikayet Edilen Daire (isteğe bağlı)</label>
                <select className="input" value={form.sikayet_edilen_daire_id} onChange={e => setForm({ ...form, sikayet_edilen_daire_id: +e.target.value })}>
                  <option value={0}>Genel / Belirtilmemiş</option>
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
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Kategori</label>
                  <select className="input" value={form.kategori} onChange={e => setForm({ ...form, kategori: e.target.value })}>
                    {KATEGORILER.map(k => <option key={k.value} value={k.value}>{k.label}</option>)}
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
