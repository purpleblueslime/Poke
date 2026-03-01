import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart'; // we mostly use XFile

const url = 'https://pokebyslime.vercel.app';

g(p, [token]) async {
  dynamic re = await http.get(
    Uri.parse('$url/api$p'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  return re;
}

p(p, body, [token]) async {
  dynamic re = await http.post(
    Uri.parse('$url/api$p'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  return re;
}

Future<Map<dynamic, dynamic>> pMultipart({
  dynamic p,
  Map<dynamic, dynamic> data = const {},
  XFile? file,
  dynamic name = 'file',
  dynamic mime,
  dynamic token,
}) async {
  dynamic request = http.MultipartRequest('POST', Uri.parse('$url/api$p'))
    ..headers['Authorization'] = 'Bearer $token';

  data.forEach((key, value) {
    request.fields[key] = value.toString();
  });

  if (file != null) {
    dynamic contentType =
        mime != null
            ? MediaType.parse(mime)
            : MediaType('application', 'octet-stream');

    request.files.add(
      await http.MultipartFile.fromPath(
        name,
        file.path,
        contentType: contentType,
      ),
    );
  }

  dynamic re = await request.send();
  dynamic body = await re.stream.bytesToString();

  Map<dynamic, dynamic> map;
  try {
    map = json.decode(body);
  } catch (e) {
    map = {};
  }

  return {'statusCode': re.statusCode, 'data': map};
}

apiUrl(p) {
  return '$url/api$p';
}

imgUrl(uid) {
  return 'https://apunwzrlgvqzzhzenzqa.supabase.co/storage/v1/object/public/users/$uid.gif';
}
