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
    final double bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 28,
        right: 28,
        bottom: bottomPadding > 0 ? bottomPadding + 12 : 20,
        top: 8,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75), // Light Frosted Glass Dock
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5), // Inner light glow border
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06), // Soft ambient shadow
                  blurRadius: 24,
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
      duration: const Duration(milliseconds: 250),
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
        Stack(
          alignment: Alignment.center,
          children: [
             AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: widget.isActive ? 46 : 0,
              height: widget.isActive ? 28 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withValues(alpha: 0.12), // Soft 12% teal wash capsule
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            ScaleTransition(
              scale: _scaleAnimation,
              child: Icon(
                widget.isActive ? widget.item.activeIcon : widget.item.icon,
                size: 22,
                color: widget.isActive
                    ? const Color(0xFF0F766E) // Dark teal icon on soft wash
                    : const Color(0xFF64748B), // Slate 500 for inactive
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: widget.isActive
                ? const Color(0xFF0F766E) // Dark teal active text (no neon)
                : const Color(0xFF64748B), // Slate 500 for inactive
            fontSize: 10,
            fontWeight: widget.isActive ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: -0.2,
          ),
          child: Text(widget.item.label),
        ),
      ],
    );
  }
}
