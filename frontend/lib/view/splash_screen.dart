import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:telecaller_app/main.dart'; // To access RootScreen

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({Key? key}) : super(key: key);

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.asset(
      'assets/PixVerse_V6_Image_Text_360P_Animate_a_sleek_lo.mp4',
    );

    try {
      await _controller.initialize();
      await _controller.setLooping(false);
      await _controller.setVolume(1.0);

      setState(() {
        _isVideoInitialized = true;
      });

      _controller.play();
      _controller.addListener(_videoListener);
    } catch (e) {
      debugPrint("Error initializing video: $e");
      _navigateToHome();
    }
  }

  void _videoListener() {
    if (_hasNavigated) return;

    if (_controller.value.isInitialized &&
        _controller.value.position >= _controller.value.duration) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (_hasNavigated) return;
    
    setState(() {
      _hasNavigated = true;
    });

    _controller.removeListener(_videoListener);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const RootScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO: Change this to match the exact background color of your video
      // You can use a hex color like this: Color(0xFF1A1A1A)
      backgroundColor: Colors.black, 
      body: Center(
        child: _isVideoInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.contain, // Changed from cover to contain
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const SizedBox.shrink(), // Replaced CircularProgressIndicator with empty space
      ),
    );
  }
}
