import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../providers/user_provider.dart';

Future<void> enviarReportePorEmail(WidgetRef ref) async {
  final nombre = ref.read(nombreProvider);
  final email = ref.read(emailProvider);
  final fuerza = ref.read(fuerzaProvider);
  final pulsos = ref.read(pulsosProvider);
  final ritmo = ref.read(ritmoProvider);

  if (email.trim().isEmpty) {
    throw Exception('El campo de email está vacío');
  }

  const serviceId = 'service_5unht7r';
  const templateId = 'template_9gra318';
  const publicKey = '2YN7Kz4kL07HaNGBM';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
  final body = {
    'service_id': serviceId,
    'template_id': templateId,
    'user_id': publicKey,
    'template_params': {
      'to_email': email,            // esto debe coincidir con el nombre del campo {{to_email}} en el template
      'nombre': nombre,
      'fuerza': fuerza.toStringAsFixed(2),
      'pulsos': pulsos.toString(),
      'ritmo': ritmo ? 'Correcto' : 'Incorrecto',
    }
  };

  print('Enviando email a: $email');
  final response = await http.post(
    url,
    headers: {
      'origin': 'http://localhost',
      'Content-Type': 'application/json',
    },
    body: json.encode(body),
  );

  if (response.statusCode != 200) {
    print('Error status: ${response.statusCode}');
    print('Respuesta: ${response.body}');
    throw Exception('Error al enviar email: ${response.body}');
  }

  print('Email enviado exitosamente a $email');
}
