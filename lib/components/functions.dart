import 'package:intl/intl.dart';

timeify(DateTime utcDate) {
  final now = DateTime.now().toUtc();
  final difference = now.difference(utcDate);

  if (difference.inDays > 0) {
    return '1d'; // max
  }
  if (difference.inHours > 0) {
    return '${difference.inHours}h';
  }
  if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m';
  }
  return 'now';
}

comify(int number) {
  return number.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match match) => '${match[1]},',
  );
}

Map<dynamic, dynamic> niceDate(createdAt) {
  final date = DateTime.parse(createdAt).toLocal();
  final day = DateFormat('EEE').format(date);
  final time = DateFormat('HH:mm').format(date);

  return {'day': day, 'time': time};
}
