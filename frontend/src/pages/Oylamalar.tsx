import { useEffect, useState } from 'react';
import { getOylamalar, getDaireler, createOylama, updateOylama, deleteOylama, oyVer } from '../services/api';
import { Oylama, Daire } from '../types';
import { Plus, Vote, Trash2, Users } from 'lucide-react';

const DURUMLAR = [
  { value: 'aktif', label: 'Aktif', cls: 'badge-green' },
  { value: 'tamamlandi', label: 'Tamamlandı', cls: 'badge-blue' },
  { value: 'iptal', label: 'İptal', cls: 'badge-gray' },
];

export default function Oylamalar() {
  const [oylamalar, setOylamalar] = useState<Oylama[]>([]);
  const [daireler, setDaireler] = useState<Daire[]>([]);
  const [modal, setModal] = useState(false);
  const [oyModal, setOyModal] = useState<Oylama | null>(null);
  const [oyDaireId, setOyDaireId] = useState(0);
  const [oySecenekId, setOySecenekId] = useState(0);
  const [form, setForm] = useState({ baslik: '', aciklama: '', bitis: '', durum: 'aktif', secenekler: ['Evet', 'Hayır'] });
  const [newSecenek, setNewSecenek] = useState('');

  const load = async () => {
    const [o, d] = await Promise.all([getOylamalar(), getDaireler()]);
    setOylamalar(o.data);
    setDaireler(d.data);
  };

  useEffect(() => { load(); }, []);

  const save = async () => {
    if (!form.baslik) return alert('Başlık zorunludur');
    if (form.secenekler.length < 2) return alert('En az 2 seçenek giriniz');
    await createOylama({ ...form, bitis: form.bitis || null });
    setModal(false);
    setForm({ baslik: '', aciklama: '', bitis: '', durum: 'aktif', secenekler: ['Evet', 'Hayır'] });
    load();
  };

  const handleOyVer = async () => {
    if (!oyDaireId || !oySecenekId) return alert('Daire ve seçenek belirtiniz');
    try {
      await oyVer({ oylama_id: oyModal!.id, daire_id: oyDaireId, secenek_id: oySecenekId });
      setOyModal(null);
      load();
    } catch (e: any) {
      alert(e.response?.data?.detail || 'Hata oluştu');
    }
  };

  const durumGuncelle = async (id: number, durum: string) => {
    await updateOylama(id, { durum });
    load();
  };

  const remove = async (id: number) => {
    if (!confirm('Oylamayı silmek istediğinize emin misiniz?')) return;
    await deleteOylama(id);
    load();
  };

  const durumInfo = (v: string) => DURUMLAR.find(d => d.value === v) || DURUMLAR[0];

  return (
    <div className="space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-2xl font-bold text-gray-900">Oylamalar</h1>
        <button onClick={() => setModal(true)} className="btn-primary flex items-center gap-2">
          <Plus className="w-4 h-4" /> Yeni Oylama
        </button>
      </div>

      <div className="space-y-4">
        {oylamalar.map(o => {
          const d = durumInfo(o.durum);
          const kazanan = o.secenekler.length > 0
            ? o.secenekler.reduce((a, b) => a.oy_sayisi >= b.oy_sayisi ? a : b)
            : null;
          return (
            <div key={o.id} className="card hover:shadow-md transition-shadow">
              <div className="flex items-start justify-between gap-4">
                <div className="flex-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    <Vote className="w-5 h-5 text-blue-500" />
                    <h3 className="font-semibold text-gray-900">{o.baslik}</h3>
                    <span className={d.cls}>{d.label}</span>
                  </div>
                  {o.aciklama && <p className="text-sm text-gray-600 mt-1">{o.aciklama}</p>}
                  <div className="flex items-center gap-4 mt-1 text-xs text-gray-400">
                    <span>Başlangıç: {new Date(o.baslangic).toLocaleDateString('tr-TR')}</span>
                    {o.bitis && <span>Bitiş: {new Date(o.bitis).toLocaleDateString('tr-TR')}</span>}
                    <span className="flex items-center gap-1"><Users className="w-3 h-3" />{o.toplam_oy} oy</span>
                  </div>
                </div>
                <div className="flex gap-1">
                  {o.durum === 'aktif' && (
                    <button onClick={() => { setOyModal(o); setOyDaireId(daireler[0]?.id || 0); setOySecenekId(o.secenekler[0]?.id || 0); }}
                      className="btn-primary text-xs py-1.5">Oy Ver</button>
                  )}
                  <button onClick={() => remove(o.id)} className="p-1.5 text-red-500 hover:bg-red-50 rounded">
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Sonuçlar */}
              {o.secenekler.length > 0 && (
                <div className="mt-4 space-y-2">
                  {o.secenekler.map(s => {
                    const yuzde = o.toplam_oy > 0 ? Math.round((s.oy_sayisi / o.toplam_oy) * 100) : 0;
                    const isKazanan = kazanan?.id === s.id && o.toplam_oy > 0;
                    return (
                      <div key={s.id}>
                        <div className="flex items-center justify-between text-sm mb-1">
                          <span className={`font-medium ${isKazanan ? 'text-blue-700' : 'text-gray-700'}`}>
                            {s.metin} {isKazanan && o.durum !== 'aktif' && '✓'}
                          </span>
                          <span className="text-gray-500">{s.oy_sayisi} oy ({yuzde}%)</span>
                        </div>
                        <div className="w-full bg-gray-100 rounded-full h-2">
                          <div className={`h-2 rounded-full transition-all ${isKazanan ? 'bg-blue-500' : 'bg-gray-300'}`}
                            style={{ width: `${yuzde}%` }} />
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}

              {o.durum === 'aktif' && (
                <div className="flex gap-2 mt-3 pt-3 border-t border-gray-100">
                  <button onClick={() => durumGuncelle(o.id, 'tamamlandi')} className="text-xs font-medium text-blue-600 hover:text-blue-800 px-2 py-1 hover:bg-blue-50 rounded">
                    ✓ Tamamla
                  </button>
                  <button onClick={() => durumGuncelle(o.id, 'iptal')} className="text-xs font-medium text-gray-500 hover:text-gray-700 px-2 py-1 hover:bg-gray-100 rounded">
                    ✕ İptal
                  </button>
                </div>
              )}
            </div>
          );
        })}
      </div>

      {oylamalar.length === 0 && (
        <div className="card text-center py-12 text-gray-400">
          <Vote className="w-12 h-12 mx-auto mb-3 opacity-30" />
          <p>Oylama bulunamadı</p>
        </div>
      )}

      {/* Yeni Oylama Modal */}
      {modal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-md max-h-[90vh] overflow-y-auto">
            <div className="px-6 py-4 border-b sticky top-0 bg-white"><h2 className="font-bold text-gray-900">Yeni Oylama</h2></div>
            <div className="p-6 space-y-4">
              <div>
                <label className="label">Başlık</label>
                <input className="input" value={form.baslik} onChange={e => setForm({ ...form, baslik: e.target.value })} />
              </div>
              <div>
                <label className="label">Açıklama</label>
                <textarea className="input" rows={3} value={form.aciklama} onChange={e => setForm({ ...form, aciklama: e.target.value })} />
              </div>
              <div>
                <label className="label">Bitiş Tarihi</label>
                <input className="input" type="datetime-local" value={form.bitis} onChange={e => setForm({ ...form, bitis: e.target.value })} />
              </div>
              <div>
                <label className="label">Seçenekler</label>
                <div className="space-y-2">
                  {form.secenekler.map((s, i) => (
                    <div key={i} className="flex gap-2">
                      <input className="input flex-1" value={s}
                        onChange={e => { const arr = [...form.secenekler]; arr[i] = e.target.value; setForm({ ...form, secenekler: arr }); }} />
                      <button onClick={() => setForm({ ...form, secenekler: form.secenekler.filter((_, j) => j !== i) })}
                        className="px-2 text-red-500 hover:bg-red-50 rounded text-sm">✕</button>
                    </div>
                  ))}
                  <div className="flex gap-2">
                    <input className="input flex-1" placeholder="Yeni seçenek..." value={newSecenek}
                      onChange={e => setNewSecenek(e.target.value)}
                      onKeyDown={e => { if (e.key === 'Enter' && newSecenek.trim()) { setForm({ ...form, secenekler: [...form.secenekler, newSecenek.trim()] }); setNewSecenek(''); } }} />
                    <button onClick={() => { if (newSecenek.trim()) { setForm({ ...form, secenekler: [...form.secenekler, newSecenek.trim()] }); setNewSecenek(''); } }}
                      className="btn-secondary text-xs">Ekle</button>
                  </div>
                </div>
              </div>
            </div>
            <div className="px-6 py-4 border-t flex justify-end gap-2">
              <button onClick={() => setModal(false)} className="btn-secondary">İptal</button>
              <button onClick={save} className="btn-primary">Oluştur</button>
            </div>
          </div>
        </div>
      )}

      {/* Oy Ver Modal */}
      {oyModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl w-full max-w-sm">
            <div className="px-6 py-4 border-b"><h2 className="font-bold text-gray-900">Oy Ver</h2></div>
            <div className="p-6 space-y-4">
              <p className="text-sm text-gray-600 font-medium">{oyModal.baslik}</p>
              <div>
                <label className="label">Hangi Daire Adına?</label>
                <select className="input" value={oyDaireId} onChange={e => setOyDaireId(+e.target.value)}>
                  {daireler.map(d => <option key={d.id} value={d.id}>{d.blok}{d.daire_no} - Kat {d.kat}</option>)}
                </select>
              </div>
              <div>
                <label className="label">Seçeneğiniz</label>
                <div className="space-y-2">
                  {oyModal.secenekler.map(s => (
                    <label key={s.id} className={`flex items-center gap-3 p-3 border rounded-lg cursor-pointer transition-colors ${oySecenekId === s.id ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300'}`}>
                      <input type="radio" name="secenek" value={s.id} checked={oySecenekId === s.id}
                        onChange={() => setOySecenekId(s.id)} className="w-4 h-4" />
                      <span className="text-sm font-medium">{s.metin}</span>
                    </label>
                  ))}
                </div>
              </div>
            </div>
            <div className="px-6 py-4 border-t flex justify-end gap-2">
              <button onClick={() => setOyModal(null)} className="btn-secondary">İptal</button>
              <button onClick={handleOyVer} className="btn-primary">Oyu Gönder</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
