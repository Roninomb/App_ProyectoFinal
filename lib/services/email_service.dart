import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> enviarReportePorEmail({
  required String nombre,
  required String email,
  required String fuerza,
  required String pulsos,
  required String ritmo,
}) async {
  const serviceId = 'service_5unht7r';
  const templateId = 'template_9gra318';
  const publicKey = '2YN7Kz4kL07HaNGBM';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final response = await http.post(
    url,
    headers: {
      'origin': 'http://localhost',
      'Content-Type': 'application/json',
    },
    body: json.encode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'email': email,
        'nombre': nombre,
        'fuerza': fuerza,
        'pulsos': pulsos,
        'ritmo': ritmo,
      }
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Error al enviar email: ${response.body}');
  }
}
