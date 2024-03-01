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
  external dynamic entries();

  @JS('prototype.keys')
  external dynamic keys();

  @JS('prototype.values')
  external dynamic values();

  external int get size;

  external factory JSMap();
}

extension Interop<K, V> on JSMap<K, V> {
  Map<K, V> toDartMap() {
    final returnMap = <K, V>{};

    final jsKeys = keys();
    final jsValues = values();

    var nextKey = jsKeys.next();
    var nextValue = jsValues.next();

    while (!nextKey.done) {
      returnMap[nextKey.value] = nextValue.value;
      nextKey = jsKeys.next();
      nextValue = jsValues.next();
    }

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
  dynamic iterator,
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
  dynamic iterator,
  bool Function(V value) mapper,
) {
  var result = iterator.next();
  while (!result.done) {
    final earlyBreak = mapper(result.value);
    if (earlyBreak) break;
    result = iterator.next();
  }
}
