import 'dart:async';

import 'package:flutter/material.dart';
<<<<<<< Updated upstream
<<<<<<< Updated upstream
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import '/backend/backend.dart';

import '/auth/base_auth_user_provider.dart';
=======
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
>>>>>>> Stashed changes
=======
import 'package:go_router/go_router.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
>>>>>>> Stashed changes

import '/main.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/lat_lng.dart';
import '/flutter_flow/place.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'serialization_util.dart';

import '/index.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier._();

  static AppStateNotifier? _instance;
  static AppStateNotifier get instance => _instance ??= AppStateNotifier._();

<<<<<<< Updated upstream
<<<<<<< Updated upstream
  BaseAuthUser? initialUser;
  BaseAuthUser? user;
  bool showSplashImage = true;
  String? _redirectLocation;

  /// Determines whether the app will refresh and build again when a sign
  /// in or sign out happens. This is useful when the app is launched or
  /// on an unexpected logout. However, this must be turned off when we
  /// intend to sign in/out and then navigate or perform any actions after.
  /// Otherwise, this will trigger a refresh and interrupt the action(s).
  bool notifyOnAuthChange = true;

  bool get loading => user == null || showSplashImage;
  bool get loggedIn => user?.loggedIn ?? false;
  bool get initiallyLoggedIn => initialUser?.loggedIn ?? false;
  bool get shouldRedirect => loggedIn && _redirectLocation != null;

  String getRedirectLocation() => _redirectLocation!;
  bool hasRedirect() => _redirectLocation != null;
  void setRedirectLocationIfUnset(String loc) => _redirectLocation ??= loc;
  void clearRedirectLocation() => _redirectLocation = null;

  /// Mark as not needing to notify on a sign in / out when we intend
  /// to perform subsequent actions (such as navigation) afterwards.
  void updateNotifyOnAuthChange(bool notify) => notifyOnAuthChange = notify;

  void update(BaseAuthUser newUser) {
    final shouldUpdate =
        user?.uid == null || newUser.uid == null || user?.uid != newUser.uid;
    initialUser ??= newUser;
    user = newUser;
    // Refresh the app on auth change unless explicitly marked otherwise.
    // No need to update unless the user has changed.
    if (notifyOnAuthChange && shouldUpdate) {
      notifyListeners();
    }
    // Once again mark the notifier as needing to update on auth change
    // (in order to catch sign in / out events).
    updateNotifyOnAuthChange(true);
  }
=======
  bool showSplashImage = true;
>>>>>>> Stashed changes
=======
  bool showSplashImage = true;
>>>>>>> Stashed changes

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) => GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: appStateNotifier,
      navigatorKey: appNavigatorKey,
<<<<<<< Updated upstream
<<<<<<< Updated upstream
      errorBuilder: (context, state) =>
          appStateNotifier.loggedIn ? NavBarPage() : LoginPageWidget(),
=======
      errorBuilder: (context, state) => HomePageWidget(),
>>>>>>> Stashed changes
=======
      errorBuilder: (context, state) => HomePageWidget(),
