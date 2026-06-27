import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

const url = 'https://pokebyslime.vercel.app';

g(p, [token]) async {
  try {
    return await http
        .get(
          Uri.parse('$url/api$p'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        )
        .timeout(Duration(seconds: 20));
  } catch (_) {
    await Future.delayed(Duration(seconds: 5));

    try {
      return await http
          .get(
            Uri.parse('$url/api$p'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: 20));
    } catch (_) {
      return http.Response('', 418);
    }
  }
}

p(p, body, [token]) async {
  try {
    return await http
        .post(
          Uri.parse('$url/api$p'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
  } catch (_) {
    await Future.delayed(Duration(seconds: 5));

    try {
      return await http
          .post(
            Uri.parse('$url/api$p'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(Duration(seconds: 20));
    } catch (_) {
      return http.Response('', 418);
    }
  }
}

pMultipart({
  dynamic p,
  dynamic data = const {},
  dynamic file,
  dynamic name = 'file',
  dynamic mime,
  dynamic token,
}) async {
  Future<Map<dynamic, dynamic>> send() async {
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

    dynamic re = await request.send().timeout(Duration(minutes: 5));
    dynamic stream = await re.stream.bytesToString();

    return {
      'statusCode': re.statusCode,
      'data': jsonDecode(stream.isEmpty ? '{}' : stream),
    };
  }

  try {
    return await send();
  } catch (_) {
    await Future.delayed(Duration(seconds: 5));

    try {
      return await send();
    } catch (_) {
      return {'statusCode': 418};
    }
  }
}

apiUrl(p) {
  return '$url/api$p';
}

imgUrl(uid, updatedAt) {
  return 'https://apunwzrlgvqzzhzenzqa.supabase.co/storage/v1/object/public/users/$uid.gif?updatedAt=$updatedAt';
}
