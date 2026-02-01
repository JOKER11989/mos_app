import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  // التوكن المصحح
  const String botToken = '8177858171:AAFfhZrtMAAB0OwdCgLEka5ksYYi-5J5_T0';
  const String chatId = '@mazadi_storage';

  print('🔍 جاري فحص الاتصال...');

  // 1. فحص معلومات البوت (للتأكد من التوكن)
  print('\n1️⃣ فحص التوكن (getMe):');
  final botResponse = await http.get(
    Uri.parse('https://api.telegram.org/bot$botToken/getMe'),
  );
  print('Status: ${botResponse.statusCode}');
  print('Body: ${botResponse.body}');

  if (botResponse.statusCode != 200) {
    print('❌ التوكن غير صحيح! تأكد من نسخه بدقة.');
    return;
  }

  // 2. فحص معلومات القناة (للتأكد من الاسم وصلاحيات البوت)
  print('\n2️⃣ فحص القناة (getChat):');
  final chatResponse = await http.get(
    Uri.parse('https://api.telegram.org/bot$botToken/getChat?chat_id=$chatId'),
  );
  print('Status: ${chatResponse.statusCode}');
  print('Body: ${chatResponse.body}');

  if (chatResponse.statusCode != 200) {
    print('❌ البوت لا يمكنه الوصول للقناة. قد تكون:');
    print(' - اسم القناة خاطئ');
    print(' - البوت ليس أدمن في القناة');
    print(' - القناة خاصة والبوت يحتاج للانضمام أولاً');
    return;
  }

  // 3. محاولة إرسال رسالة نصية بسيطة
  print('\n3️⃣ محاولة إرسال رسالة (sendMessage):');
  final sendResponse = await http.post(
    Uri.parse('https://api.telegram.org/bot$botToken/sendMessage'),
    body: {'chat_id': chatId, 'text': 'تجربة اتصال من تطبيق المزادات 🚀'},
  );
  print('Status: ${sendResponse.statusCode}');
  print('Body: ${sendResponse.body}');

  if (sendResponse.statusCode == 200) {
    print('\n✅ كل شيء يعمل بنجاح!');
  } else {
    print('\n❌ فشل الإرسال رغم صحة التوكن والقناة.');
  }
}
