import { useEffect, useState } from 'react';
import { getToplantilar, createToplanti, updateToplanti, deleteToplanti } from '../services/api';
import { Toplanti } from '../types';
import { Plus, CalendarDays, Pencil, Trash2, MapPin, FileText } from 'lucide-react';

const DURUMLAR = [
  { value: 'planlandı', label: 'Planlandı', cls: 'badge-blue' },
  { value: 'tamamlandı', label: 'Tamamlandı', cls: 'badge-green' },
  { value: 'iptal', label: 'İptal', cls: 'badge-gray' },
];

const now = new Date();
const empty = {
  baslik: '', tarih: now.toISOString().slice(0, 16),
  yer: 'Apartman Toplantı Salonu', ajanda: '', notlar: '', durum: 'planlandı'
};

export default function Toplantilar() {
  const [toplantilar, setToplantilar] = useState<Toplanti[]>([]);
  const [modal, setModal] = useState(false);
  const [notModal, setNotModal] = useState<Toplanti | null>(null);
  const [editing, setEditing] = useState<Toplanti | null>(null);
  const [form, setForm] = useState({ ...empty });
  const [notlar, setNotlar] = useState('');

  const load = async () => {
    const res = await getToplantilar();
    setToplantilar(res.data);
  };

  useEffect(() => { load(); }, []);

  const openNew = () => { setEditing(null); setForm({ ...empty }); setModal(true); };
  const openEdit = (t: Toplanti) => {
    setEditing(t);
    setForm({
      baslik: t.baslik,
      tarih: new Date(t.tarih).toISOString().slice(0, 16),
      yer: t.yer, ajanda: t.ajanda, notlar: t.notlar, durum: t.durum
    });
    setModal(true);
  };

  const save = async () => {
    if (!form.baslik) return alert('Başlık zorunludur');
    if (editing) await updateToplanti(editing.id, form);
    else await createToplanti(form);
    setModal(false);
    load();
  };

  const kaydetNotlar = async () => {
    if (!notModal) return;
    await updateToplanti(notModal.id, { notlar, durum: 'tamamlandı' });
    setNotModal(null);
    load();
  };

  const durumInfo = (v: string) => DURUMLAR.find(d => d.value === v) || DURUMLAR[0];

  const gelecek = toplantilar.filter(t => new Date(t.tarih) >= now && t.durum === 'planlandı');
  const gecmis = toplantilar.filter(t => t.durum !== 'planlandı' || new Date(t.tarih) < now);

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-2xl font-bold text-gray-900">Toplantılar</h1>
        <button onClick={openNew} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Yeni Toplantı
        </button>
      </div>

      {gelecek.length > 0 && (
        <div>
          <h2 className="text-sm font-semibold text-gray-500 mb-3 uppercase tracking-wide">Yaklaşan Toplantılar</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {gelecek.map(t => (
              <ToplantiKart key={t.id} t={t} durumInfo={durumInfo} openEdit={openEdit}
                onDelete={async () => { if (confirm('Silinsin mi?')) { await deleteToplanti(t.id); load(); } }}
                onNot={() => { setNotModal(t); setNotlar(t.notlar); }} />
            ))}
          </div>
        </div>
      )}

      {gecmis.length > 0 && (
        <div>
          <h2 className="text-sm font-semibold text-gray-500 mb-3 uppercase tracking-wide">Geçmiş Toplantılar</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {gecmis.map(t => (
              <ToplantiKart key={t.id} t={t} durumInfo={durumInfo} openEdit={openEdit}
                onDelete={async () => { if (confirm('Silinsin mi?')) { await deleteToplanti(t.id); load(); } }}
                onNot={() => { setNotModal(t); setNotlar(t.notlar); }} />
            ))}
          </div>
        </div>
      )}

      {toplantilar.length === 0 && (
        <div className="card text-center py-12 text-gray-400">
          <CalendarDays className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>Toplantı bulunamadı</p>
        </div>
      )}

      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            <div className="px-6 py-4 border-b sticky top-0 bg-white"><h2 className="font-bold text-gray-900">{editing ? 'Toplantı Düzenle' : 'Yeni Toplantı'}</h2></div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Başlık</label>
                <input className="input" value={form.baslik} onChange={e => setForm({ ...form, baslik: e.target.value })} />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Tarih & Saat</label>
                  <input className="input" type="datetime-local" value={form.tarih} onChange={e => setForm({ ...form, tarih: e.target.value })} />
                </div>
                <div>
                  <label className="label">Durum</label>
                  <select className="input" value={form.durum} onChange={e => setForm({ ...form, durum: e.target.value })}>
                    {DURUMLAR.map(d => <option key={d.value} value={d.value}>{d.label}</option>)}
                  </select>
                </div>
              </div>
              <div>
                <label className="label">Yer</label>
                <input className="input" value={form.yer} onChange={e => setForm({ ...form, yer: e.target.value })} />
              </div>
              <div>
                <label className="label">Ajanda / Gündem</label>
                <textarea className="input" rows={4} placeholder="1. Madde&#10;2. Madde..." value={form.ajanda}
                  onChange={e => setForm({ ...form, ajanda: e.target.value })} />
              </div>
              <div>
                <label className="label">Toplantı Notları</label>
                <textarea className="input" rows={3} value={form.notlar} onChange={e => setForm({ ...form, notlar: e.target.value })} />
              </div>
            </div>
            <div className="px-6 py-4 border-t flex justify-end gap-2">
              <button onClick={() => setModal(false)} className="btn-secondary">İptal</button>
              <button onClick={save} className="btn-primary">Kaydet</button>
            </div>
          </div>
        </div>
      )}

      {notModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b"><h2 className="font-bold text-gray-900">Toplantı Notu Ekle</h2></div>
            <div className="p-6">
              <p className="text-sm font-medium text-gray-700 mb-3">{notModal.baslik}</p>
              <textarea className="input" rows={6} placeholder="Alınan kararlar, katılımcılar, notlar..."
                value={notlar} onChange={e => setNotlar(e.target.value)} />
            </div>
            <div className="px-6 py-4 border-t flex justify-end gap-2">
              <button onClick={() => setNotModal(null)} className="btn-secondary">İptal</button>
              <button onClick={kaydetNotlar} className="btn-primary">Kaydet & Tamamla</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function ToplantiKart({ t, durumInfo, openEdit, onDelete, onNot }: {
  t: Toplanti;
  durumInfo: (v: string) => { cls: string; label: string };
  openEdit: (t: Toplanti) => void;
  onDelete: () => void;
  onNot: () => void;
}) {
  const d = durumInfo(t.durum);
  const tarih = new Date(t.tarih);
  return (
    <div className="card hover:shadow-md transition-shadow">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-start gap-3 flex-1">
          <div className={`mt-0.5 flex-shrink-0 w-12 h-12 rounded-xl flex flex-col items-center justify-center text-center ${t.durum === 'planlandı' ? 'bg-blue-100 text-blue-700' : t.durum === 'tamamlandı' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
            <span className="text-xs font-bold leading-none">{tarih.toLocaleDateString('tr-TR', { month: 'short' }).toUpperCase()}</span>
            <span className="text-xl font-bold leading-none mt-0.5">{tarih.getDate()}</span>
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-2 flex-wrap">
              <h3 className="font-semibold text-gray-900 text-sm">{t.baslik}</h3>
              <span className={d.cls}>{d.label}</span>
            </div>
            <div className="flex items-center gap-1 mt-1 text-xs text-gray-500">
              <MapPin className="w-3 h-3" />{t.yer}
            </div>
            <p className="text-xs text-gray-400 mt-0.5">{tarih.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' })}</p>
          </div>
        </div>
        <div className="flex gap-1">
          <button onClick={() => openEdit(t)} className="p-1.5 text-blue-500 hover:bg-blue-50 rounded"><Pencil className="w-4 h-4" /></button>
          <button onClick={onDelete} className="p-1.5 text-red-500 hover:bg-red-50 rounded"><Trash2 className="w-4 h-4" /></button>
        </div>
      </div>

      {t.ajanda && (
        <div className="mt-3 pt-3 border-t border-gray-100">
          <p className="text-xs text-gray-500 font-medium mb-1">Gündem:</p>
          <p className="text-xs text-gray-600 whitespace-pre-line">{t.ajanda}</p>
        </div>
      )}

      {t.notlar && (
        <div className="mt-2 p-2 bg-gray-50 rounded-lg">
          <p className="text-xs text-gray-500 font-medium mb-1 flex items-center gap-1"><FileText className="w-3 h-3" />Notlar:</p>
          <p className="text-xs text-gray-600">{t.notlar}</p>
        </div>
      )}

      {t.durum === 'planlandı' && (
        <div className="mt-3 pt-3 border-t border-gray-100">
          <button onClick={onNot} className="text-xs font-medium text-green-600 hover:text-green-800 px-2 py-1 hover:bg-green-50 rounded">
            + Not Ekle & Tamamla
          </button>
        </div>
      )}
    </div>
  );
}
