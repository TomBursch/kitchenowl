import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:kitchenowl/pages/photo_view_page.dart';
import 'package:kitchenowl/widgets/image_provider.dart';
import 'package:transparent_image/transparent_image.dart';

class FlexibleImageSpaceBar extends StatefulWidget {
  final String title;
  final int actionCount;
  final String imageUrl;
  final List<String>? imageUrls;
  final String? imageHash;
  final bool isCollapsed;

  const FlexibleImageSpaceBar({
    super.key,
    required this.title,
    this.isCollapsed = false,
    String? imageUrl,
    this.imageUrls,
    this.imageHash,
    this.actionCount = 1,
  }) : imageUrl = imageUrl ?? "";

  @override
  State<FlexibleImageSpaceBar> createState() => _FlexibleImageSpaceBarState();
}

class _FlexibleImageSpaceBarState extends State<FlexibleImageSpaceBar> {
  final PageController _pageController = PageController();
  int _page = 0;

  List<String> get _images => [
        ...(() {
          final uniqueImages = <String>[];
          final seenImages = <String>{};

          final candidates = widget.imageUrls?.isNotEmpty ?? false
              ? widget.imageUrls!
              : [widget.imageUrl];
          for (final candidate in candidates) {
            final normalized = candidate.trim();
            if (normalized.isEmpty) {
              continue;
            }
            if (seenImages.add(normalized)) {
              uniqueImages.add(normalized);
            }
          }

          return uniqueImages;
        })(),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToPage(int page) {
    if (page < 0 || page >= _images.length || page == _page) {
      return;
    }
    setState(() {
      _page = page;
    });
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
      );
    }
  }

  void _openCurrentImage() {
    if (_images.isEmpty) {
      return;
    }
    final currentIndex = _page.clamp(0, _images.length - 1);
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
      builder: (context) => PhotoViewPage(
        title: widget.title,
        imageProvider: getImageProvider(context, _images[currentIndex]),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FlexibleSpaceBar(
      titlePadding: EdgeInsetsDirectional.only(
        start: 60,
        bottom: 16,
        end: 16 + widget.actionCount * 40,
      ),
      title: Text(
        widget.title,
        maxLines: widget.isCollapsed ? 1 : 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      background: _images.isNotEmpty
          ? Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openCurrentImage,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (value) {
                      setState(() {
                        _page = value;
                      });
                    },
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      final imageUrl = _images[index];
                      return ShaderMask(
                        shaderCallback: (rect) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: [.6, .85],
                            colors: [Colors.black, Colors.transparent],
                          ).createShader(
                            Rect.fromLTRB(0, 0, rect.width, rect.height),
                          );
                        },
                        blendMode: BlendMode.dstIn,
                        child: FadeInImage(
                          placeholder: widget.imageHash != null && index == 0
                              ? BlurHashImage(widget.imageHash!)
                              : MemoryImage(kTransparentImage)
                                  as ImageProvider,
                          image: getImageProvider(context, imageUrl),
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
                if (_images.length > 1)
                  Positioned(
                    left: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _GalleryArrowButton(
                        icon: Icons.chevron_left_rounded,
                        onPressed:
                            _page > 0 ? () => _jumpToPage(_page - 1) : null,
                      ),
                    ),
                  ),
                if (_images.length > 1)
                  Positioned(
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _GalleryArrowButton(
                        icon: Icons.chevron_right_rounded,
                        onPressed: _page < _images.length - 1
                            ? () => _jumpToPage(_page + 1)
                            : null,
                      ),
                    ),
                  ),
                if (_images.length > 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _images.length,
                        (index) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _jumpToPage(index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index == _page
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withAlpha(100),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            )
          : null,
    );
  }
}

class _GalleryArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _GalleryArrowButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.22),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: enabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withAlpha(90),
            size: 28,
          ),
        ),
      ),
    );
  }
}
