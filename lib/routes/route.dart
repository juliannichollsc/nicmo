import 'package:go_router/go_router.dart';
import 'package:nicmo/routes/transitions.dart';
import 'package:nicmo/screens/onboarding/onboarding.dart';
import 'package:nicmo/state/city_state.dart';
import 'package:nicmo/state/onboarding_state.dart';
import 'package:nicmo/screens/home/home.dart';
import 'package:nicmo/screens/lines/lines.dart';
import 'package:nicmo/screens/cities/cities.dart';
import 'package:nicmo/screens/legal/terms.dart';
import 'package:nicmo/screens/settings/settings.dart';
import 'package:nicmo/screens/trip/trip.dart';
import 'package:nicmo/state/active_trip_state.dart';
import 'package:nicmo/widget/shared/shell.dart';
import 'package:nicmo/widget/shared/firm.dart';

final GoRouter appRouter = GoRouter(
  // The welcome slides are shown once, then the map.
  initialLocation: ActiveTripStore.pending != null
      ? '/trip'
      // The welcome slides end with the choice of city: shown until made.
      // No account: straight to the map afterwards.
      : (OnboardingState.seen && cityController.current != null
            ? '/home'
            : '/welcome'),
  routes: <RouteBase>[
    GoRoute(
      path: '/welcome',
      pageBuilder: (context, state) =>
          fadeThroughPage(state: state, child: const OnboardingScreen()),
    ),
    GoRoute(
      path: '/lines',
      pageBuilder: (context, state) =>
          sharedAxisPage(state: state, child: const LinesScreen()),
    ),
    GoRoute(
      path: '/terms',
      pageBuilder: (context, state) =>
          slideUpPage(state: state, child: const TermsScreen()),
    ),
    GoRoute(
      path: '/cities',
      pageBuilder: (context, state) =>
          sharedAxisPage(state: state, child: const CitiesScreen()),
    ),
    GoRoute(
      path: '/trip',
      pageBuilder: (context, state) =>
          slideUpPage(state: state, child: const TripScreen()),
    ),
    StatefulShellRoute(
      pageBuilder: (context, state, navigationShell) => fadeThroughPage(
        state: state,
        child: AppShell(navigationShell: navigationShell),
      ),
      navigatorContainerBuilder: (context, navigationShell, children) =>
          AnimatedBranchContainer(
            currentIndex: navigationShell.currentIndex,
            children: children,
          ),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const FirmWidget(child: HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) =>
                  const FirmWidget(child: SettingsScreen()),
            ),
          ],
        ),
      ],
    ),
  ],
);
