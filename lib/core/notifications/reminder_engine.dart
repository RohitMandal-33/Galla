import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../data/galla_repository.dart';

class ReminderEngine {
  ReminderEngine(this._repo);
  final GallaRepository _repo;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<void> evaluate() async {
    await init();
    final settings = await _repo.loadSettings();
    final summary = await _repo.summaryFor(DateTime.now());
    if (settings.notifyLowCash &&
        settings.lowCashThresholdMinor > 0 &&
        summary.cashOnHandMinor < settings.lowCashThresholdMinor) {
      await _show(
        1,
        'Galla',
        settings.locale == 'ne'
            ? 'नगद सामान्यभन्दा कम छ'
            : 'Cash on hand is lower than usual today',
      );
    }
    if (!settings.notifyPaymentDue) return;
    final parties = await _repo.partiesWithBalances();
    var shown = 0;
    for (final p in parties.where((p) => p.remindEnabled && p.balanceMinor != 0)) {
      if (shown >= 2) break;
      final last = p.lastRemindedAt;
      if (last != null && DateTime.now().difference(last).inDays < p.remindEveryDays) {
        continue;
      }
      final theyOwe = p.balanceMinor > 0;
      await _show(
        10 + shown,
        p.name,
        theyOwe
            ? 'They still owe you. Open Galla to follow up.'
            : 'You still owe them. Open Galla when you are ready to pay.',
      );
      await _repo.markReminded(p.id);
      shown++;
    }
  }

  Future<void> _show(int id, String title, String body) {
    return _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'galla_calm',
          'Galla reminders',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
