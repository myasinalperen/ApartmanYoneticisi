import { useEffect, useState } from 'react';
import { getAidatlar, getDaireler, createAidat, updateAidat, deleteAidat, topluOlustur } from '../services/api';
import { Aidat, Daire } from '../types';
import { Plus, CreditCard, CheckCircle2, Clock, Layers } from 'lucide-react';

const AYLAR = ['', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

const now = new Date();
const empty = { daire_id: 0, ay: now.getMonth() + 1, yil: now.getFullYear(), tutar: 750, odendi: false, odeme_tarihi: '', gecikme_faizi: 0 };

export default function Aidatlar() {
  const [aidatlar, setAidatlar] = useState<Aidat[]>([]);
  const [daireler, setDaireler] = useState<Daire[]>([]);
  const [modal, setModal] = useState(false);
  const [topluModal, setTopluModal] = useState(false);
  const [form, setForm] = useState({ ...empty });
  const [topluForm, setTopluForm] = useState({ yil: now.getFullYear(), ay: now.getMonth() + 1, tutar: 750 });
  const [filterAy, setFilterAy] = useState(now.getMonth() + 1);
  const [filterYil, setFilterYil] = useState(now.getFullYear());

  const load = async () => {
    const [a, d] = await Promise.all([
      getAidatlar(filterAy, filterYil),
      getDaireler()
    ]);
    setAidatlar(a.data);
    setDaireler(d.data);
  };

  useEffect(() => { load(); }, [filterAy, filterYil]);

  const daireLabel = (id: number) => {
    const d = daireler.find(x => x.id === id);
    return d ? `${d.blok}${d.daire_no}` : '—';
  };

  const save = async () => {
    if (!form.daire_id) return alert('Daire seçiniz');
    const payload = { ...form, odeme_tarihi: form.odeme_tarihi || null };
    await createAidat(payload);
    setModal(false);
    load();
  };

  const toggleOdeme = async (a: Aidat) => {
    const odendi = !a.odendi;
    await updateAidat(a.id, {
      odendi,
      odeme_tarihi: odendi ? new Date().toISOString().split('T')[0] : null
    });
    load();
  };

  const handleToplu = async () => {
    const res = await topluOlustur(topluForm.yil, topluForm.ay, topluForm.tutar);
    setTopluModal(false);
    alert(`${res.data.olusturulan} adet aidat kaydı oluşturuldu.`);
    load();
  };

  const odenen = aidatlar.filter(a => a.odendi).length;
  const bekleyen = aidatlar.filter(a => !a.odendi).length;
  const toplamTutar = aidatlar.reduce((s, a) => s + a.tutar, 0);
  const odenenTutar = aidatlar.filter(a => a.odendi).reduce((s, a) => s + a.tutar, 0);

  const fmt = (n: number) => n.toLocaleString('tr-TR', { style: 'currency', currency: 'TRY', maximumFractionDigits: 0 });

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-2xl font-bold text-gray-900">Aidatlar</h1>
        <div className="flex gap-2">
          <button onClick={() => setTopluModal(true)} className="btn-secondary flex items-center gap-2">
            <Layers className="w-4 h-4" /> Toplu Oluştur
          </button>
          <button onClick={() => { setForm({ ...empty, daire_id: daireler[0]?.id || 0 }); setModal(true); }} className="btn-primary flex items-center gap-2">
            <Plus className="w-4 h-4" /> Yeni Aidat
          </button>
        </div>
      </div>

      {/* Filters */}
      <div className="flex gap-3 flex-wrap">
        <select className="input w-36" value={filterAy} onChange={e => setFilterAy(+e.target.value)}>
          {AYLAR.slice(1).map((a, i) => <option key={i + 1} value={i + 1}>{a}</option>)}
        </select>
        <select className="input w-28" value={filterYil} onChange={e => setFilterYil(+e.target.value)}>
          {[2024, 2025, 2026, 2027].map(y => <option key={y}>{y}</option>)}
        </select>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <div className="card bg-blue-50 border-blue-100">
          <p className="text-xs text-blue-600 font-medium">Toplam</p>
          <p className="text-xl font-bold text-blue-900 mt-1">{fmt(toplamTutar)}</p>
        </div>
        <div className="card bg-green-50 border-green-100">
          <p className="text-xs text-green-600 font-medium">Ödenen ({odenen})</p>
          <p className="text-xl font-bold text-green-900 mt-1">{fmt(odenenTutar)}</p>
        </div>
        <div className="card bg-red-50 border-red-100">
          <p className="text-xs text-red-600 font-medium">Bekleyen ({bekleyen})</p>
          <p className="text-xl font-bold text-red-900 mt-1">{fmt(toplamTutar - odenenTutar)}</p>
        </div>
        <div className="card bg-gray-50 border-gray-100">
          <p className="text-xs text-gray-600 font-medium">Tahsilat Oranı</p>
          <p className="text-xl font-bold text-gray-900 mt-1">
            {toplamTutar > 0 ? Math.round((odenenTutar / toplamTutar) * 100) : 0}%
          </p>
        </div>
      </div>

      {/* Table */}
      <div className="card overflow-hidden p-0">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Daire</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Dönem</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Tutar</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Durum</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600 hidden md:table-cell">Ödeme Tarihi</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {aidatlar.map(a => (
              <tr key={a.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 font-medium text-gray-900">{daireLabel(a.daire_id)}</td>
                <td className="px-4 py-3 text-gray-600">{AYLAR[a.ay]} {a.yil}</td>
                <td className="px-4 py-3 font-medium text-gray-900">{fmt(a.tutar)}</td>
                <td className="px-4 py-3">
                  <span className={a.odendi ? 'badge-green' : 'badge-red'}>
                    {a.odendi ? 'Ödendi' : 'Bekliyor'}
                  </span>
                </td>
                <td className="px-4 py-3 text-gray-500 text-xs hidden md:table-cell">
                  {a.odeme_tarihi ? new Date(a.odeme_tarihi).toLocaleDateString('tr-TR') : '—'}
                </td>
                <td className="px-4 py-3">
                  <button
                    onClick={() => toggleOdeme(a)}
                    title={a.odendi ? 'Ödenmedi olarak işaretle' : 'Ödendi olarak işaretle'}
                    className={`p-1.5 rounded ${a.odendi ? 'text-green-500 hover:bg-green-50' : 'text-gray-400 hover:bg-gray-100'}`}
                  >
                    {a.odendi ? <CheckCircle2 className="w-5 h-5" /> : <Clock className="w-5 h-5" />}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {aidatlar.length === 0 && (
          <div className="text-center py-12 text-gray-400">
            <CreditCard className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>Bu dönem için aidat kaydı yok</p>
          </div>
        )}
      </div>

      {/* Yeni Aidat Modal */}
      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b"><h2 className="font-bold text-gray-900">Yeni Aidat</h2></div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Daire</label>
                <select className="input" value={form.daire_id} onChange={e => setForm({ ...form, daire_id: +e.target.value })}>
                  <option value={0}>Seçiniz</option>
                  {daireler.map(d => <option key={d.id} value={d.id}>{d.blok}{d.daire_no} - Kat {d.kat}</option>)}
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
              <div className="flex items-center gap-2">
                <input type="checkbox" id="odendi" checked={form.odendi}
                  onChange={e => setForm({ ...form, odendi: e.target.checked })} className="w-4 h-4" />
                <label htmlFor="odendi" className="text-sm text-gray-700">Ödendi</label>
              </div>
              {form.odendi && (
                <div>
                  <label className="label">Ödeme Tarihi</label>
                  <input className="input" type="date" value={form.odeme_tarihi}
                    onChange={e => setForm({ ...form, odeme_tarihi: e.target.value })} />
                </div>
              )}
            </div>
            <div className="px-6 py-4 border-t flex justify-end gap-2">
              <button onClick={() => setModal(false)} className="btn-secondary">İptal</button>
              <button onClick={save} className="btn-primary">Kaydet</button>
            </div>
          </div>
        </div>
      )}

      {/* Toplu Oluştur Modal */}
      {topluModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-sm">
            <div className="px-6 py-4 border-b"><h2 className="font-bold text-gray-900">Toplu Aidat Oluştur</h2></div>
            <div className="p-6 space-y-4">
              <p className="text-sm text-gray-500">Dolu tüm daireler için aidat kaydı oluşturulur.</p>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Ay</label>
                  <select className="input" value={topluForm.ay} onChange={e => setTopluForm({ ...topluForm, ay: +e.target.value })}>
                    {AYLAR.slice(1).map((a, i) => <option key={i + 1} value={i + 1}>{a}</option>)}
                  </select>
                </div>
                <div>
                  <label className="label">Yıl</label>
                  <input className="input" type="number" value={topluForm.yil}
                    onChange={e => setTopluForm({ ...topluForm, yil: +e.target.value })} />
                </div>
              </div>
              <div>
                <label className="label">Aidat Tutarı (₺)</label>
                <input className="input" type="number" value={topluForm.tutar}
                  onChange={e => setTopluForm({ ...topluForm, tutar: +e.target.value })} />
              </div>
            </div>
            <div className="px-6 py-4 border-t flex justify-end gap-2">
              <button onClick={() => setTopluModal(false)} className="btn-secondary">İptal</button>
              <button onClick={handleToplu} className="btn-primary">Oluştur</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
