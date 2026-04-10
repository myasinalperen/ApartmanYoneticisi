import { useEffect, useState } from 'react';
import { getDuyurular, createDuyuru, updateDuyuru, deleteDuyuru } from '../services/api';
import { Duyuru } from '../types';
import { Plus, Megaphone, Pencil, Trash2 } from 'lucide-react';

const ONCELIKLER = [
  { value: 'normal', label: 'Normal', cls: 'badge-gray', border: 'border-gray-200' },
  { value: 'onemli', label: 'Önemli', cls: 'badge-blue', border: 'border-blue-200 bg-blue-50/30' },
  { value: 'acil', label: 'Acil', cls: 'badge-red', border: 'border-red-200 bg-red-50/30' },
];

const empty = { baslik: '', icerik: '', oncelik: 'normal' };

export default function Duyurular() {
  const [duyurular, setDuyurular] = useState<Duyuru[]>([]);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState<Duyuru | null>(null);
  const [form, setForm] = useState({ ...empty });

  const load = async () => {
    const res = await getDuyurular();
    setDuyurular(res.data);
  };

  useEffect(() => { load(); }, []);

  const openNew = () => { setEditing(null); setForm({ ...empty }); setModal(true); };
  const openEdit = (d: Duyuru) => {
    setEditing(d);
    setForm({ baslik: d.baslik, icerik: d.icerik, oncelik: d.oncelik });
    setModal(true);
  };

  const save = async () => {
    if (!form.baslik) return alert('Başlık zorunludur');
    if (editing) await updateDuyuru(editing.id, form);
    else await createDuyuru(form);
    setModal(false);
    load();
  };

  const remove = async (id: number) => {
    if (!confirm('Duyuruyu silmek istediğinize emin misiniz?')) return;
    await deleteDuyuru(id);
    load();
  };

  const oncelikInfo = (v: string) => ONCELIKLER.find(o => o.value === v) || ONCELIKLER[0];

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-2xl font-bold text-gray-900">Duyurular</h1>
        <button onClick={openNew} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Yeni Duyuru
        </button>
      </div>

      <div className="space-y-3">
        {duyurular.map(d => {
          const o = oncelikInfo(d.oncelik);
          return (
            <div key={d.id} className={`card border ${o.border} hover:shadow-md transition-shadow`}>
              <div className="flex items-start justify-between gap-4">
                <div className="flex items-start gap-3 flex-1">
                  <div className={`mt-0.5 w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0 ${d.oncelik === 'acil' ? 'bg-red-100' : d.oncelik === 'onemli' ? 'bg-blue-100' : 'bg-gray-100'}`}>
                    <Megaphone className={`w-4 h-4 ${d.oncelik === 'acil' ? 'text-red-500' : d.oncelik === 'onemli' ? 'text-blue-500' : 'text-gray-400'}`} />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h3 className="font-semibold text-gray-900">{d.baslik}</h3>
                      <span className={o.cls}>{o.label}</span>
                    </div>
                    {d.icerik && <p className="text-sm text-gray-600 mt-1.5 leading-relaxed">{d.icerik}</p>}
                    <p className="text-xs text-gray-400 mt-2">{new Date(d.created_at).toLocaleDateString('tr-TR', { year: 'numeric', month: 'long', day: 'numeric' })}</p>
                  </div>
                </div>
                <div className="flex gap-1 flex-shrink-0">
                  <button onClick={() => openEdit(d)} className="p-1.5 text-blue-500 hover:bg-blue-50 rounded"><Pencil className="w-4 h-4" /></button>
                  <button onClick={() => remove(d.id)} className="p-1.5 text-red-500 hover:bg-red-50 rounded"><Trash2 className="w-4 h-4" /></button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {duyurular.length === 0 && (
        <div className="card text-center py-12 text-gray-400">
          <Megaphone className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>Duyuru bulunamadı</p>
        </div>
      )}

      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b"><h2 className="font-bold text-gray-900">{editing ? 'Duyuru Düzenle' : 'Yeni Duyuru'}</h2></div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Başlık</label>
                <input className="input" value={form.baslik} onChange={e => setForm({ ...form, baslik: e.target.value })} />
              </div>
              <div>
                <label className="label">İçerik</label>
                <textarea className="input" rows={5} value={form.icerik} onChange={e => setForm({ ...form, icerik: e.target.value })} />
              </div>
              <div>
                <label className="label">Öncelik</label>
                <select className="input" value={form.oncelik} onChange={e => setForm({ ...form, oncelik: e.target.value })}>
                  {ONCELIKLER.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                </select>
              </div>
            </div>
            <div className="px-6 py-4 border-t flex justify-end gap-2">
              <button onClick={() => setModal(false)} className="btn-secondary">İptal</button>
              <button onClick={save} className="btn-primary">Yayınla</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
