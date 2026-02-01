import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const String botToken = '8177858171:AAFfhzgtMABBQwdCelEka5k5YYi-5J5_T0';
  const String chatId = '@mazadi_storage';

  // Test 1: Get Bot Info
  print('🤖 Testing Bot Info...');
  final botInfoResponse = await http.get(
    Uri.parse('https://api.telegram.org/bot$botToken/getMe'),
  );
  print('Bot Info Response: ${botInfoResponse.statusCode}');
  print(json.decode(botInfoResponse.body));
  print('---\n');

  // Test 2: Get Chat Info
  print('📢 Testing Chat Info...');
  final chatInfoResponse = await http.get(
    Uri.parse('https://api.telegram.org/bot$botToken/getChat?chat_id=$chatId'),
  );
  print('Chat Info Response: ${chatInfoResponse.statusCode}');
  print(json.decode(chatInfoResponse.body));
  print('---\n');

  // Test 3: Send Test Message
  print('💬 Testing Send Message...');
  final messageResponse = await http.post(
    Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'chat_id': chatId,
      'text': 'اختبار الاتصال - Test Connection',
    }),
  );
  print('Send Message Response: ${messageResponse.statusCode}');
  print(json.decode(messageResponse.body));
}
