import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../user_provider.dart';
import 'poke_video.dart';
import '../pages/open_gallery.dart';
import './call_api.dart';

class Gallery extends StatelessWidget {
  final dynamic uid;

  const Gallery({super.key, this.uid});

  @override
  Widget build(BuildContext context) {
    dynamic userProvider = Provider.of<UserPro>(context);
    dynamic user = userProvider.user;
    dynamic w =
        (MediaQuery.of(context).size.width / 4) - 2; // dynamic dep on device

    // collect and filter pokes
    List<dynamic> justGallery = user['justGallery'];
    List<dynamic> allPokes = [];

    for (dynamic poke in justGallery) {
      if (uid != null) {
        dynamic byUid = poke['by']['uid'];
        dynamic toList = poke['to'];

        dynamic isBy = byUid != null && byUid == uid;
        dynamic isTo = toList.any((fr) => fr['uid'] == uid);

        if (!isBy && !isTo) continue;
      }
      allPokes.add(poke);
    }

    List<Map<dynamic, dynamic>> grouped = groupByDate(allPokes);
    List<Widget> widgets = [];
    List<dynamic> p = allPokes;

    for (dynamic group in grouped) {
      List<Widget> pokes = [];
      for (dynamic poke in group['pokes']) {
        pokes.add(
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OpenGallery(poke: poke, pokes: p),
                ),
              );
            },
            child: SizedBox(
              height: w,
              width: w,
              child: ClipRRect(
                child: Stack(
                  children: [
                    poke['is'] == 'img'
                        ? ExtendedImage.network(
                          apiUrl(
                            '/poke/saved?token=${userProvider.token}&id=${poke['id']}',
                          ),
                          height: w,
                          width: w,
                          fit: BoxFit.cover,
                          cache: true,
                          cacheMaxAge: Duration(days: 1),
                          loadStateChanged: (state) {
                            if (state.extendedImageLoadState ==
                                LoadState.completed) {
                              return null;
                            } else {
                              return SizedBox.shrink();
                            }
                          },
                        )
                        : PokeVideo(
                          url: apiUrl(
                            '/poke/saved?token=${userProvider.token}&id=${poke['id']}',
                          ),
                          thumbnail: true,
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      widgets.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                group['date'],
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.zero,
              child: Wrap(spacing: 2.5, runSpacing: 2.5, children: pokes),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        widgets.isEmpty ? SizedBox(height: 80) : SizedBox(height: 30),
        widgets.isEmpty
            ? Column(
              children: [
                Center(
                  child: SvgPicture.asset(
                    'images/growing-heart.svg',
                    height: 55,
                    width: 55,
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    'Your saved pokes are kept here!',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            )
            : Wrap(spacing: double.infinity, runSpacing: 10, children: widgets),
      ],
    );
  }

  // this function took sooo long ;-;
  // never touch this function again (6 hrs wasted)
  List<Map<dynamic, dynamic>> groupByDate(List<dynamic> pokes) {
    List<Map<dynamic, dynamic>> grouped = [];
    dynamic seenDates = <dynamic>{};

    for (dynamic poke in pokes) {
      dynamic createdAt = poke['createdAt'];
      dynamic date = datify(createdAt);
      if (!seenDates.contains(date)) {
        dynamic dayPokes =
            pokes.where((p) => datify(p['createdAt']) == date).toList();
        grouped.add({'date': date, 'pokes': dayPokes});
        seenDates.add(date);
      }
    }
    return grouped;
  }

  dynamic datify(dynamic isoDate) {
    dynamic date = DateTime.parse(isoDate).toLocal();
    dynamic now = DateTime.now();
    dynamic tday = DateTime(now.year, now.month, now.day);
    dynamic yest = tday.subtract(Duration(days: 1));
    dynamic checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == tday) return 'Tday';
    if (checkDate == yest) return 'Yday';

    // '05 Jul' or '05 Jul 25' dep on year
    dynamic newYear = date.year != now.year;
    dynamic fmt = newYear ? DateFormat('dd MMM yy') : DateFormat('MMM dd');

    return fmt.format(date);
  }
}
