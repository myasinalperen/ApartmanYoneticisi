import { useEffect, useState } from 'react';
import { getDaireler, createDaire, updateDaire, deleteDaire } from '../services/api';
import { Daire } from '../types';
import { Plus, Pencil, Trash2, Building2 } from 'lucide-react';

const TIPLER = ['1+1', '2+1', '3+1', '4+1', 'Stüdyo'];
const BLOKLAR = ['A', 'B', 'C', 'D'];

const empty = { blok: 'A', kat: 1, daire_no: '', tip: '2+1', metrekare: 85, durum: 'dolu' };

export default function Daireler() {
  const [daireler, setDaireler] = useState<Daire[]>([]);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState<Daire | null>(null);
  const [form, setForm] = useState({ ...empty });
  const [search, setSearch] = useState('');

  const load = async () => {
    const res = await getDaireler();
    setDaireler(res.data);
  };

  useEffect(() => { load(); }, []);

  const openNew = () => { setEditing(null); setForm({ ...empty }); setModal(true); };
  const openEdit = (d: Daire) => {
    setEditing(d);
    setForm({ blok: d.blok, kat: d.kat, daire_no: d.daire_no, tip: d.tip, metrekare: d.metrekare, durum: d.durum });
    setModal(true);
  };

  const save = async () => {
    if (!form.daire_no) return alert('Daire numarası zorunludur');
    if (editing) await updateDaire(editing.id, form);
    else await createDaire(form);
    setModal(false);
    load();
  };

  const remove = async (id: number) => {
    if (!confirm('Bu daireyi silmek istediğinize emin misiniz?')) return;
    await deleteDaire(id);
    load();
  };

  const filtered = daireler.filter(d =>
    `${d.blok}${d.daire_no} ${d.tip}`.toLowerCase().includes(search.toLowerCase())
  );

  const grouped = filtered.reduce((acc, d) => {
    const key = d.blok;
    if (!acc[key]) acc[key] = [];
    acc[key].push(d);
    return acc;
  }, {} as Record<string, Daire[]>);

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Daireler</h1>
        <button onClick={openNew} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Yeni Daire
        </button>
      </div>

      <div className="flex gap-3">
        <input className="input max-w-xs" placeholder="Daire ara..." value={search}
          onChange={e => setSearch(e.target.value)} />
        <div className="flex gap-4 ml-2 text-sm text-gray-500 items-center">
          <span className="badge-blue">{daireler.filter(d => d.durum === 'dolu').length} Dolu</span>
          <span className="badge-gray">{daireler.filter(d => d.durum === 'bos').length} Boş</span>
        </div>
      </div>

      {Object.entries(grouped).sort().map(([blok, list]) => (
        <div key={blok}>
          <h2 className="text-sm font-semibold text-gray-500 mb-2 uppercase tracking-wide">{blok} Blok</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
            {list.map(d => (
              <div key={d.id} className="card hover:shadow-md transition-shadow">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-2">
                    <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${d.durum === 'dolu' ? 'bg-blue-100' : 'bg-gray-100'}`}>
                      <Building2 className={`w-5 h-5 ${d.durum === 'dolu' ? 'text-blue-600' : 'text-gray-400'}`} />
                    </div>
                    <div>
                      <p className="font-bold text-gray-900">{d.blok}{d.daire_no}</p>
                      <p className="text-xs text-gray-500">Kat {d.kat}</p>
                    </div>
                  </div>
                  <span className={d.durum === 'dolu' ? 'badge-blue' : 'badge-gray'}>
                    {d.durum === 'dolu' ? 'Dolu' : 'Boş'}
                  </span>
                </div>
                <div className="space-y-1 text-sm text-gray-600">
                  <p><span className="text-gray-400">Tip:</span> {d.tip}</p>
                  <p><span className="text-gray-400">Alan:</span> {d.metrekare} m²</p>
                </div>
                <div className="flex gap-2 mt-3 pt-3 border-t border-gray-100">
                  <button onClick={() => openEdit(d)} className="flex-1 flex items-center justify-center gap-1 text-xs text-blue-600 hover:text-blue-800 font-medium">
                    <Pencil className="w-3.5 h-3.5" /> Düzenle
                  </button>
                  <button onClick={() => remove(d.id)} className="flex-1 flex items-center justify-center gap-1 text-xs text-red-500 hover:text-red-700 font-medium">
                    <Trash2 className="w-3.5 h-3.5" /> Sil
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}

      {filtered.length === 0 && (
        <div className="card text-center py-12 text-gray-400">
          <Building2 className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>Daire bulunamadı</p>
        </div>
      )}

      {/* Modal */}
      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b border-gray-200">
              <h2 className="font-bold text-gray-900">{editing ? 'Daire Düzenle' : 'Yeni Daire'}</h2>
            </div>
            <div className="p-6 space-y-4">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Blok</label>
                  <select className="input" value={form.blok} onChange={e => setForm({ ...form, blok: e.target.value })}>
                    {BLOKLAR.map(b => <option key={b}>{b}</option>)}
                  </select>
                </div>
                <div>
                  <label className="label">Kat</label>
                  <input className="input" type="number" min={0} value={form.kat}
                    onChange={e => setForm({ ...form, kat: +e.target.value })} />
                </div>
              </div>
              <div>
                <label className="label">Daire No</label>
                <input className="input" value={form.daire_no}
                  onChange={e => setForm({ ...form, daire_no: e.target.value })}
                  placeholder="Örn: 3, 5A" />
              </div>
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="label">Daire Tipi</label>
                  <select className="input" value={form.tip} onChange={e => setForm({ ...form, tip: e.target.value })}>
                    {TIPLER.map(t => <option key={t}>{t}</option>)}
                  </select>
                </div>
                <div>
                  <label className="label">Alan (m²)</label>
                  <input className="input" type="number" value={form.metrekare}
                    onChange={e => setForm({ ...form, metrekare: +e.target.value })} />
                </div>
              </div>
              <div>
                <label className="label">Durum</label>
                <select className="input" value={form.durum} onChange={e => setForm({ ...form, durum: e.target.value })}>
                  <option value="dolu">Dolu</option>
                  <option value="bos">Boş</option>
                </select>
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
