import 'package:flutter/material.dart';

class HorizontalMenuBar extends StatefulWidget {
  final List<Map<String, dynamic>> sections;
  final int selectedIndex;
  final Function(int) onSectionTapped;

  const HorizontalMenuBar({
    Key? key,
    required this.sections,
    required this.selectedIndex,
    required this.onSectionTapped,
  }) : super(key: key);

  @override
  _HorizontalMenuBarState createState() => _HorizontalMenuBarState();
}

class _HorizontalMenuBarState extends State<HorizontalMenuBar>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  double _scrollPosition = 0;
  bool _isDragging = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scrollController.addListener(() {
      if (!_isDragging && mounted) {
        setState(() {
          _scrollPosition =
              _scrollController.position.pixels /
              (_scrollController.position.maxScrollExtent == 0
                  ? 1
                  : _scrollController.position.maxScrollExtent);
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HorizontalMenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _scrollToSelected();
    }
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;

    final double targetOffset = widget.selectedIndex * 110.0;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double viewportWidth = _scrollController.position.viewportDimension;

    // Center the selected item
    double offset = targetOffset - (viewportWidth / 2) + 55;
    offset = offset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      child: Container(
        color: Colors.white,
        height: 90,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = widget.sections.length * 110.0;
            final visibleWidth = constraints.maxWidth;
            final indicatorWidth = (visibleWidth / totalWidth * visibleWidth)
                .clamp(40.0, visibleWidth);

            return Stack(
              children: [
                SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: widget.sections.asMap().entries.map((entry) {
                      final index = entry.key;
                      final section = entry.value;
                      final isSelected = widget.selectedIndex == index;

                      return GestureDetector(
                        onTap: () {
                          widget.onSectionTapped(index);
                          _animationController.forward(from: 0);
                        },
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOutCubic,
                          tween: Tween<double>(
                            begin: 0,
                            end: isSelected ? 1 : 0,
                          ),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: 1.0 + (value * 0.05),
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                constraints: const BoxConstraints(minWidth: 90),
                                decoration: BoxDecoration(
                                  color: Color.lerp(
                                    Colors.transparent,
                                    Colors.blue.shade50,
                                    value,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Color.lerp(
                                      const Color.fromARGB(255, 9, 41, 75),
                                      Colors.blue,
                                      value,
                                    )!,
                                    width: 1.6,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(
                                        value * 0.2,
                                      ),
                                      blurRadius: 8 * value,
                                      offset: Offset(0, 2 * value),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    TweenAnimationBuilder<double>(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      curve: Curves.easeOut,
                                      tween: Tween<double>(
                                        begin: 0,
                                        end: isSelected ? 1 : 0,
                                      ),
                                      builder: (context, iconValue, child) {
                                        return Icon(
                                          section['icon'] as IconData,
                                          color: Color.lerp(
                                            Colors.grey.shade600,
                                            Colors.blue,
                                            iconValue,
                                          ),
                                          size: 22 + (iconValue * 2),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      section['label'] as String,
                                      style: TextStyle(
                                        color: Color.lerp(
                                          Colors.grey.shade700,
                                          Colors.blue,
                                          value,
                                        ),
                                        fontWeight: FontWeight.lerp(
                                          FontWeight.w500,
                                          FontWeight.bold,
                                          value,
                                        ),
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                // Smooth Draggable Scroll Indicator
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: LayoutBuilder(
                      builder: (context, boxConstraints) {
                        if (!_scrollController.hasClients) {
                          return const SizedBox();
                        }

                        final maxScrollWidth =
                            _scrollController.position.maxScrollExtent;

                        if (maxScrollWidth == 0) {
                          return const SizedBox();
                        }

                        final leftPosition =
                            _scrollPosition *
                            (boxConstraints.maxWidth - indicatorWidth);

                        return GestureDetector(
                          onHorizontalDragStart: (_) {
                            setState(() => _isDragging = true);
                          },
                          onHorizontalDragUpdate: (details) {
                            if (!_scrollController.hasClients) return;

                            double newLeft = leftPosition + details.delta.dx;
                            newLeft = newLeft.clamp(
                              0.0,
                              boxConstraints.maxWidth - indicatorWidth,
                            );
                            double newScrollPos =
                                newLeft /
                                (boxConstraints.maxWidth - indicatorWidth) *
                                maxScrollWidth;
                            _scrollController.jumpTo(newScrollPos);
                          },
                          onHorizontalDragEnd: (_) {
                            setState(() => _isDragging = false);
                          },
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: _isDragging
                                    ? Duration.zero
                                    : const Duration(milliseconds: 150),
                                curve: Curves.easeOutCubic,
                                left: leftPosition.clamp(
                                  0.0,
                                  boxConstraints.maxWidth - indicatorWidth,
                                ),
                                child: Container(
                                  width: indicatorWidth,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
