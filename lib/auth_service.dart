import 'api_client.dart';

class AuthService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>> login(String email, String password) {
    return _api.post("/v1/auth/login", {
      "email": email.trim(),
      "password": password,
    });
  }

  Future<Map<String, dynamic>> registerUser(String name, String email, String password) {
    return _api.post("/v1/auth/register", {
      "name": name.trim(),
      "email": email.trim(),
      "password": password,
      "role": "user",
    });
  }

  Future<Map<String, dynamic>> registerCompany(
      String name,
      String email,
      String password,
      String companyName,
      ) {
    return _api.post("/v1/auth/register", {
      "name": name.trim(),
      "email": email.trim(),
      "password": password,
      "role": "company",
      "company_name": companyName.trim(),
    });
  }

  Future<Map<String, dynamic>> me() => _api.get("/v1/auth/me");
}