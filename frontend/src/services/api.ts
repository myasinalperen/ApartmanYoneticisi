import axios from 'axios';

const api = axios.create({ baseURL: '/api' });
export default api;

export const getDaireler = () => api.get('/daireler/');
export const createDaire = (data: object) => api.post('/daireler/', data);
export const updateDaire = (id: number, data: object) => api.put(`/daireler/${id}`, data);
export const deleteDaire = (id: number) => api.delete(`/daireler/${id}`);

export const getSakinler = () => api.get('/sakinler/');
export const createSakin = (data: object) => api.post('/sakinler/', data);
export const updateSakin = (id: number, data: object) => api.put(`/sakinler/${id}`, data);
export const deleteSakin = (id: number) => api.delete(`/sakinler/${id}`);

export const getAidatlar = (ay?: number, yil?: number) => {
  const params: Record<string, number> = {};
  if (ay) params.ay = ay;
  if (yil) params.yil = yil;
  return api.get('/aidatlar/', { params });
};
export const createAidat = (data: object) => api.post('/aidatlar/', data);
export const topluOlustur = (yil: number, ay: number, tutar: number) =>
  api.post('/aidatlar/toplu-olustur', null, { params: { yil, ay, tutar } });
export const updateAidat = (id: number, data: object) => api.put(`/aidatlar/${id}`, data);
export const deleteAidat = (id: number) => api.delete(`/aidatlar/${id}`);

export const getFaturalar = (ay?: number, yil?: number) => {
  const params: Record<string, number> = {};
  if (ay) params.ay = ay;
  if (yil) params.yil = yil;
  return api.get('/faturalar/', { params });
};
export const createFatura = (data: object) => api.post('/faturalar/', data);
export const updateFatura = (id: number, data: object) => api.put(`/faturalar/${id}`, data);
export const deleteFatura = (id: number) => api.delete(`/faturalar/${id}`);

export const getTalepler = (durum?: string) => api.get('/talepler/', { params: durum ? { durum } : {} });
export const createTalep = (data: object) => api.post('/talepler/', data);
export const updateTalep = (id: number, data: object) => api.put(`/talepler/${id}`, data);
export const deleteTalep = (id: number) => api.delete(`/talepler/${id}`);

export const getSikayetler = (durum?: string) => api.get('/sikayetler/', { params: durum ? { durum } : {} });
export const createSikayet = (data: object) => api.post('/sikayetler/', data);
export const updateSikayet = (id: number, data: object) => api.put(`/sikayetler/${id}`, data);
export const deleteSikayet = (id: number) => api.delete(`/sikayetler/${id}`);

export const getOylamalar = () => api.get('/oylamalar/');
export const createOylama = (data: object) => api.post('/oylamalar/', data);
export const updateOylama = (id: number, data: object) => api.put(`/oylamalar/${id}`, data);
export const deleteOylama = (id: number) => api.delete(`/oylamalar/${id}`);
export const oyVer = (data: object) => api.post('/oylamalar/oy-ver', data);

export const getDuyurular = () => api.get('/duyurular/');
export const createDuyuru = (data: object) => api.post('/duyurular/', data);
export const updateDuyuru = (id: number, data: object) => api.put(`/duyurular/${id}`, data);
export const deleteDuyuru = (id: number) => api.delete(`/duyurular/${id}`);

export const getGiderler = () => api.get('/giderler/');
export const createGider = (data: object) => api.post('/giderler/', data);
export const updateGider = (id: number, data: object) => api.put(`/giderler/${id}`, data);
export const deleteGider = (id: number) => api.delete(`/giderler/${id}`);

export const getToplantilar = () => api.get('/toplantilar/');
export const createToplanti = (data: object) => api.post('/toplantilar/', data);
export const updateToplanti = (id: number, data: object) => api.put(`/toplantilar/${id}`, data);
export const deleteToplanti = (id: number) => api.delete(`/toplantilar/${id}`);

export const getDashboard = () => api.get('/dashboard');
export const seedDatabase = () => api.post('/seed');
