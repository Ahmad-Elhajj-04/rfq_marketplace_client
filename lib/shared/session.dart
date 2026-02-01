class Session {
  static int? userId;
  static String? role; // "user" | "company"
  static String? name;

  static bool get isLoggedIn => userId != null && role != null;

  static void clear() {
    userId = null;
    role = null;
    name = null;
  }
}