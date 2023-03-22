/// A pair of values.
class Pair<E, F> {
  Pair(this.left, this.right);

  final E left;
  final F right;

  @override
  String toString() => 'Pair[$left, $right]';
}