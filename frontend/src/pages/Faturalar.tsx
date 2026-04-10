import { useEffect, useState } from 'react';
import { getFaturalar, createFatura, updateFatura, deleteFatura } from '../services/api';
import { Fatura } from '../types';
import { Plus, Pencil, Trash2, FileText, CheckCircle2, Clock, Zap, Droplets, Flame, Wind, Star } from 'lucide-react';

const AYLAR = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

const TIPLER = [
  { value: 'elektrik', label: 'Elektrik', icon: Zap, color: 'text-yellow-500', bg: 'bg-yellow-50' },
  { value: 'su', label: 'Su', icon: Droplets, color: 'text-blue-500', bg: 'bg-blue-50' },
  { value: 'dogalgaz', label: 'Doğalgaz', icon: Flame, color: 'text-orange-500', bg: 'bg-orange-50' },
  { value: 'asansor', label: 'Asansör', icon: Wind, color: 'text-purple-500', bg: 'bg-purple-50' },
  { value: 'temizlik', label: 'Temizlik', icon: Star, color: 'text-green-500', bg: 'bg-green-50' },
  { value: 'internet', label: 'İnternet', icon: Wind, color: 'text-indigo-500', bg: 'bg-indigo-50' },
  { value: 'diger', label: 'Diğer', icon: FileText, color: 'text-gray-500', bg: 'bg-gray-50' },
];

const now = new Date();
const empty = { tip: 'elektrik', ay: now.getMonth() + 1, yil: now.getFullYear(), tutar: 0, son_odeme_tarihi: '', odendi: false, aciklama: '' };

