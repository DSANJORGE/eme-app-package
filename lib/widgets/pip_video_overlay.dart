import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_eme_base/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';
import '../utils/error_handler.dart';
import 'fullscreen_mediaviewer.dart';

/// Floating Picture-in-Picture (PiP) Overlay manager and widget for video playback.
class PipVideoOverlay {
  static OverlayEntry? _overlayEntry;
  static _PipVideoOverlayWidgetState? _currentState;

  /// Returns whether a PiP overlay is currently active on screen.
  static bool get isShowing => _overlayEntry != null;

  /// Display a floating draggable PiP video player overlay on top of the app.
  static void show(
    BuildContext context, {
    required String videoUrl,
    String? title,
    String? caption,
    String? mediaType,
    Duration? startPosition,
  }) {
    // If an overlay already exists, dismiss it first
    dismiss();

    final overlayState = Overlay.of(context, rootOverlay: true);

    _overlayEntry = OverlayEntry(
      builder: (context) => _PipVideoOverlayWidget(
        videoUrl: videoUrl,
        title: title,
        caption: caption,
        mediaType: mediaType,
        startPosition: startPosition,
        onClose: dismiss,
        onStateCreated: (state) => _currentState = state,
      ),
    );

    overlayState.insert(_overlayEntry!);
  }

  /// Dismiss the current active PiP overlay window.
  static void dismiss() {
    if (_overlayEntry != null) {
      _currentState?.stopAndDispose();
      _overlayEntry?.remove();
      _overlayEntry = null;
      _currentState = null;
    }
  }
}

class _PipVideoOverlayWidget extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final String? caption;
  final String? mediaType;
  final Duration? startPosition;
  final VoidCallback onClose;
  final ValueChanged<_PipVideoOverlayWidgetState> onStateCreated;

  const _PipVideoOverlayWidget({
    required this.videoUrl,
    this.title,
    this.caption,
    this.mediaType,
    this.startPosition,
    required this.onClose,
    required this.onStateCreated,
  });

  @override
  State<_PipVideoOverlayWidget> createState() => _PipVideoOverlayWidgetState();
}

class _PipVideoOverlayWidgetState extends State<_PipVideoOverlayWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  Offset _position = const Offset(20, 100);
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);
    _initVideo();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Default initial position to bottom-right corner based on screen dimensions
    final screenSize = MediaQuery.of(context).size;
    final defaultX = screenSize.width - 240;
    final defaultY = screenSize.height - 200;
    if (_position.dx == 20 && _position.dy == 100) {
      _position = Offset(
        defaultX.clamp(16.0, screenSize.width - 230),
        defaultY.clamp(60.0, screenSize.height - 150),
      );
    }
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

  Future<void> _initVideo() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(
        uri,
        formatHint: widget.videoUrl.toLowerCase().contains('.m3u8')
            ? VideoFormat.hls
            : null,
      );
      await _controller!.initialize();
      _controller!.setLooping(true);

      if (widget.startPosition != null &&
          widget.startPosition! > Duration.zero) {
        await _controller!.seekTo(widget.startPosition!);
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
        _resetHideControlsTimer();
      }
    } catch (e, stack) {
      AppErrorHandler.recordNonFatal(
        e,
        stack,
        reason: 'PipVideoOverlay _initVideo failed',
        customKeys: {'videoUrl': widget.videoUrl},
      );
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void stopAndDispose() {
    _hideControlsTimer?.cancel();
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
  }

  @override
  void dispose() {
    stopAndDispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
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

  void _openFullscreen() {
    final contextRef = context;
    widget.onClose();

    FullScreenMediaViewer.open(
      contextRef,
      url: widget.videoUrl,
      caption: widget.caption,
      mediaType: widget.mediaType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    const pipWidth = 220.0;
    const pipHeight = 124.0;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            final newX = (_position.dx + details.delta.dx).clamp(
              10.0,
              screenSize.width - pipWidth - 10.0,
            );
            final newY = (_position.dy + details.delta.dy).clamp(
              40.0,
              screenSize.height - pipHeight - 20.0,
            );
            _position = Offset(newX, newY);
          });
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: pipWidth,
            height: pipHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.5),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Video View layer
                  if (_isInitialized && _controller != null)
                    Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio > 0
                            ? _controller!.value.aspectRatio
                            : 16 / 9,
                        child: VideoPlayer(_controller!),
                      ),
                    )
                  else if (_hasError)
                    const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 28,
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    ),

                  // Overlay Controls Layer
                  GestureDetector(
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
                    behavior: HitTestBehavior.translucent,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: Builder(
                          builder: (context) {
                            final l10n = AppLocalizations.of(context)!;
                            return Stack(
                              children: [
                                // Top drag handle & close button
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withValues(alpha: 0.8),
                                          Colors.transparent,
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.drag_handle_rounded,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            widget.title ?? l10n.pipVideo,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        InkWell(
                                          onTap: widget.onClose,
                                          borderRadius: BorderRadius.circular(12),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Center Play / Pause Button
                                Center(
                                  child: IconButton(
                                    iconSize: 34,
                                    padding: EdgeInsets.zero,
                                    icon: Icon(
                                      (_controller?.value.isPlaying ?? false)
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                      color: Colors.white.withValues(alpha: 0.95),
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),
                                ),

                                // Bottom Right: Fullscreen Action Button
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: IconButton(
                                    iconSize: 18,
                                    padding: const EdgeInsets.all(4),
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.fullscreen,
                                      color: Colors.white,
                                    ),
                                    tooltip: l10n.fullScreen,
                                    onPressed: _openFullscreen,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
