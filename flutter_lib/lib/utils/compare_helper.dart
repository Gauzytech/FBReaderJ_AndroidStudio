
class CompareHelper {

  static bool equals(Object o1, Object o2) {
    return o1 == o2;
  }

  static int createHashCode(Object? o) {
    return o != null ? o.hashCode : 0;
  }
}