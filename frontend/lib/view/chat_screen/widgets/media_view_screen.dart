import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class MediaViewScreen extends StatefulWidget {
  final String? url;
  final String? localPath;
  final String type; // 'image' or 'video'

  const MediaViewScreen({
    Key? key,
    this.url,
    this.localPath,
    required this.type,
  }) : super(key: key);

  @override
  State<MediaViewScreen> createState() => _MediaViewScreenState();
}

class _MediaViewScreenState extends State<MediaViewScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.file(File(widget.localPath!));
    } else if (widget.url != null && widget.url!.isNotEmpty) {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.url!));
    }

    if (_videoPlayerController != null) {
      await _videoPlayerController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: widget.type == 'image'
            ? _buildImage()
            : _buildVideo(),
      ),
    );
  }

  Widget _buildImage() {
    if (widget.localPath != null && widget.localPath!.isNotEmpty) {
      return InteractiveViewer(
        child: Image.file(File(widget.localPath!)),
      );
    } else if (widget.url != null && widget.url!.isNotEmpty) {
      return InteractiveViewer(
        child: CachedNetworkImage(
          imageUrl: widget.url!,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
        ),
      );
    }
    return const Icon(Icons.broken_image, color: Colors.white, size: 50);
  }

  Widget _buildVideo() {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(
        controller: _chewieController!,
      );
    } else {
      return const CircularProgressIndicator();
    }
  }
}
