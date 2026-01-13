import 'package:flutter/material.dart';
import 'home_content_screen.dart';
import 'ai_hub_screen.dart';
import 'insights_screen.dart';
import 'tools_screen.dart';
import 'assistant_screen.dart';

class AgriBaseHomeScreen extends StatefulWidget {
  const AgriBaseHomeScreen({super.key});

  @override
  State<AgriBaseHomeScreen> createState() => _AgriBaseHomeScreenState();
}

class _AgriBaseHomeScreenState extends State<AgriBaseHomeScreen> {
  int _selectedNavIndex = 0; // Home is selected by default

  final List<Widget> _screens = [
    const HomeScreen(), // Home Dashboard
    const AIHubScreen(), // AI Hub (centralized AI features)
    const InsightsScreen(), // Insights (merged Analytics, Discover, Region)
    const ToolsScreen(), // Tools (Calculators, Settings)
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _selectedNavIndex, children: _screens),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF1A237E), // Deep indigo for AI
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AssistantScreen()));
        },
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text(
          'Ask AI',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedNavIndex,
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          indicatorColor: theme.colorScheme.primary.withValues(alpha: 0.2),
          onDestinationSelected: (index) {
            setState(() {
              _selectedNavIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.dashboard_outlined,
                color: _selectedNavIndex == 0
                    ? theme.colorScheme.primary
                    : isDark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              selectedIcon: Icon(
                Icons.dashboard,
                color: theme.colorScheme.primary,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: _selectedNavIndex == 1
                      ? Colors.white
                      : isDark
                      ? Colors.grey[400]
                      : const Color.fromARGB(255, 235, 192, 0),
                ),
              ),
              selectedIcon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.psychology_outlined, color: theme.colorScheme.primary,),
              ),
              label: 'AI Hub',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.insights_outlined,
                color: _selectedNavIndex == 2
                    ? theme.colorScheme.primary
                    : isDark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              selectedIcon: Icon(
                Icons.insights,
                color: theme.colorScheme.primary,
              ),
              label: 'Insights',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.build_circle_outlined,
                color: _selectedNavIndex == 3
                    ? theme.colorScheme.primary
                    : isDark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
              selectedIcon: Icon(
                Icons.build_circle,
                color: theme.colorScheme.primary,
              ),
              label: 'Tools',
            ),
          ],
        ),
      ),
    );
  }
}
