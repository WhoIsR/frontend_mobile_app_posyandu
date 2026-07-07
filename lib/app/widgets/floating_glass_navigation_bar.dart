import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../ledger_theme.dart';

class FloatingGlassNavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingGlassNavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class FloatingGlassNavigationBar extends StatelessWidget {
  const FloatingGlassNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<FloatingGlassNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for safe area
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: LedgerColors
          .paper, // Match scaffold background so the floating bar sits nicely
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomPadding > 0 ? bottomPadding + 8 : 16,
        top: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(destinations.length, (index) {
                final item = destinations[index];
                final bool isActive = selectedIndex == index;

                return Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onDestinationSelected(index);
                    },
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    child: _NavBarItem(item: item, isActive: isActive),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatefulWidget {
  const _NavBarItem({required this.item, required this.isActive});

  final FloatingGlassNavDestination item;
  final bool isActive;

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    if (widget.isActive) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: Icon(
            widget.isActive ? widget.item.activeIcon : widget.item.icon,
            size: 24,
            color: widget.isActive
                ? LedgerColors.primary
                : LedgerColors.inkSoft,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: widget.isActive
                ? LedgerColors.primary
                : LedgerColors.inkSoft,
            fontSize: 11,
            fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: -0.2,
          ),
          child: Text(widget.item.label),
        ),
        const SizedBox(height: 3),
        // Active dot indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.isActive ? 4 : 0,
          height: widget.isActive ? 4 : 0,
          decoration: const BoxDecoration(
            color: LedgerColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
