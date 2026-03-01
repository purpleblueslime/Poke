import 'package:intl/intl.dart';

timeify(DateTime utcDate) {
  dynamic now = DateTime.now().toUtc();
  dynamic dif = now.difference(utcDate);

  if (dif.inDays > 0) {
    return '1d'; // max
  }
  if (dif.inHours > 0) {
    return '${dif.inHours}h';
  }
  if (dif.inMinutes > 0) {
    return '${dif.inMinutes}m';
  }
  return 'now';
}

comify(dynamic number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match match) => '${match[1]},',
  );
}

Map<dynamic, dynamic> niceDate(createdAt) {
  dynamic date = DateTime.parse(createdAt).toLocal();
  dynamic day = DateFormat('EEE').format(date);
  dynamic time = DateFormat('HH:mm').format(date);

  return {'day': day, 'time': time};
}
