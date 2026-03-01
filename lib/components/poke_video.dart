import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';

class PokeVideo extends StatefulWidget {
  final dynamic url;
  final dynamic thumbnail;
  final dynamic file;
  final dynamic ghost;

  const PokeVideo({
    super.key,
    this.url,
    this.thumbnail = false,
    this.file = false,
    this.ghost,
  });

  @override
  State<PokeVideo> createState() => _PokeVideoState();
}

class _PokeVideoState extends State<PokeVideo> {
  late BetterPlayerController _betterPlayerController;
  late dynamic url;
  dynamic config = false;

  onEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      if (widget.ghost == null) return;
      if (!mounted) return;
      Navigator.pop(widget.ghost);
    }
  }

  makePlayer() async {
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      widget.file
          ? BetterPlayerDataSourceType.file
          : BetterPlayerDataSourceType.network,
      url,
      cacheConfiguration: BetterPlayerCacheConfiguration(
        useCache: true,
        maxCacheSize: 5 * 1024 * 1024 * 1024, // 5GB all files combined
        maxCacheFileSize: 50 * 1024 * 1024, // 50MB per file
      ),
    );

    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        eventListener: onEvent,
        autoPlay: !widget.thumbnail,
        looping: !widget.thumbnail,
        aspectRatio:
            MediaQuery.of(context).size.width /
            (MediaQuery.of(context).size.height - 120),
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false, // No controls
        ),
        fit: BoxFit.cover,
      ),
      betterPlayerDataSource: dataSource,
    );
  }

  @override
  initState() {
    super.initState();
    url = widget.url;
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();

    if (config) return;

    setState(() {
      config = true;
    });

    makePlayer();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.thumbnail) {
      return ClipRRect(
        child: BetterPlayer(controller: _betterPlayerController),
      );
    }

    return GestureDetector(
      onTap: () {
        _betterPlayerController.isPlaying() ==
                true // can be null
            ? _betterPlayerController.pause()
            : _betterPlayerController.play();
      },
      child: ClipRRect(
        child: BetterPlayer(controller: _betterPlayerController),
      ),
    );
  }

  @override
  dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }
}
