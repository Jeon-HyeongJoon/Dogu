import 'package:flutter_web_plugins/url_strategy.dart';

/// Web: use clean path URLs (no `#`) so tabs and product detail are deep-linkable.
void configureUrlStrategy() => usePathUrlStrategy();