export default function Faturalar() {
  const [faturalar, setFaturalar] = useState<Fatura[]>([]);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState<Fatura | null>(null);
  const [form, setForm] = useState({ ...empty });
  const [filterAy, setFilterAy] = useState<number>(0);
  const [filterYil, setFilterYil] = useState(now.getFullYear());

  const load = async () => {
    const res = await getFaturalar(filterAy || undefined, filterYil);
    setFaturalar(res.data);
  };

  useEffect(() => { load(); }, [filterAy, filterYil]);

  const tipInfo = (tip: string) => TIPLER.find(t => t.value === tip) || TIPLER[TIPLER.length - 1];

  const openNew = () => { setEditing(null); setForm({ ...empty }); setModal(true); };
  const openEdit = (f: Fatura) => {
    setEditing(f);
    setForm({ tip: f.tip, ay: f.ay, yil: f.yil, tutar: f.tutar, son_odeme_tarihi: f.son_odeme_tarihi || '', odendi: f.odendi, aciklama: f.aciklama });
    setModal(true);
  };

  const save = async () => {
    const payload = { ...form, son_odeme_tarihi: form.son_odeme_tarihi || null };
    if (editing) await updateFatura(editing.id, payload);
    else await createFatura(payload);
    setModal(false);
    load();
  };

  const toggleOdeme = async (f: Fatura) => {
    await updateFatura(f.id, { odendi: !f.odendi });
    load();
  };

  const remove = async (id: number) => {
    if (!confirm('Faturayı silmek istediğinize emin misiniz?')) return;
    await deleteFatura(id);
    load();
  };

  const fmt = (n: number) => n.toLocaleString('tr-TR', { style: 'currency', currency: 'TRY', maximumFractionDigits: 0 });
  const odenmemisTopla = faturalar.filter(f => !f.odendi).reduce((s, f) => s + f.tutar, 0);

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-2xl font-bold text-gray-900">Faturalar</h1>
        <button onClick={openNew} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Yeni Fatura
        </button>
      </div>

      <div className="flex gap-3 flex-wrap items-center">
        <select className="input w-36" value={filterAy} onChange={e => setFilterAy(+e.target.value)}>
          <option value={0}>Tüm Aylar</option>
          {AYLAR.slice(1).map((a, i) => <option key={i + 1} value={i + 1}>{a}</option>)}
        </select>
        <select className="input w-28" value={filterYil} onChange={e => setFilterYil(+e.target.value)}>
          {[2024, 2025, 2026, 2027].map(y => <option key={y}>{y}</option>)}
        </select>
        {odenmemisTopla > 0 && (
          <span className="badge-red text-sm px-3 py-1">Ödenmemiş: {fmt(odenmemisTopla)}</span>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {faturalar.map(f => {
          const info = tipInfo(f.tip);
          const Icon = info.icon;
          const gecikti = f.son_odeme_tarihi && !f.odendi && new Date(f.son_odeme_tarihi) < new Date();
          return (
            <div key={f.id} className={`card hover:shadow-md transition-shadow ${gecikti ? 'border-red-200' : ''}`}>
              <div className="flex items-start justify-between mb-3">
                <div className="flex items-center gap-3">
                  <div className={`${info.bg} p-2.5 rounded-lg`}>
                    <Icon className={`w-5 h-5 ${info.color}`} />
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900">{info.label}</p>
                    <p className="text-xs text-gray-500">{AYLAR[f.ay]} {f.yil}</p>
                  </div>
                </div>
                <div className="flex gap-1">
                  <button onClick={() => openEdit(f)} className="p-1.5 text-blue-500 hover:bg-blue-50 rounded">
                    <Pencil className="w-4 h-4" />
                  </button>
                  <button onClick={() => remove(f.id)} className="p-1.5 text-red-500 hover:bg-red-50 rounded">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <p className="text-2xl font-bold text-gray-900 mb-2">{fmt(f.tutar)}</p>

              {f.aciklama && <p className="text-xs text-gray-500 mb-2">{f.aciklama}</p>}

              {f.son_odeme_tarihi && (
                <p className={`text-xs mb-2 ${gecikti ? 'text-red-500 font-medium' : 'text-gray-500'}`}>
                  Son ödeme: {new Date(f.son_odeme_tarihi).toLocaleDateString('tr-TR')}
                  {gecikti && ' — GECİKMİŞ'}
                </p>
              )}

              <div className="flex items-center justify-between pt-2 border-t border-gray-100">
                <span className={f.odendi ? 'badge-green' : 'badge-red'}>
                  {f.odendi ? 'Ödendi' : 'Bekliyor'}
                </span>
                <button onClick={() => toggleOdeme(f)}
                  className={`flex items-center gap-1 text-xs font-medium px-2.5 py-1 rounded-full transition-colors ${f.odendi ? 'text-gray-500 hover:bg-gray-100' : 'text-green-600 hover:bg-green-50'}`}
                >
                  {f.odendi ? <><Clock className="w-3.5 h-3.5" /> Geri Al</> : <><CheckCircle2 className="w-3.5 h-3.5" /> Ödendi</>}
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {faturalar.length === 0 && (
        <div className="card text-center py-12 text-gray-400">
          <FileText className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>Bu dönem için fatura yok</p>
        </div>
      )}

      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b"><h2 className="font-bold text-gray-900">{editing ? 'Fatura Düzenle' : 'Yeni Fatura'}</h2></div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Fatura Türü</label>
                <select className="input" value={form.tip} onChange={e => setForm({ ...form, tip: e.target.value })}>
                  {TIPLER.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Ay</label>
                  <select className="input" value={form.ay} onChange={e => setForm({ ...form, ay: +e.target.value })}>
                    {AYLAR.slice(1).map((a, i) => <option key={i + 1} value={i + 1}>{a}</option>)}
                  </select>
                </div>
                <div>
                  <label className="label">Yıl</label>
                  <input className="input" type="number" value={form.yil} onChange={e => setForm({ ...form, yil: +e.target.value })} />
                </div>
              </div>
              <div>
                <label className="label">Tutar (₺)</label>
                <input className="input" type="number" value={form.tutar} onChange={e => setForm({ ...form, tutar: +e.target.value })} />
              </div>
              <div>
                <label className="label">Son Ödeme Tarihi</label>
                <input className="input" type="date" value={form.son_odeme_tarihi}
                  onChange={e => setForm({ ...form, son_odeme_tarihi: e.target.value })} />
              </div>
              <div>
                <label className="label">Açıklama</label>
                <input className="input" value={form.aciklama} onChange={e => setForm({ ...form, aciklama: e.target.value })} />
              </div>
              <div className="flex items-center gap-2">
                <input type="checkbox" id="fodendi" checked={form.odendi}
                  onChange={e => setForm({ ...form, odendi: e.target.checked })} className="w-4 h-4" />
                <label htmlFor="fodendi" className="text-sm text-gray-700">Ödendi</label>
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
