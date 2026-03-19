import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:extended_image/extended_image.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class PokeThumbnail extends StatefulWidget {
  final dynamic url;
  final dynamic id;
  final dynamic height;
  final dynamic width;

  const PokeThumbnail({super.key, this.url, this.height, this.width, this.id});

  @override
  State<PokeThumbnail> createState() => _PokeThumbnailState();
}

class _PokeThumbnailState extends State<PokeThumbnail> {
  late dynamic url;
  dynamic file;

  dynamic thumbify(url, id) async {
    dynamic box = Hive.box('thumbs');

    dynamic exist = box.get(id);
    if (exist != null) {
      setState(() {
        file = exist;
      });
      return;
    }

    dynamic data = await VideoThumbnail.thumbnailData(
      video: url,
      imageFormat: ImageFormat.PNG,
      quality: 75,
    );

    await box.put(id, data);
    setState(() {
      file = data;
    });
  }

  @override
  initState() {
    super.initState();
    thumbify(widget.url, widget.id);
  }

  @override
  Widget build(BuildContext context) {
    if (file == null) {
      return SizedBox.shrink();
    }

    return ExtendedImage.memory(
      file,
      height: widget.height,
      width: widget.width,
      fit: BoxFit.cover,
      loadStateChanged: (state) {
        if (state.extendedImageLoadState == LoadState.completed) {
          return null;
        } else {
          return SizedBox.shrink();
        }
      },
    );
  }
}
