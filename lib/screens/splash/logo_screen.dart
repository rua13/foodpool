import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoScreen extends StatefulWidget {
  const LogoScreen({super.key});

  @override
  State<LogoScreen> createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _forkX;
  late final Animation<double> _knifeX;
  late final Animation<double> _textX;
  late final Animation<double> _textOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();

    _forkX = Tween<double>(begin: 0, end: -78).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.42, curve: Curves.easeOutCubic),
      ),
    );
    _knifeX = Tween<double>(begin: 0, end: 78).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.30, 0.74, curve: Curves.easeOutCubic),
      ),
    );
    _textX = Tween<double>(begin: -18, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.44, 1, curve: Curves.easeOutCubic),
      ),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.44, 0.88, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return SizedBox(
              width: 320,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: Offset(_forkX.value, 0),
                    child: SvgPicture.asset(
                      'lib/assets/icons/logo1.svg',
                      width: 14,
                      height: 24,
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(_knifeX.value, 0),
                    child: SvgPicture.asset(
                      'lib/assets/icons/logo2.svg',
                      width: 14,
                      height: 24,
                    ),
                  ),
                  Opacity(
                    opacity: _textOpacity.value,
                    child: Transform.translate(
                      offset: Offset(_textX.value, 0),
                      child: Text(
                        'FOODPOOL',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.unbounded(
                          color: const Color(0xFFFF5751),
                          fontSize: 30.01,
                          fontWeight: FontWeight.w700,
                          height: 0.74,
                          letterSpacing: 0.19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
