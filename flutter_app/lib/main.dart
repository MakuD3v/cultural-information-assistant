import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'models/models.dart';
import 'screens/login_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/plan_screen.dart';
import 'screens/guide_screen.dart';
import 'screens/map_screen.dart';
import 'screens/culture_screen.dart';
import 'screens/culture_detail_screen.dart';
import 'screens/more_screen.dart';

void main() {
  runApp(const CulturalAssistantApp());
}

class CulturalAssistantApp extends StatelessWidget {
  const CulturalAssistantApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SorSU × CTU Can Tho Exchange',
      theme: MekongTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const MainAppController(),
    );
  }
}

class MainAppController extends StatefulWidget {
  const MainAppController({Key? key}) : super(key: key);

  @override
  State<MainAppController> createState() => _MainAppControllerState();
}

class _MainAppControllerState extends State<MainAppController> {
  UserProfile? _currentUser;
  int _currentTabIndex = 0; // 0: Home, 1: Plan, 2: Ask, 3: Map, 4: Culture, 5: More
  CulturalArticleItem? _activeDetailArticle;
  String? _pendingGuideQuery;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return LoginScreen(
        onLoginSuccess: (user) {
          setState(() {
            _currentUser = user;
            _currentTabIndex = 0;
          });
        },
      );
    }

    if (_activeDetailArticle != null) {
      return CultureDetailScreen(
        article: _activeDetailArticle!,
        onBack: () => setState(() => _activeDetailArticle = null),
        onAskAboutThis: (query) {
          setState(() {
            _activeDetailArticle = null;
            _currentTabIndex = 2; // Ask tab
            _pendingGuideQuery = query;
          });
        },
        onOpenMap: () {
          setState(() {
            _activeDetailArticle = null;
            _currentTabIndex = 3; // Map tab
          });
        },
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          // 0: Home Dashboard (Fixed non-scrollable)
          HomeDashboardScreen(
            user: _currentUser!,
            onNavigateTab: (index) {
              setState(() {
                _pendingGuideQuery = null;
                _currentTabIndex = index;
              });
            },
            onOpenArticle: (article) => setState(() => _activeDetailArticle = article),
          ),

          // 1: Plan
          PlanScreen(
            user: _currentUser!,
            onSelectActivity: (act) {
              setState(() {
                _currentTabIndex = 2; // Ask guide
                _pendingGuideQuery = 'What time is ${act.title}?';
              });
            },
          ),

          // 2: Ask Guide
          GuideScreen(
            initialQuery: _pendingGuideQuery,
          ),

          // 3: Map
          MapScreen(
            onAskAbout: (q) {
              setState(() {
                _currentTabIndex = 2;
                _pendingGuideQuery = q;
              });
            },
          ),

          // 4: Culture
          CultureScreen(
            onSelectArticle: (article) {
              setState(() => _activeDetailArticle = article);
            },
          ),

          // 5: More
          MoreScreen(
            user: _currentUser!,
            onSignOut: () => setState(() => _currentUser = null),
            onOpenApprovedSources: () {
              setState(() => _currentTabIndex = 4);
            },
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: MekongColors.card,
          border: const Border(top: BorderSide(color: MekongColors.divider, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavTab(0, Icons.home_outlined, 'Home'),
            _buildNavTab(1, Icons.calendar_today_outlined, 'Plan'),

            // Center prominent Ask Clay circular button
            InkWell(
              onTap: () {
                setState(() {
                  _pendingGuideQuery = null;
                  _currentTabIndex = 2;
                });
              },
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: MekongColors.clay,
                  shape: BoxShape.circle,
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                    SizedBox(height: 2),
                    Text(
                      'Ask',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),

            _buildNavTab(3, Icons.map_outlined, 'Map'),
            _buildNavTab(4, Icons.menu_book_outlined, 'Culture'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;
    final color = isSelected ? MekongColors.riverGreen : MekongColors.ink.withOpacity(0.6);
    return InkWell(
      onTap: () {
        setState(() {
          _pendingGuideQuery = null;
          _currentTabIndex = index;
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
