import { useEffect, useState } from 'react';
import { getSakinler, getDaireler, createSakin, updateSakin, deleteSakin } from '../services/api';
import { Sakin, Daire } from '../types';
import { Plus, Pencil, Trash2, Users, Phone, Mail } from 'lucide-react';

const empty = {
  ad: '', soyad: '', telefon: '', email: '',
  daire_id: 0, tip: 'kiracı', giris_tarihi: '', aktif: true
};

export default function Sakinler() {
  const [sakinler, setSakinler] = useState<Sakin[]>([]);
  const [daireler, setDaireler] = useState<Daire[]>([]);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState<Sakin | null>(null);
  const [form, setForm] = useState({ ...empty });
  const [search, setSearch] = useState('');
  const [filterTip, setFilterTip] = useState('');

  const load = async () => {
    const [s, d] = await Promise.all([getSakinler(), getDaireler()]);
    setSakinler(s.data);
    setDaireler(d.data);
  };

  useEffect(() => { load(); }, []);

  const daireLabel = (id: number) => {
    const d = daireler.find(x => x.id === id);
    return d ? `${d.blok}${d.daire_no} (Kat ${d.kat})` : '—';
  };

  const openNew = () => {
    setEditing(null);
    setForm({ ...empty, daire_id: daireler[0]?.id || 0 });
    setModal(true);
  };

  const openEdit = (s: Sakin) => {
    setEditing(s);
    setForm({
      ad: s.ad, soyad: s.soyad, telefon: s.telefon || '',
      email: s.email || '', daire_id: s.daire_id,
      tip: s.tip, giris_tarihi: s.giris_tarihi || '', aktif: s.aktif
    });
    setModal(true);
  };

  const save = async () => {
    if (!form.ad || !form.soyad) return alert('Ad ve soyad zorunludur');
    if (!form.daire_id) return alert('Daire seçiniz');
    const payload = { ...form, giris_tarihi: form.giris_tarihi || null };
    if (editing) await updateSakin(editing.id, payload);
    else await createSakin(payload);
    setModal(false);
    load();
  };

  const remove = async (id: number) => {
    if (!confirm('Bu sakini silmek istediğinize emin misiniz?')) return;
    await deleteSakin(id);
    load();
  };

  const filtered = sakinler.filter(s => {
    const text = `${s.ad} ${s.soyad} ${s.telefon} ${s.email}`.toLowerCase();
    return (
      text.includes(search.toLowerCase()) &&
      (filterTip ? s.tip === filterTip : true)
    );
  });

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Sakinler</h1>
        <button onClick={openNew} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Yeni Sakin
        </button>
      </div>

      <div className="flex flex-wrap gap-3">
        <input className="input max-w-xs" placeholder="İsim, telefon ara..." value={search}
          onChange={e => setSearch(e.target.value)} />
        <select className="input w-40" value={filterTip} onChange={e => setFilterTip(e.target.value)}>
          <option value="">Tüm Tipler</option>
          <option value="ev_sahibi">Ev Sahibi</option>
          <option value="kiracı">Kiracı</option>
        </select>
      </div>

      <div className="card overflow-hidden p-0">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Sakin</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Daire</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Tip</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600 hidden md:table-cell">İletişim</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600 hidden lg:table-cell">Giriş</th>
              <th className="text-left px-4 py-3 font-medium text-gray-600">Durum</th>
              <th className="px-4 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {filtered.map(s => (
              <tr key={s.id} className="hover:bg-gray-50">
                <td className="px-4 py-3">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-700 font-bold text-sm">
                      {s.ad[0]}{s.soyad[0]}
                    </div>
                    <span className="font-medium text-gray-900">{s.ad} {s.soyad}</span>
                  </div>
                </td>
                <td className="px-4 py-3 text-gray-600">{daireLabel(s.daire_id)}</td>
                <td className="px-4 py-3">
                  <span className={s.tip === 'ev_sahibi' ? 'badge-blue' : 'badge-purple'}>
                    {s.tip === 'ev_sahibi' ? 'Ev Sahibi' : 'Kiracı'}
                  </span>
                </td>
                <td className="px-4 py-3 hidden md:table-cell">
                  <div className="space-y-0.5">
                    {s.telefon && <div className="flex items-center gap-1 text-gray-500 text-xs"><Phone className="w-3 h-3" />{s.telefon}</div>}
                    {s.email && <div className="flex items-center gap-1 text-gray-500 text-xs"><Mail className="w-3 h-3" />{s.email}</div>}
                  </div>
                </td>
                <td className="px-4 py-3 text-gray-500 hidden lg:table-cell text-xs">
                  {s.giris_tarihi ? new Date(s.giris_tarihi).toLocaleDateString('tr-TR') : '—'}
                </td>
                <td className="px-4 py-3">
                  <span className={s.aktif ? 'badge-green' : 'badge-gray'}>
                    {s.aktif ? 'Aktif' : 'Pasif'}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <div className="flex gap-1">
                    <button onClick={() => openEdit(s)} className="p-1.5 text-blue-500 hover:bg-blue-50 rounded">
                      <Pencil className="w-4 h-4" />
                    </button>
                    <button onClick={() => remove(s.id)} className="p-1.5 text-red-500 hover:bg-red-50 rounded">
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
            <Users className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>Sakin bulunamadı</p>
          </div>
        )}
      </div>

      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="font-bold text-gray-900">{editing ? 'Sakin Düzenle' : 'Yeni Sakin'}</h2>
            </div>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Ad</label>
                  <input className="input" value={form.ad} onChange={e => setForm({ ...form, ad: e.target.value })} />
                </div>
                <div>
                  <label className="label">Soyad</label>
                  <input className="input" value={form.soyad} onChange={e => setForm({ ...form, soyad: e.target.value })} />
                </div>
              </div>
              <div>
                <label className="label">Telefon</label>
                <input className="input" value={form.telefon} onChange={e => setForm({ ...form, telefon: e.target.value })} placeholder="0532 xxx xx xx" />
              </div>
              <div>
                <label className="label">E-posta</label>
                <input className="input" type="email" value={form.email} onChange={e => setForm({ ...form, email: e.target.value })} />
              </div>
              <div>
                <label className="label">Daire</label>
                <select className="input" value={form.daire_id} onChange={e => setForm({ ...form, daire_id: +e.target.value })}>
                  <option value={0}>Seçiniz</option>
                  {daireler.map(d => (
                    <option key={d.id} value={d.id}>{d.blok}{d.daire_no} - Kat {d.kat} ({d.tip})</option>
                  ))}
                </select>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Tip</label>
                  <select className="input" value={form.tip} onChange={e => setForm({ ...form, tip: e.target.value })}>
                    <option value="ev_sahibi">Ev Sahibi</option>
                    <option value="kiracı">Kiracı</option>
                  </select>
                </div>
                <div>
                  <label className="label">Giriş Tarihi</label>
                  <input className="input" type="date" value={form.giris_tarihi}
                    onChange={e => setForm({ ...form, giris_tarihi: e.target.value })} />
                </div>
              </div>
              <div className="flex items-center gap-2">
                <input type="checkbox" id="aktif" checked={form.aktif}
                  onChange={e => setForm({ ...form, aktif: e.target.checked })} className="w-4 h-4" />
                <label htmlFor="aktif" className="text-sm text-gray-700">Aktif sakin</label>
              </div>
            </div>
            <div className="px-6 py-4 border-t border-gray-200 flex justify-end gap-2">
              <button onClick={() => setModal(false)} className="btn-secondary">İptal</button>
              <button onClick={save} className="btn-primary">Kaydet</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
