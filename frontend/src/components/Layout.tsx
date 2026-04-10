import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import {
  LayoutDashboard, Building2, Users, CreditCard, FileText,
  Wrench, MessageSquareWarning, Vote, Megaphone, TrendingDown,
  CalendarDays, Menu, X, Building
} from 'lucide-react';

const navItems = [
  { path: '/', label: 'Panel', icon: LayoutDashboard },
  { path: '/daireler', label: 'Daireler', icon: Building2 },
  { path: '/sakinler', label: 'Sakinler', icon: Users },
  { path: '/aidatlar', label: 'Aidatlar', icon: CreditCard },
  { path: '/faturalar', label: 'Faturalar', icon: FileText },
  { path: '/giderler', label: 'Giderler', icon: TrendingDown },
  { path: '/talepler', label: 'Talepler', icon: Wrench },
  { path: '/sikayetler', label: 'Şikayetler', icon: MessageSquareWarning },
  { path: '/oylamalar', label: 'Oylamalar', icon: Vote },
  { path: '/duyurular', label: 'Duyurular', icon: Megaphone },
  { path: '/toplantilar', label: 'Toplantılar', icon: CalendarDays },
];

export default function Layout({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="flex h-screen bg-gray-50">
      {sidebarOpen && (
        <div className="fixed inset-0 bg-black/50 z-20 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      <aside className={`
        fixed lg:static inset-y-0 left-0 z-30
        w-64 bg-white border-r border-gray-200 flex flex-col
        transform transition-transform duration-200 ease-in-out
        ${sidebarOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'}
      `}>
        <div className="flex items-center gap-3 px-6 py-5 border-b border-gray-200">
          <div className="w-9 h-9 bg-blue-600 rounded-lg flex items-center justify-center">
            <Building className="w-5 h-5 text-white" />
          </div>
          <div>
            <p className="font-bold text-gray-900 text-sm leading-tight">Apartman</p>
            <p className="font-bold text-blue-600 text-sm leading-tight">Yöneticisi</p>
          </div>
          <button className="ml-auto lg:hidden text-gray-500 hover:text-gray-700" onClick={() => setSidebarOpen(false)}>
            <X className="w-5 h-5" />
          </button>
        </div>

        <nav className="flex-1 px-3 py-4 overflow-y-auto">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                onClick={() => setSidebarOpen(false)}
                className={`
                  flex items-center gap-3 px-3 py-2.5 rounded-lg mb-0.5
                  text-sm font-medium transition-colors
                  ${isActive ? 'bg-blue-50 text-blue-700' : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'}
                `}
              >
                <Icon className={`w-5 h-5 ${isActive ? 'text-blue-600' : 'text-gray-400'}`} />
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="px-6 py-4 border-t border-gray-200">
          <p className="text-xs text-gray-400">v1.0.0 · 2026</p>
        </div>
      </aside>

      <div className="flex-1 flex flex-col overflow-hidden">
        <header className="bg-white border-b border-gray-200 px-4 py-3 flex items-center gap-3 lg:hidden">
          <button onClick={() => setSidebarOpen(true)} className="text-gray-500 hover:text-gray-700">
            <Menu className="w-6 h-6" />
          </button>
          <div className="flex items-center gap-2">
            <div className="w-7 h-7 bg-blue-600 rounded flex items-center justify-center">
              <Building className="w-4 h-4 text-white" />
            </div>
            <span className="font-bold text-gray-900 text-sm">Apartman Yöneticisi</span>
          </div>
        </header>

        <main className="flex-1 overflow-y-auto p-4 lg:p-6">
          {children}
        </main>
      </div>
    </div>
  );
}
