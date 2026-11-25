import 'package:flutter/foundation.dart';
import 'package:nicmo/domain/transit/transit_network.dart';

/// Line chosen in the side menu or the lines list; the map then shows only
/// that line. `null` shows the whole network.
final ValueNotifier<String?> lineFilter = ValueNotifier<String?>(null);

/// Kind of transport shown on the map (metro, cable, feeder buses...);
/// `null` shows all of them.
final ValueNotifier<LineGroup?> groupFilter = ValueNotifier<LineGroup?>(null);
