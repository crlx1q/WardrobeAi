import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../calendar/calendar_screen.dart';
import '../scan/scan_screen.dart';
import '../stylist/stylist_screen.dart';
import '../wardrobe/wardrobe_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  final _tabs = const [
    WardrobeScreen(),
    StylistScreen(),
    ScanScreen(),
    CalendarScreen(),
  ];

  static const _items = [
    _NavItem(Icons.checkroom_outlined, Icons.checkroom, 'Гардероб'),
    _NavItem(Icons.auto_awesome_outlined, Icons.auto_awesome, 'Стилист'),
    _NavItem(Icons.camera_alt_outlined, Icons.camera_alt, 'Сканер'),
    _NavItem(Icons.calendar_today_outlined, Icons.calendar_today, 'Календарь'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.cs.surface,
          border: Border(top: BorderSide(color: context.cs.outlineVariant.withValues(alpha: 0.5))),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_items.length, (i) {
                final selected = i == _index;
                final item = _items[i];
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _index = i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected ? item.activeIcon : item.icon,
                          size: 24,
                          color: selected ? context.cs.onSurface : context.cs.outline,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? context.cs.onSurface : context.cs.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
