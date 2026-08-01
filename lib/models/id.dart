import 'dart:math';

final _random = Random();

/// A client-generated identifier, used as the Firestore document ID.
///
/// Generated locally rather than by `collection.doc()` so a newly created item
/// has its final ID before the write is acknowledged — which matters offline,
/// where the write may sit in the queue for a long time.
/// Upper bound for the random suffix.
///
/// Deliberately not `1 << 32`: on web an int is a JS double and `<<` is a
/// 32-bit operation, so `1 << 32` wraps to 0 and `nextInt(0)` throws
/// "max must be in range 0 < max <= 2^32". 2^30 is the largest power of two
/// that is safe on both web and the VM, and a billion values alongside a
/// microsecond timestamp is ample.
const _saltRange = 1 << 30;

String newId() {
  final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final salt = _random.nextInt(_saltRange).toRadixString(36).padLeft(6, '0');
  return '$stamp-$salt';
}
