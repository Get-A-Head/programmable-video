@JS()
library js_map;

import 'package:js/js.dart';

@JS('Map')
class JSMap<K, V> {
  /// Returns an [IteratorJS] of all the key value pairs in the [Map]
  ///
  /// The [IteratorJS] returns the key value pairs as a [List<dynamic>].
  /// The [List] always contains two elements. The first is the key and the second is the value.
  @JS('prototype.entries')
  external IteratorJS<List<dynamic>> entries();

  @JS('prototype.keys')
  external IteratorJS<K> keys();

  @JS('prototype.values')
  external IteratorJS<V> values();

  @JS('prototype.forEach')
  external void forEach(void Function(V value, K key, JSMap<K, V> map) callback);

  external int get size;

  external factory JSMap();
}

extension Interop<K, V> on JSMap<K, V> {
  Map<K, V> toDartMap() {
    final returnMap = <K, V>{};

    forEach((value, key, map) {
      returnMap[key] = value;
    });

    return returnMap;
  }
}

@JS()
class IteratorJS<T> {
  external IteratorValue<T> next();

  external factory IteratorJS();
}

@JS()
class IteratorValue<T> {
  external T get value;
  external bool get done;

  external factory IteratorValue();
}

List<T> iteratorToList<T, V>(
  IteratorJS<V> iterator,
  T Function(V value) mapper,
) {
  final list = <T>[];
  var result = iterator.next();
  while (!result.done) {
    list.add(
      mapper(result.value),
    );

    result = iterator.next();
  }
  return list;
}

void iteratorForEach<V>(
  IteratorJS<V> iterator,
  bool Function(V value) mapper,
) {
  var result = iterator.next();
  while (!result.done) {
    final earlyBreak = mapper(result.value);
    if (earlyBreak) break;
    result = iterator.next();
  }
}
