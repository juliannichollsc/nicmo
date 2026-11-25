/// Product name. A brand: it is not translated.
const String kAppName = 'Nicmo';

/// Application id on Android and bundle id on iOS.
const String kAppPackage = 'com.jnicholls.nicmo';

/// Choosing other cities (cities screen, city chip and item in the side
/// menu, other cities in the welcome step). Off while the app covers only
/// Medellín and the Valle de Aburrá; the per-city data, cache and planner
/// work the same either way.
const bool kMultiCityEnabled = false;

/// City preselected (and, without [kMultiCityEnabled], the only one offered)
/// in the welcome step: Medellín covers the whole Valle de Aburrá.
const String kDefaultCityId = 'medellin';
