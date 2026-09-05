import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'home_dashboard_screen.dart';
import 'task_tempo_sync_screen.dart';
import 'gemini_assistant_screen.dart';
import 'finance_tracker_screen.dart';
import 'voice_to_text_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 1; // Default to Task-Tempo Sync screen
  int _previousIndex = 1;

  void _onSelectTab(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(
        onNavigateTab: (index) => _onSelectTab(index),
      ),
      const TaskTempoSyncScreen(),
      const GeminiAssistantScreen(),
      const FinanceTrackerScreen(),
      const VoiceToTextScreen(),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.graphic_eq,
                color: Colors.white,
                size: 20,
              ),
            ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(width: 10),
            Text(
              'Ritme',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: AppColors.onSurface,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_outlined),
            color: AppColors.onSurfaceVariant,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18, left: 6),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: PageTransitionSwitcher(
          duration: const Duration(milliseconds: 350),
          reverse: _currentIndex < _previousIndex,
          transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              fillColor: Colors.transparent,
              child: child,
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(_currentIndex),
            child: screens[_currentIndex],
          ),
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomNav(),
    );
  }

  Widget _buildFloatingBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        height: 72,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Glassmorphic Nav Pill Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(40),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.85),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
                      _buildNavItem(
                          1, Icons.check_box_outlined, Icons.check_box, 'Tasks'),
                      // Placeholder spacer for center raised button
                      const SizedBox(width: 56),
                      _buildNavItem(3, Icons.account_balance_wallet_outlined,
                          Icons.account_balance_wallet, 'Finance'),
                      _buildNavItem(
                          4, Icons.mic_none_outlined, Icons.mic, 'Voice AI'),
                    ],
                  ),
                ),
              ),
            ),

            // Raised Glowing Center Button (Gemini Core AI)
            Positioned(
              top: -12,
              child: GestureDetector(
                onTap: () => _onSelectTab(2),
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF6C4CE0),
                        Color(0xFF987CFE),
                        Color(0xFF534978),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withValues(
                            alpha: _currentIndex == 2 ? 0.6 : 0.4),
                        blurRadius: _currentIndex == 2 ? 24 : 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 26,
                  ),
                )
                .animate(target: _currentIndex == 2 ? 1 : 0)
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  curve: Curves.easeOutBack,
                  duration: 250.ms,
                )
                .shimmer(
                  duration: 1800.ms,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData outlineIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onSelectTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryFixed.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.onSurfaceVariant,
              size: 22,
            ).animate(target: isSelected ? 1 : 0).scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.12, 1.12),
                  curve: Curves.easeOutBack,
                  duration: 200.ms,
                ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
