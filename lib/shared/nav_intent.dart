class NavIntent {
  // Example:
  // { "action": "submit-quotation", "request": <Map> }
  static Map<String, dynamic>? pending;

  static void set(Map<String, dynamic> value) {
    pending = value;
  }

  static Map<String, dynamic>? take() {
    final v = pending;
    pending = null;
    return v;
  }
}