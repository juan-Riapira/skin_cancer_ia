import 'package:flutter/material.dart';

class CabeceraCurva extends StatelessWidget {
  final String subtitulo;
  const CabeceraCurva({super.key, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _CabeceraClipper(),
      child: Container(
        width: double.infinity,
        height: 200,
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(24, 70, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'S L A T E',
              style: TextStyle(color: Colors.white, fontSize: 28, letterSpacing: 3),
            ),
            const SizedBox(height: 6),
            Text(subtitulo,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _CabeceraClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 1.05,
      size.width,
      0,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}