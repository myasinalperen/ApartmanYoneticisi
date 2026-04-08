import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/dashboard_screen.dart';
import 'screens/daireler_screen.dart';
import 'screens/sakinler_screen.dart';
import 'screens/aidatlar_screen.dart';
import 'screens/faturalar_screen.dart';
import 'screens/giderler_screen.dart';
import 'screens/talepler_screen.dart';
import 'screens/sikayetler_screen.dart';
import 'screens/oylamalar_screen.dart';
import 'screens/duyurular_screen.dart';
import 'screens/toplantilar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR', null);
  runApp(const ApartmanYoneticisiApp());
}

class ApartmanYoneticisiApp extends StatelessWidget {
  const ApartmanYoneticisiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Apartman Yöneticisi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.screen,
  });
}

final navItems = [
  const NavItem(label: 'Panel', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, screen: DashboardScreen()),
  const NavItem(label: 'Daireler', icon: Icons.apartment_outlined, activeIcon: Icons.apartment_rounded, screen: DairelerScreen()),
  const NavItem(label: 'Sakinler', icon: Icons.people_outline, activeIcon: Icons.people_rounded, screen: SakinlerScreen()),
  const NavItem(label: 'Aidatlar', icon: Icons.credit_card_outlined, activeIcon: Icons.credit_card_rounded, screen: AidatlarScreen()),
  const NavItem(label: 'Faturalar', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, screen: FaturalarScreen()),
  const NavItem(label: 'Giderler', icon: Icons.trending_down_outlined, activeIcon: Icons.trending_down_rounded, screen: GiderlerScreen()),
  const NavItem(label: 'Talepler', icon: Icons.build_outlined, activeIcon: Icons.build_rounded, screen: TaleplerScreen()),
  const NavItem(label: 'Şikayetler', icon: Icons.report_problem_outlined, activeIcon: Icons.report_problem_rounded, screen: SikayetlerScreen()),
  const NavItem(label: 'Oylamalar', icon: Icons.how_to_vote_outlined, activeIcon: Icons.how_to_vote_rounded, screen: OylamalarScreen()),
  const NavItem(label: 'Duyurular', icon: Icons.campaign_outlined, activeIcon: Icons.campaign_rounded, screen: DuyurularScreen()),
  const NavItem(label: 'Toplantılar', icon: Icons.event_outlined, activeIcon: Icons.event_rounded, screen: ToplantilarScreen()),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;
    final current = navItems[_selectedIndex];

    if (isWide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              backgroundColor: Colors.white,
              useIndicator: true,
              indicatorColor: const Color(0xFFDBEAFE),
              labelType: NavigationRailLabelType.all,
              selectedLabelTextStyle: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
              unselectedLabelTextStyle:
                  TextStyle(fontSize: 11, color: Colors.grey.shade600),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.business, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 4),
                  const Text('Apartman',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  const Text('Yöneticisi',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ]),
              ),
              destinations: navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.activeIcon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  title: Row(children: [
                    Icon(current.activeIcon,
                        size: 20, color: const Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(current.label),
                  ]),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: Text(
                          _getDateStr(),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ),
                    ),
                  ],
                ),
                body: current.screen,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text(current.label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: current.screen,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2563EB)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.business, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 10),
                const Text('Apartman Yöneticisi',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_getDateStr(),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: navItems.length,
              itemBuilder: (_, i) {
                final item = navItems[i];
                final selected = _selectedIndex == i;
                return ListTile(
                  leading: Icon(
                    selected ? item.activeIcon : item.icon,
                    color: selected ? const Color(0xFF2563EB) : Colors.grey.shade600,
                    size: 22,
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected ? const Color(0xFF2563EB) : const Color(0xFF374151),
                    ),
                  ),
                  tileColor: selected ? const Color(0xFFEFF6FF) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('v1.0.0 · 2026',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ),
        ],
      ),
    );
  }

  String _getDateStr() {
    final now = DateTime.now();
    const aylar = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${now.day} ${aylar[now.month - 1]} ${now.year}';
  }
}
