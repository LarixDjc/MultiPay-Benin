import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants.dart';

class ApiService {
  // Récupérer le token stocké
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }
  static Future<Map<String, dynamic>> modifierDelaiActivite(Map<String, dynamic> data) async {
  try {
    final headers = await headersAvecToken();
    final response = await http.patch(
      Uri.parse(Constants.delaiActiviteUrl),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'message': 'Erreur réseau'};
  }
}

  // Sauvegarder le token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Supprimer le token (déconnexion)
  static Future<void> supprimerToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  // Headers avec token
  static Future<Map<String, String>> headersAvecToken() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'ngrok-skip-browser-warning': 'true',
    };
  }

  // ---- AUTH ----
  static Future<Map<String, dynamic>> inscrire(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(Constants.inscriptionUrl),
        headers: {'Content-Type': 'application/json' , 'ngrok-skip-browser-warning': 'true',},
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur de connexion au serveur'};
    }
  }
 static Future<Map<String, dynamic>> consulterComptesOperateurs() async {
  try {
    final headers = await headersAvecToken();
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/compte/operateurs'),
      headers: headers,
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'message': 'Erreur réseau'};
  }
}

  static Future<Map<String, dynamic>> configurerCompteOperateur(List comptes) async {
  try {
    final headers = await headersAvecToken();
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/compte/operateurs'),
      headers: headers,
      body: jsonEncode({'comptes': comptes}),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'message': 'Erreur réseau'};
  }
}

  static Future<Map<String, dynamic>> connecter(String email, String motDePasse) async {
  try {
    print('URL: ${Constants.connexionUrl}');
    print('Email: $email');
    final response = await http.post(
      Uri.parse(Constants.connexionUrl),
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
      body: jsonEncode({'email': email, 'motDePasse': motDePasse}),
    );
    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');
    final data = jsonDecode(response.body);
    if (data['token'] != null) {
      await saveToken(data['token']);
    }
    return data;
  } catch (e) {
    print('ERREUR: $e');
    return {'message': 'Erreur de connexion au serveur'};
  }
}

  // ---- COMPTE ----
  static Future<Map<String, dynamic>> consulterSolde() async {
    try {
      final headers = await headersAvecToken();
      final response = await http.get(
        Uri.parse(Constants.soldeUrl),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
  print('ERREUR CONNEXION: $e');
  return {'message': 'Erreur de connexion au serveur'};
}
  }
 static Future<Map<String, dynamic>> consulterStats() async {
  try {
    final headers = await headersAvecToken();
    final response = await http.get(
      Uri.parse(Constants.statsUrl),
      headers: headers,
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'message': 'Erreur réseau'};
  }
}
  // ---- TRANSACTIONS ----
  static Future<Map<String, dynamic>> effectuerDepot(Map<String, dynamic> data) async {
    try {
      final headers = await headersAvecToken();
      final response = await http.post(
        Uri.parse(Constants.depotUrl),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  static Future<Map<String, dynamic>> effectuerRetrait(Map<String, dynamic> data) async {
    try {
      final headers = await headersAvecToken();
      final response = await http.post(
        Uri.parse(Constants.retraitUrl),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  static Future<Map<String, dynamic>> consulterTransactions() async {
    try {
      final headers = await headersAvecToken();
      final response = await http.get(
        Uri.parse(Constants.transactionsUrl),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  // ---- HISTORIQUE ----
  static Future<Map<String, dynamic>> consulterHistorique({String? type}) async {
    try {
      final headers = await headersAvecToken();
      final url = type != null
          ? '${Constants.historiqueUrl}/$type'
          : Constants.historiqueUrl;
      final response = await http.get(Uri.parse(url), headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  // ---- VENDRE ----
  static Future<Map<String, dynamic>> vendreCredit(Map<String, dynamic> data) async {
    try {
      final headers = await headersAvecToken();
      final response = await http.post(
        Uri.parse(Constants.vendreCreditUrl),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  static Future<Map<String, dynamic>> vendreForfait(Map<String, dynamic> data) async {
    try {
      final headers = await headersAvecToken();
      final response = await http.post(
        Uri.parse(Constants.vendreForfaitUrl),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  static Future<Map<String, dynamic>> listerForfaits({String? type}) async {
    try {
      final headers = await headersAvecToken();
      final url = type != null
          ? '${Constants.forfaitsUrl}?type=$type'
          : Constants.forfaitsUrl;
      final response = await http.get(Uri.parse(url), headers: headers);
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  // ---- AUTRES SERVICES ----
  static Future<Map<String, dynamic>> payerService(Map<String, dynamic> data) async {
    try {
      final headers = await headersAvecToken();
      final response = await http.post(
        Uri.parse(Constants.payerServiceUrl),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  // ---- NOTIFICATIONS ----
  static Future<Map<String, dynamic>> consulterNotifications() async {
    try {
      final headers = await headersAvecToken();
      final response = await http.get(
        Uri.parse(Constants.notificationsUrl),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  // ---- PARAMÈTRES ----
  static Future<Map<String, dynamic>> consulterProfil() async {
    try {
      final headers = await headersAvecToken();
      final response = await http.get(
        Uri.parse(Constants.profilUrl),
        headers: headers,
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  static Future<Map<String, dynamic>> modifierProfil(Map<String, dynamic> data) async {
    try {
      final headers = await headersAvecToken();
      final response = await http.patch(
        Uri.parse(Constants.profilUrl),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  static Future<Map<String, dynamic>> changerMotDePasse(Map<String, dynamic> data) async {
    try {
      final headers = await headersAvecToken();
      final response = await http.patch(
        Uri.parse(Constants.motDePasseUrl),
        headers: headers,
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'message': 'Erreur réseau'};
    }
  }

  static Future<Map<String, dynamic>> consulterSeuils() async {
  try {
    final headers = await headersAvecToken();
    final response = await http.get(
      Uri.parse(Constants.seuilsUrl),
      headers: headers,
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'message': 'Erreur réseau'};
  }
}

static Future<Map<String, dynamic>> modifierSeuil(Map<String, dynamic> data) async {
  try {
    final headers = await headersAvecToken();
    final response = await http.post(
      Uri.parse(Constants.seuilsUrl),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'message': 'Erreur réseau'};
  }
}

static Future<Map<String, dynamic>> consulterFrais() async {
  try {
    final headers = await headersAvecToken();
    final response = await http.get(
      Uri.parse(Constants.fraisUrl),
      headers: headers,
    );
    return jsonDecode(response.body);
  } catch (e) {
    return {'message': 'Erreur réseau'};
  }
}

}