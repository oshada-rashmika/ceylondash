import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class VoicePlayer extends StatefulWidget {
  final String audioUrl;
  final bool isIncoming;

  const VoicePlayer({super.key, required this.audioUrl, required this.isIncoming});

  @override
  _VoicePlayerState createState() => _VoicePlayerState();
}

class _VoicePlayerState extends State<VoicePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.setSourceUrl(widget.audioUrl);
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) setState(() => _duration = newDuration);
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) setState(() => _position = newPosition);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.isIncoming ? Colors.blue : Colors.white;
    final Color textColor = widget.isIncoming ? Colors.black54 : Colors.white70;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: iconColor),
          onPressed: () {
            if (_isPlaying) {
              _audioPlayer.pause();
            } else {
              _audioPlayer.play(UrlSource(widget.audioUrl));
            }
          },
        ),
        Slider(
          min: 0.0,
          max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
          value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
          onChanged: (value) async {
            final position = Duration(milliseconds: value.toInt());
            await _audioPlayer.seek(position);
          },
          activeColor: iconColor,
          inactiveColor: iconColor.withOpacity(0.3),
        ),
        Text(
          _formatDuration(_position),
          style: TextStyle(color: textColor, fontSize: 12),
        ),
      ],
    );
  }
}