>>>>>>> Stashed changes
      routes: [
        FFRoute(
          name: '_initialize',
          path: '/',
<<<<<<< Updated upstream
<<<<<<< Updated upstream
          builder: (context, _) =>
              appStateNotifier.loggedIn ? NavBarPage() : LoginPageWidget(),
        ),
        FFRoute(
          name: LoginPageWidget.routeName,
          path: LoginPageWidget.routePath,
          builder: (context, params) => LoginPageWidget(),
        ),
        FFRoute(
          name: RegisterAccountWidget.routeName,
          path: RegisterAccountWidget.routePath,
          builder: (context, params) => RegisterAccountWidget(),
        ),
        FFRoute(
          name: CompleteProfileWidget.routeName,
          path: CompleteProfileWidget.routePath,
          builder: (context, params) => CompleteProfileWidget(),
        ),
        FFRoute(
          name: ForgotPasswordWidget.routeName,
          path: ForgotPasswordWidget.routePath,
          builder: (context, params) => ForgotPasswordWidget(),
        ),
        FFRoute(
          name: OnboardingWidget.routeName,
          path: OnboardingWidget.routePath,
          builder: (context, params) => OnboardingWidget(),
        ),
        FFRoute(
          name: CreateBudgetBeginWidget.routeName,
          path: CreateBudgetBeginWidget.routePath,
          builder: (context, params) => CreateBudgetBeginWidget(),
        ),
        FFRoute(
          name: MYCardWidget.routeName,
          path: MYCardWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'MY_Card')
              : MYCardWidget(),
        ),
        FFRoute(
          name: MYBudgetsWidget.routeName,
          path: MYBudgetsWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'MY_Budgets')
              : MYBudgetsWidget(),
        ),
        FFRoute(
          name: PaymentDetailsWidget.routeName,
          path: PaymentDetailsWidget.routePath,
          builder: (context, params) => PaymentDetailsWidget(
            transactionDetails: params.getParam(
              'transactionDetails',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['transactions'],
            ),
            userSpent: params.getParam(
              'userSpent',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['users'],
            ),
          ),
        ),
        FFRoute(
          name: MYProfilePageWidget.routeName,
          path: MYProfilePageWidget.routePath,
          builder: (context, params) => params.isEmpty
              ? NavBarPage(initialPage: 'MY_profilePage')
              : MYProfilePageWidget(
                  userProfile: params.getParam(
                    'userProfile',
                    ParamType.DocumentReference,
                    isList: false,
                    collectionNamePath: ['users'],
                  ),
                ),
        ),
        FFRoute(
          name: BudgetDetailsWidget.routeName,
          path: BudgetDetailsWidget.routePath,
          builder: (context, params) => BudgetDetailsWidget(
            budgetDetails: params.getParam(
              'budgetDetails',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['budgets'],
            ),
          ),
        ),
        FFRoute(
          name: TransferCompleteWidget.routeName,
          path: TransferCompleteWidget.routePath,
          builder: (context, params) => TransferCompleteWidget(),
        ),
        FFRoute(
          name: TransferFundsWidget.routeName,
          path: TransferFundsWidget.routePath,
          builder: (context, params) => TransferFundsWidget(),
        ),
        FFRoute(
          name: RequestFundsWidget.routeName,
          path: RequestFundsWidget.routePath,
          builder: (context, params) => RequestFundsWidget(),
        ),
        FFRoute(
          name: CreateBudgetWidget.routeName,
          path: CreateBudgetWidget.routePath,
          builder: (context, params) => CreateBudgetWidget(),
        ),
        FFRoute(
          name: TransactionADDWidget.routeName,
          path: TransactionADDWidget.routePath,
          builder: (context, params) => TransactionADDWidget(),
        ),
        FFRoute(
          name: TransactionEDITWidget.routeName,
          path: TransactionEDITWidget.routePath,
          builder: (context, params) => TransactionEDITWidget(
            transactionDetails: params.getParam(
              'transactionDetails',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['transactions'],
            ),
          ),
        ),
        FFRoute(
          name: EditProfileWidget.routeName,
          path: EditProfileWidget.routePath,
          builder: (context, params) => EditProfileWidget(
            userProfile: params.getParam(
              'userProfile',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['users'],
            ),
          ),
        ),
        FFRoute(
          name: ChangePasswordWidget.routeName,
          path: ChangePasswordWidget.routePath,
          builder: (context, params) => ChangePasswordWidget(),
        ),
        FFRoute(
          name: NotificationsSettingsWidget.routeName,
          path: NotificationsSettingsWidget.routePath,
          builder: (context, params) => NotificationsSettingsWidget(),
        ),
        FFRoute(
          name: PrivacyPolicyWidget.routeName,
          path: PrivacyPolicyWidget.routePath,
          builder: (context, params) => PrivacyPolicyWidget(),
        ),
        FFRoute(
          name: TutorialPROFILEWidget.routeName,
          path: TutorialPROFILEWidget.routePath,
          builder: (context, params) => TutorialPROFILEWidget(),
=======
          builder: (context, _) => HomePageWidget(),
>>>>>>> Stashed changes
=======
          builder: (context, _) => HomePageWidget(),
>>>>>>> Stashed changes
        ),
        FFRoute(
          name: HomePageWidget.routeName,
          path: HomePageWidget.routePath,
          builder: (context, params) => HomePageWidget(),
        ),
        FFRoute(
<<<<<<< Updated upstream
<<<<<<< Updated upstream
          name: HomePageAltWidget.routeName,
          path: HomePageAltWidget.routePath,
          builder: (context, params) => HomePageAltWidget(),
        ),
        FFRoute(
          name: HomePageAlt1Widget.routeName,
          path: HomePageAlt1Widget.routePath,
          builder: (context, params) => HomePageAlt1Widget(),
        ),
        FFRoute(
          name: BudgetDELETEWidget.routeName,
          path: BudgetDELETEWidget.routePath,
          builder: (context, params) => BudgetDELETEWidget(
            budgetList: params.getParam(
              'budgetList',
              ParamType.DocumentReference,
              isList: false,
              collectionNamePath: ['budgets'],
            ),
          ),
        ),
        FFRoute(
          name: ProfilepageWidget.routeName,
          path: ProfilepageWidget.routePath,
          builder: (context, params) => ProfilepageWidget(),
=======
=======
>>>>>>> Stashed changes
          name: QuizPageWidget.routeName,
          path: QuizPageWidget.routePath,
          builder: (context, params) => QuizPageWidget(),
        ),
        FFRoute(
          name: SignupWidget.routeName,
          path: SignupWidget.routePath,
          builder: (context, params) => SignupWidget(),
        ),
        FFRoute(
          name: LoginWidget.routeName,
          path: LoginWidget.routePath,
          builder: (context, params) => LoginWidget(),
        ),
        FFRoute(
          name: ProfileWidget.routeName,
          path: ProfileWidget.routePath,
          builder: (context, params) => ProfileWidget(),
        ),
        FFRoute(
          name: MainPageWidget.routeName,
          path: MainPageWidget.routePath,
          builder: (context, params) => MainPageWidget(),
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
        )
      ].map((r) => r.toRoute(appStateNotifier)).toList(),
    );

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
  void goNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : goNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

  void pushNamedAuth(
    String name,
    bool mounted, {
    Map<String, String> pathParameters = const <String, String>{},
    Map<String, String> queryParameters = const <String, String>{},
    Object? extra,
    bool ignoreRedirect = false,
  }) =>
      !mounted || GoRouter.of(this).shouldRedirect(ignoreRedirect)
          ? null
          : pushNamed(
              name,
              pathParameters: pathParameters,
              queryParameters: queryParameters,
              extra: extra,
            );

