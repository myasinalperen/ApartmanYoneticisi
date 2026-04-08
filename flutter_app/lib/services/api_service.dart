import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  // Web'de çalışırken localhost:8000, mobilde cihazın IP adresi kullanılır
  static const String baseUrl = 'http://localhost:8000';

  static Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'));
    if (res.statusCode >= 400) throw Exception('API hatası: ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<List<dynamic>> _getList(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'));
    if (res.statusCode >= 400) throw Exception('API hatası: ${res.statusCode}');
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) throw Exception(utf8.decode(res.bodyBytes));
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final res = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) throw Exception(utf8.decode(res.bodyBytes));
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<void> _delete(String path) async {
    final res = await http.delete(Uri.parse('$baseUrl$path'));
    if (res.statusCode >= 400) throw Exception('Silme hatası: ${res.statusCode}');
  }

  // Dashboard
  static Future<DashboardStats> getDashboard() async {
    final data = await _get('/dashboard');
    return DashboardStats.fromJson(data);
  }

  static Future<String> seedDatabase() async {
    final res = await http.post(Uri.parse('$baseUrl/seed'));
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    return data['message'] ?? '';
  }

  // Daireler
  static Future<List<Daire>> getDaireler() async {
    final list = await _getList('/daireler/');
    return list.map((e) => Daire.fromJson(e)).toList();
  }

  static Future<Daire> createDaire(Map<String, dynamic> data) async {
    return Daire.fromJson(await _post('/daireler/', data));
  }

  static Future<Daire> updateDaire(int id, Map<String, dynamic> data) async {
    return Daire.fromJson(await _put('/daireler/$id', data));
  }

  static Future<void> deleteDaire(int id) => _delete('/daireler/$id');

  // Sakinler
  static Future<List<Sakin>> getSakinler() async {
    final list = await _getList('/sakinler/');
    return list.map((e) => Sakin.fromJson(e)).toList();
  }

  static Future<Sakin> createSakin(Map<String, dynamic> data) async {
    return Sakin.fromJson(await _post('/sakinler/', data));
  }

  static Future<Sakin> updateSakin(int id, Map<String, dynamic> data) async {
    return Sakin.fromJson(await _put('/sakinler/$id', data));
  }

  static Future<void> deleteSakin(int id) => _delete('/sakinler/$id');

  // Aidatlar
  static Future<List<Aidat>> getAidatlar({int? ay, int? yil}) async {
    String q = '';
    if (ay != null || yil != null) {
      q = '?';
      if (ay != null) q += 'ay=$ay&';
      if (yil != null) q += 'yil=$yil';
    }
    final list = await _getList('/aidatlar/$q');
    return list.map((e) => Aidat.fromJson(e)).toList();
  }

  static Future<Aidat> createAidat(Map<String, dynamic> data) async {
    return Aidat.fromJson(await _post('/aidatlar/', data));
  }

  static Future<Aidat> updateAidat(int id, Map<String, dynamic> data) async {
    return Aidat.fromJson(await _put('/aidatlar/$id', data));
  }

  static Future<void> deleteAidat(int id) => _delete('/aidatlar/$id');

  static Future<Map<String, dynamic>> topluOlustur(int yil, int ay, double tutar) async {
    final res = await http.post(
        Uri.parse('$baseUrl/aidatlar/toplu-olustur?yil=$yil&ay=$ay&tutar=$tutar'));
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  // Faturalar
  static Future<List<Fatura>> getFaturalar({int? ay, int? yil}) async {
    String q = '';
    if (ay != null || yil != null) {
      q = '?';
      if (ay != null) q += 'ay=$ay&';
      if (yil != null) q += 'yil=$yil';
    }
    final list = await _getList('/faturalar/$q');
    return list.map((e) => Fatura.fromJson(e)).toList();
  }

  static Future<Fatura> createFatura(Map<String, dynamic> data) async {
    return Fatura.fromJson(await _post('/faturalar/', data));
  }

  static Future<Fatura> updateFatura(int id, Map<String, dynamic> data) async {
    return Fatura.fromJson(await _put('/faturalar/$id', data));
  }

  static Future<void> deleteFatura(int id) => _delete('/faturalar/$id');

  // Talepler
  static Future<List<Talep>> getTalepler({String? durum}) async {
    final q = durum != null ? '?durum=$durum' : '';
    final list = await _getList('/talepler/$q');
    return list.map((e) => Talep.fromJson(e)).toList();
  }

  static Future<Talep> createTalep(Map<String, dynamic> data) async {
    return Talep.fromJson(await _post('/talepler/', data));
  }

  static Future<Talep> updateTalep(int id, Map<String, dynamic> data) async {
    return Talep.fromJson(await _put('/talepler/$id', data));
  }

  static Future<void> deleteTalep(int id) => _delete('/talepler/$id');

  // Sikayetler
  static Future<List<Sikayet>> getSikayetler({String? durum}) async {
    final q = durum != null ? '?durum=$durum' : '';
    final list = await _getList('/sikayetler/$q');
    return list.map((e) => Sikayet.fromJson(e)).toList();
  }

  static Future<Sikayet> createSikayet(Map<String, dynamic> data) async {
    return Sikayet.fromJson(await _post('/sikayetler/', data));
  }

  static Future<Sikayet> updateSikayet(int id, Map<String, dynamic> data) async {
    return Sikayet.fromJson(await _put('/sikayetler/$id', data));
  }

  static Future<void> deleteSikayet(int id) => _delete('/sikayetler/$id');

  // Oylamalar
  static Future<List<Oylama>> getOylamalar() async {
    final list = await _getList('/oylamalar/');
    return list.map((e) => Oylama.fromJson(e)).toList();
  }

  static Future<Oylama> createOylama(Map<String, dynamic> data) async {
    return Oylama.fromJson(await _post('/oylamalar/', data));
  }

  static Future<Oylama> updateOylama(int id, Map<String, dynamic> data) async {
    return Oylama.fromJson(await _put('/oylamalar/$id', data));
  }

  static Future<void> deleteOylama(int id) => _delete('/oylamalar/$id');

  static Future<void> oyVer(int oylamaId, int daireId, int secenekId) async {
    await _post('/oylamalar/oy-ver', {
      'oylama_id': oylamaId,
      'daire_id': daireId,
      'secenek_id': secenekId,
    });
  }

  // Duyurular
  static Future<List<Duyuru>> getDuyurular() async {
    final list = await _getList('/duyurular/');
    return list.map((e) => Duyuru.fromJson(e)).toList();
  }

  static Future<Duyuru> createDuyuru(Map<String, dynamic> data) async {
    return Duyuru.fromJson(await _post('/duyurular/', data));
  }

  static Future<Duyuru> updateDuyuru(int id, Map<String, dynamic> data) async {
    return Duyuru.fromJson(await _put('/duyurular/$id', data));
  }

  static Future<void> deleteDuyuru(int id) => _delete('/duyurular/$id');

  // Giderler
  static Future<List<Gider>> getGiderler() async {
    final list = await _getList('/giderler/');
    return list.map((e) => Gider.fromJson(e)).toList();
  }

  static Future<Gider> createGider(Map<String, dynamic> data) async {
    return Gider.fromJson(await _post('/giderler/', data));
  }

  static Future<Gider> updateGider(int id, Map<String, dynamic> data) async {
    return Gider.fromJson(await _put('/giderler/$id', data));
  }

  static Future<void> deleteGider(int id) => _delete('/giderler/$id');

  // Toplantilar
  static Future<List<Toplanti>> getToplantilar() async {
    final list = await _getList('/toplantilar/');
    return list.map((e) => Toplanti.fromJson(e)).toList();
  }

  static Future<Toplanti> createToplanti(Map<String, dynamic> data) async {
    return Toplanti.fromJson(await _post('/toplantilar/', data));
  }

  static Future<Toplanti> updateToplanti(int id, Map<String, dynamic> data) async {
    return Toplanti.fromJson(await _put('/toplantilar/$id', data));
  }

  static Future<void> deleteToplanti(int id) => _delete('/toplantilar/$id');
}
