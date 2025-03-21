import 'package:flutter/material.dart';

// Custom Neumorphic button class for dark theme
class NeumorphicButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final double width;
  final double height;
  final bool isLoading;

  const NeumorphicButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.width = double.infinity,
    this.height = 50,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF252836), // Slightly lighter than background
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          // Dark shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(4, 4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          // Highlight shadow
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            offset: const Offset(-4, -4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF61DAFB)), // Light blue
                      strokeWidth: 2.5,
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

// Custom Neumorphic text field container for dark theme
class NeumorphicTextField extends StatelessWidget {
  final Widget child;

  const NeumorphicTextField({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252836), // Slightly lighter than background
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          // Dark shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(4, 4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
          // Subtle highlight
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            offset: const Offset(-4, -4),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}