=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

<<<<<<< Updated upstream
<<<<<<< Updated upstream
extension GoRouterExtensions on GoRouter {
  AppStateNotifier get appState => AppStateNotifier.instance;
  void prepareAuthEvent([bool ignoreRedirect = false]) =>
      appState.hasRedirect() && !ignoreRedirect
          ? null
          : appState.updateNotifyOnAuthChange(false);
  bool shouldRedirect(bool ignoreRedirect) =>
      !ignoreRedirect && appState.hasRedirect();
  void clearRedirectLocation() => appState.clearRedirectLocation();
  void setRedirectLocationIfUnset(String location) =>
      appState.updateNotifyOnAuthChange(false);
}

=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};
  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);
  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));
  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;
  bool get hasFutures => state.allParams.entries.any(isAsyncParam);
  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
<<<<<<< Updated upstream
<<<<<<< Updated upstream
    List<String>? collectionNamePath,
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
<<<<<<< Updated upstream
<<<<<<< Updated upstream
      collectionNamePath: collectionNamePath,
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
<<<<<<< Updated upstream
<<<<<<< Updated upstream
        redirect: (context, state) {
          if (appStateNotifier.shouldRedirect) {
            final redirectLocation = appStateNotifier.getRedirectLocation();
            appStateNotifier.clearRedirectLocation();
            return redirectLocation;
          }

          if (requireAuth && !appStateNotifier.loggedIn) {
            appStateNotifier.setRedirectLocationIfUnset(state.uri.toString());
            return '/loginPage';
          }
          return null;
        },
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
<<<<<<< Updated upstream
<<<<<<< Updated upstream
          final child = appStateNotifier.loading
              ? Container(
                  color: Colors.transparent,
                  child: Center(
                    child: Image.asset(
                      'assets/images/Medical_ScheduleApp_0.0.png',
                      width: MediaQuery.sizeOf(context).width * 1.0,
                      fit: BoxFit.fitWidth,
                    ),
                  ),
                )
              : page;
=======
          final child = page;
>>>>>>> Stashed changes
=======
          final child = page;
>>>>>>> Stashed changes

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() => TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);
  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
