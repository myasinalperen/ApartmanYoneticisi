import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Daireler from './pages/Daireler';
import Sakinler from './pages/Sakinler';
import Aidatlar from './pages/Aidatlar';
import Faturalar from './pages/Faturalar';
import Giderler from './pages/Giderler';
import Talepler from './pages/Talepler';
import Sikayetler from './pages/Sikayetler';
import Oylamalar from './pages/Oylamalar';
import Duyurular from './pages/Duyurular';
import Toplantilar from './pages/Toplantilar';

export default function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/daireler" element={<Daireler />} />
          <Route path="/sakinler" element={<Sakinler />} />
          <Route path="/aidatlar" element={<Aidatlar />} />
          <Route path="/faturalar" element={<Faturalar />} />
          <Route path="/giderler" element={<Giderler />} />
          <Route path="/talepler" element={<Talepler />} />
          <Route path="/sikayetler" element={<Sikayetler />} />
          <Route path="/oylamalar" element={<Oylamalar />} />
          <Route path="/duyurular" element={<Duyurular />} />
          <Route path="/toplantilar" element={<Toplantilar />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}
