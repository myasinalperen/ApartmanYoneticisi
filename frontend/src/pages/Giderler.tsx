import { useEffect, useState } from 'react';
import { getGiderler, createGider, updateGider, deleteGider } from '../services/api';
import { Gider } from '../types';
import { Plus, Pencil, Trash2, TrendingDown } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

const KATEGORILER = [
  { value: 'bakim', label: 'Bakım & Onarım' },
  { value: 'temizlik', label: 'Temizlik' },
  { value: 'elektrik', label: 'Elektrik' },
  { value: 'su', label: 'Su' },
  { value: 'dogalgaz', label: 'Doğalgaz' },
  { value: 'asansor', label: 'Asansör' },
  { value: 'guvenlik', label: 'Güvenlik' },
  { value: 'diger', label: 'Diğer' },
];

const KAT_COLORS: Record<string, string> = {
  bakim: 'badge-orange', temizlik: 'badge-green', elektrik: 'badge-yellow',
  su: 'badge-blue', dogalgaz: 'badge-orange', asansor: 'badge-purple',
  guvenlik: 'badge-red', diger: 'badge-gray'
};

const now = new Date();
const empty = { kategori: 'bakim', aciklama: '', tutar: 0, tarih: now.toISOString().split('T')[0], belge_no: '' };

export default function Giderler() {
  const [giderler, setGiderler] = useState<Gider[]>([]);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState<Gider | null>(null);
  const [form, setForm] = useState({ ...empty });
  const [filterKat, setFilterKat] = useState('');

  const load = async () => {
    const res = await getGiderler();
    setGiderler(res.data);
  };

  useEffect(() => { load(); }, []);

  const openNew = () => { setEditing(null); setForm({ ...empty }); setModal(true); };
  const openEdit = (g: Gider) => {
    setEditing(g);
    setForm({ kategori: g.kategori, aciklama: g.aciklama, tutar: g.tutar, tarih: g.tarih, belge_no: g.belge_no });
    setModal(true);
  };

  const save = async () => {
    if (!form.aciklama) return alert('Açıklama zorunludur');
    if (editing) await updateGider(editing.id, form);
    else await createGider(form);
    setModal(false);
    load();
  };

  const remove = async (id: number) => {
    if (!confirm('Gideri silmek istediğinize emin misiniz?')) return;
    await deleteGider(id);
    load();
  };

  const filtered = filterKat ? giderler.filter(g => g.kategori === filterKat) : giderler;
  const toplamGider = filtered.reduce((s, g) => s + g.tutar, 0);

  const fmt = (n: number) => n.toLocaleString('tr-TR', { style: 'currency', currency: 'TRY', maximumFractionDigits: 0 });

  // Kategori bazlı özet
  const katOzet = KATEGORILER.map(k => ({
    name: k.label,
    tutar: giderler.filter(g => g.kategori === k.value).reduce((s, g) => s + g.tutar, 0)
  })).filter(k => k.tutar > 0);

  const katLabel = (v: string) => KATEGORILER.find(k => k.value === v)?.label || v;

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-2xl font-bold text-gray-900">Giderler</h1>
        <button onClick={openNew} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Yeni Gider
        </button>
      </div>

      <div className="flex gap-3 flex-wrap items-center">
        <select className="input w-48" value={filterKat} onChange={e => setFilterKat(e.target.value)}>
          <option value="">Tüm Kategoriler</option>
          {KATEGORILER.map(k => <option key={k.value} value={k.value}>{k.label}</option>)}
        </select>
        <span className="text-sm font-semibold text-gray-700">Toplam: {fmt(toplamGider)}</span>
      </div>

      {/* Chart */}
      {katOzet.length > 0 && (
        <div className="card">
          <h2 className="font-semibold text-gray-900 mb-4 text-sm">Kategori Bazlı Dağılım</h2>
          <ResponsiveContainer width="100%" height={180}>
            <BarChart data={katOzet}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => `₺${(v / 1000).toFixed(0)}K`} />
              <Tooltip formatter={(v: number) => fmt(v)} />
              <Bar dataKey="tutar" fill="#3b82f6" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      )}

      <div className="card overflow-hidden p-0">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Tarih</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Kategori</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Açıklama</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Tutar</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600 hidden md:table-cell">Belge No</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filtered.map(g => (
              <tr key={g.id} className="hover:bg-gray-50">
                <td className="px-4 py-3 text-gray-500 text-xs whitespace-nowrap">
                  {new Date(g.tarih).toLocaleDateString('tr-TR')}
                </td>
                <td className="px-4 py-3">
                  <span className={KAT_COLORS[g.kategori] || 'badge-gray'}>{katLabel(g.kategori)}</span>
                </td>
                <td className="px-4 py-3 text-gray-700">{g.aciklama}</td>
                <td className="px-4 py-3 font-semibold text-gray-900">{fmt(g.tutar)}</td>
                <td className="px-4 py-3 text-gray-400 text-xs hidden md:table-cell">{g.belge_no || '—'}</td>
                <td className="px-4 py-3">
                  <div className="flex gap-1">
                    <button onClick={() => openEdit(g)} className="p-1.5 text-blue-500 hover:bg-blue-50 rounded">
                      <Pencil className="w-4 h-4" />
                    </button>
                    <button onClick={() => remove(g.id)} className="p-1.5 text-red-500 hover:bg-red-50 rounded">
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && (
          <div className="text-center py-12 text-gray-400">
            <TrendingDown className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>Gider kaydı yok</p>
          </div>
        )}
      </div>

      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b"><h2 className="font-bold text-gray-900">{editing ? 'Gider Düzenle' : 'Yeni Gider'}</h2></div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Kategori</label>
                <select className="input" value={form.kategori} onChange={e => setForm({ ...form, kategori: e.target.value })}>
                  {KATEGORILER.map(k => <option key={k.value} value={k.value}>{k.label}</option>)}
                </select>
              </div>
              <div>
                <label className="label">Açıklama</label>
                <input className="input" value={form.aciklama} onChange={e => setForm({ ...form, aciklama: e.target.value })} />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Tutar (₺)</label>
                  <input className="input" type="number" value={form.tutar} onChange={e => setForm({ ...form, tutar: +e.target.value })} />
                </div>
                <div>
                  <label className="label">Tarih</label>
                  <input className="input" type="date" value={form.tarih} onChange={e => setForm({ ...form, tarih: e.target.value })} />
                </div>
              </div>
              <div>
                <label className="label">Belge / Fatura No</label>
                <input className="input" value={form.belge_no} onChange={e => setForm({ ...form, belge_no: e.target.value })} />
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
