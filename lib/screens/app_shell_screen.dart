import 'package:expense_tracker_app/controllers/navigation_controller.dart';
import 'package:expense_tracker_app/screens/add_transaction_screen.dart';
import 'package:expense_tracker_app/screens/dashboard_screen.dart';
import 'package:expense_tracker_app/screens/transactions_screen.dart';
import 'package:expense_tracker_app/screens/budget_screen.dart';
import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:expense_tracker_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';

class AppShellScreen extends StatefulWidget {
  const AppShellScreen({super.key});

  @override
  State<AppShellScreen> createState() => _AppShellScreenState();
}

class _AppShellScreenState extends State<AppShellScreen> {
  static const double _tabletBreakpoint = 720;
  static const double _desktopBreakpoint = 1100;

  late final NavigationController _navigationController;
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _navigationController = NavigationController();
  }

  @override
  void dispose() {
    _refreshNotifier.dispose();
    _navigationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _navigationController,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width >= _tabletBreakpoint) {
              return _buildWideScaffold(
                extendedRail: width >= _desktopBreakpoint,
              );
            }
            return _buildMobileScaffold();
          },
        );
      },
    );
  }

  void _handleBudgetSaved(int exceededCount) {
    _navigationController.changeTab(0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final strings = AppStrings.of(context);
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(strings.budgetCheckResultTitle),
            content: Text(
              exceededCount > 0
                  ? strings.overBudgetDescription(exceededCount)
                  : strings.noBudgetExceededMessage,
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(strings.doneLabel),
              ),
            ],
          );
        },
      );
    });
  }

  Scaffold _buildMobileScaffold() {
    final strings = AppStrings.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _navigationController.currentIndex,
        children: [
          DashboardScreen(refreshNotifier: _refreshNotifier),
          TransactionsScreen(refreshNotifier: _refreshNotifier),
          const BudgetScreen(),
          SettingsScreen(onBudgetSaved: _handleBudgetSaved),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (added == true && mounted) {
            _refreshNotifier.value++;
          }
        },
        tooltip: strings.addTransactionTooltip,
        child: const Icon(Icons.add_rounded),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showLabels = constraints.maxWidth >= 390;
            final centerGap = showLabels ? 52.0 : 40.0;

            return SafeArea(
              top: false,
              child: SizedBox(
                height: showLabels ? 62 : 54,
                child: Row(
                  children: [
                    Expanded(
                      child: _NavTabItem(
                        icon: Icons.dashboard_outlined,
                        selectedIcon: Icons.dashboard_rounded,
                        label: strings.dashboardLabel,
                        selected: _navigationController.currentIndex == 0,
                        onTap: () => _navigationController.changeTab(0),
                        showLabel: showLabels,
                      ),
                    ),
                    Expanded(
                      child: _NavTabItem(
                        icon: Icons.receipt_long_outlined,
                        selectedIcon: Icons.receipt_long,
                        label: strings.transactionsLabel,
                        selected: _navigationController.currentIndex == 1,
                        onTap: () => _navigationController.changeTab(1),
                        showLabel: showLabels,
                      ),
                    ),
                    SizedBox(width: centerGap),
                    Expanded(
                      child: _NavTabItem(
                        icon: Icons.pie_chart_outline,
                        selectedIcon: Icons.pie_chart,
                        label: strings.budgetLabel,
                        selected: _navigationController.currentIndex == 2,
                        onTap: () => _navigationController.changeTab(2),
                        showLabel: showLabels,
                      ),
                    ),
                    Expanded(
                      child: _NavTabItem(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings,
                        label: strings.settingsLabel,
                        selected: _navigationController.currentIndex == 3,
                        onTap: () => _navigationController.changeTab(3),
                        showLabel: showLabels,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Scaffold _buildWideScaffold({required bool extendedRail}) {
    final strings = AppStrings.of(context);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
          if (added == true && mounted) {
            _refreshNotifier.value++;
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(strings.addLabel),
      ),
      body: Row(
        children: [
          NavigationRail(
            extended: extendedRail,
            minExtendedWidth: 220,
            selectedIndex: _navigationController.currentIndex,
            onDestinationSelected: _navigationController.changeTab,
            labelType: extendedRail
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text(strings.dashboardLabel),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text(strings.transactionsLabel),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.pie_chart_outline),
                selectedIcon: Icon(Icons.pie_chart),
                label: Text(strings.budgetLabel),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text(strings.settingsLabel),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: IndexedStack(
              index: _navigationController.currentIndex,
              children: [
                DashboardScreen(refreshNotifier: _refreshNotifier),
                TransactionsScreen(refreshNotifier: _refreshNotifier),
                const BudgetScreen(),
                SettingsScreen(onBudgetSaved: _handleBudgetSaved),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.showLabel,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: showLabel ? 6 : 2,
          vertical: showLabel ? 6 : 4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? activeColor : inactiveColor,
            ),
            if (showLabel) ...[
              const SizedBox(height: 3),
              SizedBox(
                width: 60,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? activeColor : inactiveColor,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
