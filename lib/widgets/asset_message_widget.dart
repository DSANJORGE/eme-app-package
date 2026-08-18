import 'dart:async';

import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:video_player/video_player.dart';

import '../models/chat_message.dart';
import 'fullscreen_mediaviewer.dart';
import 'pip_video_overlay.dart';

/// Widget for displaying a chat message of type asset.
/// Supports inline video playback, Picture-in-Picture (PiP) mode, and full-screen viewer.
class AssetMessageWidget extends StatefulWidget {
  final ChatMessage message;
  final String? assetThumbnail;
  final String? assetUrl;
  final String? caption;
  final String? mediaType;

  const AssetMessageWidget({
    super.key,
    required this.message,
    this.assetThumbnail,
    this.assetUrl,
    this.caption,
    this.mediaType,
  });

  @override
  State<AssetMessageWidget> createState() => _AssetMessageWidgetState();
}

class _AssetMessageWidgetState extends State<AssetMessageWidget> {
  VideoPlayerController? _controller;
  bool _isInlinePlaying = false;
  bool _isInitializing = false;
  bool _hasError = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted &&
          _showControls &&
          _controller != null &&
          _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  bool _checkIsVideo(String url, String? mediaType) {
    if (mediaType != null && mediaType.trim().isNotEmpty) {
      final t = mediaType.toLowerCase();
      if (t.contains('video')) return true;
    }
    final clean = url.split('?').first.split('#').first.toLowerCase();
    return clean.endsWith('.mp4') ||
        clean.endsWith('.mov') ||
        clean.endsWith('.mkv') ||
        clean.endsWith('.webm') ||
        clean.endsWith('.avi') ||
        clean.endsWith('.m3u8');
  }

