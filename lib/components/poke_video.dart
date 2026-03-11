import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class PokeVideo extends StatefulWidget {
  final dynamic url;
  final dynamic file;
  final dynamic ghost;

  const PokeVideo({super.key, this.url, this.file = false, this.ghost});

  @override
  State<PokeVideo> createState() => _PokeVideoState();
}

class _PokeVideoState extends State<PokeVideo> {
  late dynamic url;
  BetterPlayerController? betterPlayer;
  dynamic config = false;
  dynamic loading = false;

  onEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.bufferingStart) {
      setState(() {
        loading = true;
      });
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.bufferingEnd) {
      setState(() {
        loading = false;
      });
    }

    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      // uh for ghosting
      if (widget.ghost == null) return;
      if (!mounted) return; // dont pop if not on same page

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
        maxCacheFileSize: 5 * 1024 * 1024, // 5MB per file (vercel lim)
      ),
    );

    betterPlayer = BetterPlayerController(
      BetterPlayerConfiguration(
        eventListener: onEvent,
        autoPlay: true,
        looping: true,
        aspectRatio:
            MediaQuery.of(context).size.width /
            (MediaQuery.of(context).size.height - 120),
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: false, // still no controls
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
    if (betterPlayer == null) {
      return SizedBox.shrink();
    }

    if (loading) {
      return Center(
        child: LoadingAnimationWidget.waveDots(color: Colors.white, size: 40),
      );
    }

    return GestureDetector(
      onTap: () {
        betterPlayer?.isPlaying() ==
                true // can be null
            ? betterPlayer?.pause()
            : betterPlayer?.play();
      },
      child: ClipRRect(
        child: BetterPlayer(controller: betterPlayer as BetterPlayerController),
      ),
    );
  }

  @override
  dispose() {
    betterPlayer?.dispose();
    super.dispose();
  }
}
