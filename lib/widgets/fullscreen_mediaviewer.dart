import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pip_video_overlay.dart';

enum DetectedMediaType { image, audio, video, pdf, unknown }

/// Fullscreen media viewer capable of displaying Images, Audio, Video, and PDF documents.
/// Accepts [url] or [mediaUrl] as prop, with optional [name], [caption], and [mediaType].
class FullScreenMediaViewer extends StatefulWidget {
  /// Primary media URL to display.
  final String? url;

  /// Alternative parameter name for media URL.
  final String? mediaUrl;

  /// Optional title or filename for the media.
  final String? name;

  /// Optional description or caption for the media.
  final String? caption;

  /// Optional explicit media type override: 'image', 'audio', 'video', or 'pdf'.
  final String? mediaType;

  const FullScreenMediaViewer({
    super.key,
    this.url,
    this.mediaUrl,
    this.name,
    this.caption,
    this.mediaType,
  }) : assert(
         url != null || mediaUrl != null,
         'Either url or mediaUrl must be provided.',
       );

  /// Effective URL helper.
  String get effectiveUrl => (url ?? mediaUrl ?? '').trim();

  /// Helper static method to open the FullScreenMediaViewer directly as a full-screen route.
  static Future<void> open(
    BuildContext context, {
    String? url,
    String? mediaUrl,
    String? name,
    String? caption,
    String? mediaType,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenMediaViewer(
          url: url,
          mediaUrl: mediaUrl,
          name: name,
          caption: caption,
          mediaType: mediaType,
        ),
      ),
    );
  }

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late DetectedMediaType _resolvedType;
  bool _showOverlay = true;

  // Video controller
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoError = false;
  Timer? _hideControlsTimer;

  // Audio player & state
  AudioPlayer? _audioPlayer;
  bool _isAudioPlaying = false;
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  bool _isAudioLoading = false;
  bool _isAudioError = false;

  // PDF state
  String? _pdfLocalPath;
  bool _isPdfLoading = false;
  bool _isPdfError = false;
  int _pdfTotalPages = 0;
  int _pdfCurrentPage = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _resolvedType = _determineMediaType();
    _initializeMedia();
  }

  DetectedMediaType _determineMediaType() {
    if (widget.mediaType != null && widget.mediaType!.isNotEmpty) {
      final typeStr = widget.mediaType!.toLowerCase();
      if (typeStr.contains('image')) return DetectedMediaType.image;
      if (typeStr.contains('audio') || typeStr.contains('sound'))
        return DetectedMediaType.audio;
      if (typeStr.contains('video')) return DetectedMediaType.video;
      if (typeStr.contains('pdf')) return DetectedMediaType.pdf;
    }

    final urlString = widget.effectiveUrl;
    final cleanUrl = urlString.split('?').first.split('#').first.toLowerCase();

    if (cleanUrl.endsWith('.pdf')) {
      return DetectedMediaType.pdf;
    }
    if (cleanUrl.endsWith('.mp3') ||
        cleanUrl.endsWith('.wav') ||
        cleanUrl.endsWith('.aac') ||
        cleanUrl.endsWith('.m4a') ||
        cleanUrl.endsWith('.ogg') ||
        cleanUrl.endsWith('.flac') ||
        cleanUrl.endsWith('.opus')) {
      return DetectedMediaType.audio;
    }
    if (cleanUrl.endsWith('.mp4') ||
        cleanUrl.endsWith('.mov') ||
        cleanUrl.endsWith('.mkv') ||
        cleanUrl.endsWith('.webm') ||
        cleanUrl.endsWith('.avi') ||
        cleanUrl.endsWith('.m3u8')) {
      return DetectedMediaType.video;
    }
    if (cleanUrl.endsWith('.jpg') ||
        cleanUrl.endsWith('.jpeg') ||
        cleanUrl.endsWith('.png') ||
        cleanUrl.endsWith('.gif') ||
        cleanUrl.endsWith('.webp') ||
        cleanUrl.endsWith('.bmp') ||
        cleanUrl.endsWith('.svg')) {
      return DetectedMediaType.image;
    }

    // Default fallback to image viewer
    return DetectedMediaType.image;
  }

  void _initializeMedia() {
    switch (_resolvedType) {
      case DetectedMediaType.video:
        _initVideo();
        break;
      case DetectedMediaType.audio:
        _initAudio();
        break;
      case DetectedMediaType.pdf:
        _downloadAndInitPdf();
        break;
      case DetectedMediaType.image:
      case DetectedMediaType.unknown:
        break;
    }
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 2), () {
      if (mounted &&
          _showOverlay &&
          _videoController != null &&
          _videoController!.value.isPlaying) {
        setState(() {
          _showOverlay = false;
        });
      }
    });
  }

  Future<void> _initVideo() async {
    try {
      final uri = Uri.parse(widget.effectiveUrl);
      _videoController = VideoPlayerController.networkUrl(
        uri,
        formatHint: widget.effectiveUrl.toLowerCase().contains('.m3u8')
            ? VideoFormat.hls
            : null,
      );
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.play();
        _resetHideControlsTimer();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isVideoError = true;
        });
      }
    }
  }

  Future<void> _initAudio() async {
    setState(() {
      _isAudioLoading = true;
    });

    try {
      _audioPlayer = AudioPlayer();

      _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isAudioPlaying = state == PlayerState.playing;
          });
        }
      });

      _audioPlayer!.onDurationChanged.listen((newDuration) {
        if (mounted) {
          setState(() {
            _audioDuration = newDuration;
            _isAudioLoading = false;
          });
        }
      });

      _audioPlayer!.onPositionChanged.listen((newPosition) {
        if (mounted) {
          setState(() {
            _audioPosition = newPosition;
          });
        }
      });

      await _audioPlayer!.setSourceUrl(widget.effectiveUrl);
      await _audioPlayer!.resume();
    } catch (_) {
      if (mounted) {
        setState(() {
          _isAudioLoading = false;
          _isAudioError = true;
        });
      }
    }
  }

  Future<void> _downloadAndInitPdf() async {
    setState(() {
      _isPdfLoading = true;
      _isPdfError = false;
    });

    try {
      final response = await http.get(Uri.parse(widget.effectiveUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final tempDir = await getTemporaryDirectory();
        final filename = 'doc_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${tempDir.path}/$filename');
        await file.writeAsBytes(bytes, flush: true);

        if (mounted) {
          setState(() {
            _pdfLocalPath = file.path;
            _isPdfLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load PDF (${response.statusCode})');
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPdfLoading = false;
          _isPdfError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
    if (_showOverlay) {
      if (_resolvedType == DetectedMediaType.video) {
        _resetHideControlsTimer();
      }
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  Future<void> _openInExternalBrowser() async {
    final uri = Uri.parse(widget.effectiveUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch media URL')),
        );
      }
    }
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleOverlay,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Media Content Layer
            Positioned.fill(child: _buildMediaBody()),

            // Animated Header Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _showOverlay
                    ? _buildHeader(context)
                    : const SizedBox.shrink(),
              ),
            ),

            // Animated Bottom Caption & Controls Overlay Layer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                opacity: _showOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: _showOverlay ? _buildFooter() : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaBody() {
    switch (_resolvedType) {
      case DetectedMediaType.image:
        return _buildImageViewer();
      case DetectedMediaType.video:
        return _buildVideoViewer();
      case DetectedMediaType.audio:
        return _buildAudioViewer();
      case DetectedMediaType.pdf:
        return _buildPdfViewer();
      case DetectedMediaType.unknown:
        return _buildImageViewer();
    }
  }

  // --- IMAGE VIEWER ---
  Widget _buildImageViewer() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      clipBehavior: Clip.none,
      child: Center(
        child: Image.network(
          widget.effectiveUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            final progress = loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                : null;
            return Center(
              child: CircularProgressIndicator(
                value: progress,
                color: Colors.white,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  size: 64,
                  color: Colors.white54,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _openInExternalBrowser,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in Browser'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- VIDEO VIEWER ---
  Widget _buildVideoViewer() {
    if (_isVideoError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.white54),
            const SizedBox(height: 12),
            const Text(
              'Failed to play video',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openInExternalBrowser,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Video Externally'),
            ),
          ],
        ),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
        ),
        // Play / Pause Overlay Center Indicator
        if (_showOverlay)
          IconButton(
            iconSize: 72,
            icon: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_filled,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            onPressed: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                  _hideControlsTimer?.cancel();
                  _showOverlay = true;
                } else {
                  _videoController!.play();
                  _resetHideControlsTimer();
                }
              });
            },
          ),
        // Video scrubber overlay
        if (_showOverlay)
          Positioned(
            bottom: (widget.caption != null && widget.caption!.isNotEmpty)
                ? 80
                : 24,
            left: 20,
            right: 20,
            child: ValueListenableBuilder(
              valueListenable: _videoController!,
              builder: (context, VideoPlayerValue value, child) {
                final duration = value.duration.inMilliseconds.toDouble();
                final position = value.position.inMilliseconds.toDouble();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _formatDuration(value.position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6,
                            ),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: position.clamp(
                              0.0,
                              duration > 0 ? duration : 1.0,
                            ),
                            max: duration > 0 ? duration : 1.0,
                            activeColor: Colors.white,
                            inactiveColor: Colors.white24,
                            onChanged: (val) {
                              _videoController!.seekTo(
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
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // --- AUDIO VIEWER ---
  Widget _buildAudioViewer() {
    if (_isAudioError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.audiotrack, size: 64, color: Colors.white54),
            const SizedBox(height: 12),
            const Text(
              'Failed to load audio',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openInExternalBrowser,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Audio Link'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Container(
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: Colors.grey[900]?.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Audio Icon / Artwork Placeholder
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade600, Colors.blue.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.music_note,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              if (widget.name != null && widget.name!.isNotEmpty)
                Text(
                  widget.name!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 16),

              if (_isAudioLoading)
                const CircularProgressIndicator(color: Colors.white)
              else ...[
                // Audio Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    value: _audioPosition.inSeconds.toDouble().clamp(
                      0.0,
                      _audioDuration.inSeconds.toDouble() > 0
                          ? _audioDuration.inSeconds.toDouble()
                          : 1.0,
                    ),
                    max: _audioDuration.inSeconds.toDouble() > 0
                        ? _audioDuration.inSeconds.toDouble()
                        : 1.0,
                    activeColor: Colors.deepPurpleAccent,
                    inactiveColor: Colors.white24,
                    onChanged: (val) {
                      _audioPlayer?.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(_audioPosition),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _formatDuration(_audioDuration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      onPressed: () {
                        final target =
                            _audioPosition - const Duration(seconds: 10);
                        _audioPlayer?.seek(
                          target < Duration.zero ? Duration.zero : target,
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 64,
                      icon: Icon(
                        _isAudioPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.deepPurpleAccent,
                      ),
                      onPressed: () {
                        if (_isAudioPlaying) {
                          _audioPlayer?.pause();
                        } else {
                          _audioPlayer?.resume();
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      iconSize: 36,
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () {
                        final target =
                            _audioPosition + const Duration(seconds: 10);
                        _audioPlayer?.seek(
                          target > _audioDuration ? _audioDuration : target,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- PDF VIEWER ---
  Widget _buildPdfViewer() {
    if (_isPdfLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Loading document...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_isPdfError || _pdfLocalPath == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf_outlined,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 12),
            const Text(
              'Failed to display PDF document',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openInExternalBrowser,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open PDF in Browser'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        PDFView(
          filePath: _pdfLocalPath,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: true,
          pageFling: true,
          onRender: (pages) {
            setState(() {
              _pdfTotalPages = pages ?? 0;
            });
          },
          onViewCreated: (controller) {
            _pdfViewController = controller;
          },
          onPageChanged: (page, total) {
            setState(() {
              _pdfCurrentPage = page ?? 0;
              if (total != null) _pdfTotalPages = total;
            });
          },
          onError: (error) {
            setState(() {
              _isPdfError = true;
            });
          },
        ),

        // Floating Page Controls Overlay
        if (_showOverlay && _pdfTotalPages > 0)
          Positioned(
            bottom: (widget.caption != null && widget.caption!.isNotEmpty)
                ? 80
                : 24,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _pdfCurrentPage > 0
                        ? () {
                            _pdfViewController?.setPage(_pdfCurrentPage - 1);
                          }
                        : null,
                  ),
                  Text(
                    'Page ${_pdfCurrentPage + 1} of $_pdfTotalPages',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _pdfCurrentPage < _pdfTotalPages - 1
                        ? () {
                            _pdfViewController?.setPage(_pdfCurrentPage + 1);
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // --- TOP HEADER BAR ---
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.black.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.name ?? _getFilenameFromUrl(widget.effectiveUrl),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_resolvedType == DetectedMediaType.video)
            IconButton(
              icon: const Icon(
                Icons.picture_in_picture_alt,
                color: Colors.white,
              ),
              tooltip: 'Picture in Picture',
              onPressed: () {
                final currentPos =
                    _videoController?.value.position ?? Duration.zero;
                final videoUrl = widget.effectiveUrl;
                final caption = widget.caption;
                final mediaType = widget.mediaType;
                Navigator.of(context).pop();
                PipVideoOverlay.show(
                  context,
                  videoUrl: videoUrl,
                  caption: caption,
                  mediaType: mediaType,
                  startPosition: currentPos,
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new, color: Colors.white),
            tooltip: 'Open link',
            onPressed: _openInExternalBrowser,
          ),
        ],
      ),
    );
  }

  // --- FOOTER CAPTION BAR ---
  Widget _buildFooter() {
    if (widget.caption == null || widget.caption!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.0),
            Colors.black.withValues(alpha: 0.85),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Text(
        widget.caption!,
        style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _getFilenameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segment = uri.pathSegments.lastWhere(
        (s) => s.isNotEmpty,
        orElse: () => 'Media Viewer',
      );
      return Uri.decodeFull(segment);
    } catch (_) {
      return 'Media Viewer';
    }
  }
}