  Future<void> _startInlinePlayer(String videoUrl) async {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        _isInlinePlaying = true;
      });
      _controller!.play();
      return;
    }

    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    try {
      final uri = Uri.parse(videoUrl);
      final controller = VideoPlayerController.networkUrl(
        uri,
        formatHint: videoUrl.toLowerCase().contains('.m3u8')
            ? VideoFormat.hls
            : null,
      );
      await controller.initialize();
      controller.setLooping(true);

      controller.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitializing = false;
          _isInlinePlaying = true;
        });
        controller.play();
        _resetHideControlsTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      }
    }
  }

  void _pauseInlinePlayer() {
    if (_controller != null && _controller!.value.isPlaying) {
      _controller!.pause();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _hideControlsTimer?.cancel();
        _showControls = true;
      } else {
        _controller!.play();
        _resetHideControlsTimer();
      }
    });
  }

  void _openPiP(String videoUrl, String? caption, String? mediaType) {
    _pauseInlinePlayer();
    final currentPos = _controller?.value.position ?? Duration.zero;
    PipVideoOverlay.show(
      context,
      videoUrl: videoUrl,
      caption: caption,
      mediaType: mediaType,
      startPosition: currentPos,
    );
  }

  void _openFullscreen(String targetUrl, String? caption, String? mediaType) {
    _pauseInlinePlayer();
    FullScreenMediaViewer.open(
      context,
      url: targetUrl,
      caption: caption,
      mediaType: mediaType,
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${twoDigits(duration.inHours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveThumb =
        widget.assetThumbnail ?? widget.message.asset?.thumbnail;
    final effectiveUrl = widget.assetUrl ?? widget.message.asset?.url;
    final effectiveCaption = widget.caption ?? widget.message.textContent;
    final effectiveMediaType =
        widget.mediaType ?? widget.message.asset?.mediaType;

    final hasThumb = effectiveThumb != null && effectiveThumb.trim().isNotEmpty;
    final hasUrl = effectiveUrl != null && effectiveUrl.trim().isNotEmpty;

    if (!hasThumb && !hasUrl) {
      return const SizedBox.shrink();
    }

    final imageUrl = hasThumb ? effectiveThumb : effectiveUrl!;
    final targetUrl = hasUrl ? effectiveUrl : imageUrl;
    final isVideo = _checkIsVideo(targetUrl, effectiveMediaType);

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            child: isVideo
                ? _buildVideoSection(
                    imageUrl: imageUrl,
                    targetUrl: targetUrl,
                    caption: effectiveCaption,
                    mediaType: effectiveMediaType,
                  )
                : _buildImageSection(
                    imageUrl: imageUrl,
                    targetUrl: targetUrl,
                    caption: effectiveCaption,
                    mediaType: effectiveMediaType,
                  ),
          ),
          if (effectiveCaption != null &&
              effectiveCaption.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              effectiveCaption.trim(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageSection({
    required String imageUrl,
    required String targetUrl,
    required String? caption,
    required String? mediaType,
  }) {
    return InkWell(
      onTap: () => _openFullscreen(targetUrl, caption, mediaType),
      borderRadius: BorderRadius.circular(11),
      child: Center(
        child: Container(
          constraints: BoxConstraints(maxHeight: 200),
          color: const Color(0xFF1E293B),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: FadeInImage.memoryNetwork(
              placeholder: kTransparentImage,
              image: imageUrl,
              fit: BoxFit.contain,
              imageErrorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1E293B),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 36,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Media Preview',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoSection({
    required String imageUrl,
    required String targetUrl,
    required String? caption,
    required String? mediaType,
  }) {
    // If video is active and playing inline
    if (_isInlinePlaying &&
        _controller != null &&
        _controller!.value.isInitialized) {
      final value = _controller!.value;
      final duration = value.duration.inMilliseconds.toDouble();
      final position = value.position.inMilliseconds.toDouble();

      return GestureDetector(
        onTap: () {
          setState(() {
            _showControls = !_showControls;
          });
          if (_showControls) {
            _resetHideControlsTimer();
          } else {
            _hideControlsTimer?.cancel();
          }
        },
        child: AspectRatio(
          aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller!),

              // Overlay Controls
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Stack(
                    children: [
                      // Center Play/Pause button
                      Center(
                        child: IconButton(
                          iconSize: 48,
                          icon: Icon(
                            value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          onPressed: _togglePlayPause,
                        ),
                      ),

                      // Bottom Control Bar
                      Positioned(
                        bottom: 4,
                        left: 8,
                        right: 8,
                        child: Row(
                          children: [
                            IconButton(
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: _togglePlayPause,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(value.position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 4,
                                  ),
                                  trackHeight: 2,
                                  overlayShape: SliderComponentShape.noOverlay,
                                ),
                                child: Slider(
                                  value: position.clamp(
                                    0.0,
                                    duration > 0 ? duration : 1.0,
                                  ),
                                  max: duration > 0 ? duration : 1.0,
                                  activeColor: Colors.white,
                                  inactiveColor: Colors.white30,
                                  onChanged: (val) {
                                    _controller!.seekTo(
                                      Duration(milliseconds: val.toInt()),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Text(
                              _formatDuration(value.duration),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Picture-in-Picture Button
                            IconButton(
                              iconSize: 20,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.picture_in_picture_alt,
                                color: Colors.white,
                              ),
                              tooltip: 'Picture in Picture',
                              onPressed: () =>
                                  _openPiP(targetUrl, caption, mediaType),
                            ),
                            // Fullscreen Button
                            IconButton(
                              iconSize: 20,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.fullscreen,
                                color: Colors.white,
                              ),
                              tooltip: 'Full Screen',
                              onPressed: () => _openFullscreen(
                                targetUrl,
                                caption,
                                mediaType,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Default thumbnail preview state with Play button overlay
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background thumbnail image
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1E293B),
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: imageUrl,
                fit: BoxFit.cover,
                imageErrorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFF1E293B),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.movie_outlined,
                          color: Colors.white54,
                          size: 36,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Video Preview',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Video Badge
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.videocam, color: Colors.white70, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center Play Action Button / Loader
          if (_isInitializing)
            const CircularProgressIndicator(color: Colors.white)
          else if (_hasError)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white70,
                  size: 36,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Failed to load video',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 4),
                ElevatedButton.icon(
                  onPressed: () =>
                      _openFullscreen(targetUrl, caption, mediaType),
                  icon: const Icon(Icons.open_in_new, size: 14),
                  label: const Text(
                    'Open External',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: () => _startInlinePlayer(targetUrl),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
