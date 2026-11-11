import 'package:flutter_test/flutter_test.dart';
import 'package:project_3/data/rates_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes.dart';

void main() {
  Future<(RatesCache, SharedPreferences)> cacheWith(
    Map<String, Object> values,
  ) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return (RatesCache(prefs), prefs);
  }

  test('is empty on first launch', () async {
    final (cache, _) = await cacheWith({});
    expect(cache.load(), isNull);
  });

  test('returns what was saved', () async {
    final (cache, _) = await cacheWith({});
    final saved = snapshot();
    await cache.save(saved);

    final loaded = cache.load()!;
    expect(loaded.perUsd, saved.perUsd);
    expect(loaded.updatedAt, saved.updatedAt);
    expect(loaded.fetchedAt, saved.fetchedAt);
  });

  test('a newer save replaces the older one', () async {
    final (cache, _) = await cacheWith({});
    await cache.save(snapshot(kzt: 440));
    await cache.save(snapshot(kzt: 455));
    expect(rateOf(cache.load()!, .kzt), 455);
  });

  test('drops an entry that is not JSON', () async {
    final (cache, prefs) = await cacheWith({RatesCache.key: '{oops'});
    expect(cache.load(), isNull);
    expect(prefs.containsKey(RatesCache.key), isFalse);
  });

  test('drops an entry with the wrong shape', () async {
    final (cache, prefs) = await cacheWith({
      RatesCache.key: '{"rates":{"USD":1},"updatedAt":0,"fetchedAt":0}',
    });
    expect(cache.load(), isNull);
    expect(prefs.containsKey(RatesCache.key), isFalse);
  });
}
