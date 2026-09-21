import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:telecaller_app/utils/color_constant.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final bool isLocal;
  final bool isOutbound;

  const AudioPlayerWidget({
    Key? key,
    required this.audioUrl,
    this.isLocal = false,
    this.isOutbound = false,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
    
    _audioPlayer.onPlayerComplete.listen((event) {
       if (mounted) {
         setState(() {
           _position = Duration.zero;
           _isPlaying = false;
         });
       }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playPause() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (widget.isLocal) {
        await _audioPlayer.play(DeviceFileSource(widget.audioUrl));
      } else {
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
    }
  }
  
  String _formatDuration(Duration d) {
    String minutes = d.inMinutes.toString().padLeft(2, '0');
    String seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOutbound ? Colors.black87 : Colors.black87;
    return Container(
      width: 240,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: color,
            ),
            onPressed: _playPause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: widget.isOutbound ? Colors.black54 : ColorConstant.primaryColor,
                inactiveTrackColor: Colors.black12,
                thumbColor: widget.isOutbound ? Colors.black87 : ColorConstant.primaryColor,
                trackHeight: 3,
              ),
              child: Slider(
                min: 0.0,
                max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0,
                value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0),
                onChanged: (value) async {
                  final position = Duration(seconds: value.toInt());
                  await _audioPlayer.seek(position);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
