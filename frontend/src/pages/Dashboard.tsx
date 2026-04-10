import { useEffect, useState } from 'react';
import { getDashboard, seedDatabase } from '../services/api';
import { DashboardStats } from '../types';
import {
  Building2, Users, CreditCard, FileText, Wrench,
  MessageSquareWarning, Vote, TrendingDown, AlertCircle, CheckCircle2,
  Database, RefreshCw
} from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell, Legend } from 'recharts';

const AYLAR = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];

function StatCard({ title, value, sub, icon: Icon, color, bg }: {
  title: string; value: string | number; sub?: string;
  icon: React.ElementType; color: string; bg: string;
}) {
  return (
    <div className="card flex items-start gap-4">
      <div className={`${bg} p-3 rounded-lg`}>
        <Icon className={`w-6 h-6 ${color}`} />
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm text-gray-500 font-medium">{title}</p>
        <p className="text-2xl font-bold text-gray-900 mt-0.5">{value}</p>
        {sub && <p className="text-xs text-gray-400 mt-0.5">{sub}</p>}
      </div>
    </div>
  );
}

export default function Dashboard() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [seeding, setSeeding] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const res = await getDashboard();
      setStats(res.data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const handleSeed = async () => {
    setSeeding(true);
    try {
      await seedDatabase();
      await load();
    } finally {
      setSeeding(false);
    }
  };

  useEffect(() => { load(); }, []);

  const now = new Date();
  const ayAdi = AYLAR[now.getMonth()];

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <RefreshCw className="w-8 h-8 text-blue-500 animate-spin" />
      </div>
    );
  }

  if (!stats) return null;

  const aidatData = [
    { name: 'Ödenen', value: stats.bu_ay_aidat_odenen, fill: '#22c55e' },
    { name: 'Bekleyen', value: stats.bu_ay_aidat_bekleyen, fill: '#ef4444' },
  ];

  const dolulukData = [
    { name: 'Dolu', value: stats.dolu_daire, fill: '#3b82f6' },
    { name: 'Boş', value: stats.bos_daire, fill: '#d1d5db' },
  ];

  const fmt = (n: number) =>
    n.toLocaleString('tr-TR', { style: 'currency', currency: 'TRY', maximumFractionDigits: 0 });

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Yönetim Paneli</h1>
          <p className="text-sm text-gray-500 mt-1">{now.toLocaleDateString('tr-TR', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</p>
        </div>
        <div className="flex gap-2">
          <button onClick={handleSeed} disabled={seeding}
            className="flex items-center gap-2 btn-secondary text-xs"
            title="Örnek veri yükle">
            <Database className={`w-4 h-4 ${seeding ? 'animate-spin' : ''}`} />
            {seeding ? 'Yükleniyor...' : 'Örnek Veri'}
          </button>
          <button onClick={load} className="flex items-center gap-2 btn-secondary text-xs">
            <RefreshCw className="w-4 h-4" />
            Yenile
          </button>
        </div>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard title="Toplam Daire" value={stats.toplam_daire}
          sub={`${stats.dolu_daire} dolu · ${stats.bos_daire} boş`}
          icon={Building2} color="text-blue-600" bg="bg-blue-50" />
        <StatCard title="Aktif Sakin" value={stats.toplam_sakin}
          icon={Users} color="text-purple-600" bg="bg-purple-50" />
        <StatCard title="Bekleyen Talep" value={stats.bekleyen_talep}
          icon={Wrench} color="text-orange-600" bg="bg-orange-50" />
        <StatCard title="Açık Şikayet" value={stats.acik_sikayet}
          icon={MessageSquareWarning} color="text-red-600" bg="bg-red-50" />
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard title={`${ayAdi} Aidat Toplam`} value={fmt(stats.bu_ay_aidat_toplam)}
          icon={CreditCard} color="text-green-600" bg="bg-green-50" />
        <StatCard title="Ödenen Aidat" value={fmt(stats.bu_ay_aidat_odenen)}
          sub="Bu ay" icon={CheckCircle2} color="text-green-600" bg="bg-green-50" />
        <StatCard title="Bekleyen Aidat" value={fmt(stats.bu_ay_aidat_bekleyen)}
          sub="Tahsilat bekliyor" icon={AlertCircle} color="text-yellow-600" bg="bg-yellow-50" />
        <StatCard title="Bu Ay Gider" value={fmt(stats.bu_ay_gider)}
          icon={TrendingDown} color="text-red-600" bg="bg-red-50" />
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <StatCard title="Ödenmemiş Fatura" value={stats.odenmemis_fatura}
          sub="Adet" icon={FileText} color="text-orange-600" bg="bg-orange-50" />
        <StatCard title="Aktif Oylama" value={stats.aktif_oylama}
          icon={Vote} color="text-blue-600" bg="bg-blue-50" />
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Aidat durumu */}
        <div className="card">
          <h2 className="font-semibold text-gray-900 mb-4">{ayAdi} Aidat Durumu</h2>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={aidatData} cx="50%" cy="50%" innerRadius={55} outerRadius={80}
                dataKey="value" paddingAngle={3}>
                {aidatData.map((entry, i) => (
                  <Cell key={i} fill={entry.fill} />
                ))}
              </Pie>
              <Tooltip formatter={(v: number) => fmt(v)} />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Doluluk */}
        <div className="card">
          <h2 className="font-semibold text-gray-900 mb-4">Daire Doluluk</h2>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie data={dolulukData} cx="50%" cy="50%" innerRadius={55} outerRadius={80}
                dataKey="value" paddingAngle={3}>
                {dolulukData.map((entry, i) => (
                  <Cell key={i} fill={entry.fill} />
                ))}
              </Pie>
              <Tooltip />
              <Legend />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Durum özeti */}
        <div className="card">
          <h2 className="font-semibold text-gray-900 mb-4">Genel Durum</h2>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={[
              { name: 'Talep', value: stats.bekleyen_talep },
              { name: 'Şikayet', value: stats.acik_sikayet },
              { name: 'Oylama', value: stats.aktif_oylama },
              { name: 'Fatura', value: stats.odenmemis_fatura },
            ]}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="name" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Bar dataKey="value" fill="#3b82f6" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
