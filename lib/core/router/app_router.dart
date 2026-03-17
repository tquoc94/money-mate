import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qlct/features/auth/presentation/login_screen.dart';
import 'package:qlct/features/auth/providers/auth_providers.dart';
import 'package:qlct/features/dashboard/presentation/dashboard_screen.dart';
import 'package:qlct/features/transactions/presentation/screens/transaction_list_screen.dart';
import 'package:qlct/features/reports/presentation/report_screen.dart';
import 'package:qlct/features/settings/presentation/settings_screen.dart';
import 'package:qlct/features/transactions/presentation/screens/add_edit_transaction_screen.dart';
import 'package:qlct/features/budget/presentation/budget_screen.dart';
import 'package:qlct/features/transactions/presentation/screens/category_management_screen.dart';
import 'package:qlct/features/savings/presentation/savings_screen.dart';
import 'package:qlct/features/debts/presentation/debt_screen.dart';
import 'package:qlct/features/reminders/presentation/reminder_screen.dart';
import 'package:qlct/features/settings/presentation/about_screen.dart';
import 'package:qlct/core/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnLogin = state.uri.path == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            name: 'transactions',
            builder: (context, state) => const TransactionListScreen(),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/transaction/add',
        name: 'addTransaction',
        builder: (context, state) => const AddEditTransactionScreen(),
      ),
      GoRoute(
        path: '/transaction/edit/:id',
        name: 'editTransaction',
        builder: (context, state) =>
            AddEditTransactionScreen(transactionId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/budget',
        name: 'budget',
        builder: (context, state) => const BudgetScreen(),
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),
      GoRoute(
        path: '/savings',
        name: 'savings',
        builder: (context, state) => const SavingsScreen(),
      ),
      GoRoute(
        path: '/debts',
        name: 'debts',
        builder: (context, state) => const DebtScreen(),
      ),
      GoRoute(
        path: '/reminders',
        name: 'reminders',
        builder: (context, state) => const ReminderScreen(),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});
