import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícone "G" do Google desenhado em SVG inline
                _GoogleIcon(),
                const SizedBox(width: 12),
                const Text(
                  'Continuar com Google',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Red
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    // Blue
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    // Green
    final greenPaint = Paint()..color = const Color(0xFF34A853);
    // Yellow
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);

    // Simplified: draw 4 arcs
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, 3.14, false,
      redPaint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.28,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.57, 1.57, false,
      greenPaint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.28,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14, 0.79, false,
      yellowPaint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.28,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.93, 0.78, false,
      bluePaint..style = PaintingStyle.stroke..strokeWidth = size.width * 0.28,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
