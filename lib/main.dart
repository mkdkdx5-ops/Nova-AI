
import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const NovaAI());
}

class NovaAI extends StatelessWidget {
  const NovaAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NOVA AI',
      theme: ThemeData.dark(),
      home: const NovaHome(),
    );
  }
}

class NovaHome extends StatefulWidget {
  const NovaHome({super.key});

  @override
  State<NovaHome> createState() => _NovaHomeState();
}

class _NovaHomeState extends State<NovaHome>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool listening = false;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03070C),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Column(
              children: [
                const SizedBox(height: 25),

                const Text(
                  'NOVA AI',
                  style: TextStyle(
                    fontSize: 30,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFD5EFFF),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'YOUR INTELLIGENT ASSISTANT',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 4,
                    color: Colors.white38,
                  ),
                ),

                const Spacer(),

                Center(
                  child: SizedBox(
                    width: 330,
                    height: 330,
                    child: CustomPaint(
                      painter: ParticleSpherePainter(
                        progress: controller.value,
                        listening: listening,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  listening ? 'LISTENING...' : 'READY TO CONNECT',
                  style: TextStyle(
                    color: listening
                        ? const Color(0xFF9EEAFF)
                        : Colors.white54,
                    letterSpacing: 4,
                    fontSize: 11,
                  ),
                ),

                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _menuItem(Icons.chat_bubble_outline, 'CHAT'),
                    _menuItem(Icons.search, 'SEARCH'),
                    _menuItem(Icons.psychology_outlined, 'BRAIN'),
                  ],
                ),

                const SizedBox(height: 35),

                GestureDetector(
                  onTap: () {
                    setState(() {
                      listening = !listening;
                    });
                  },
                  child: Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0x669DDCFF),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x339DDCFF),
                          blurRadius: 30,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      listening ? Icons.stop : Icons.mic_none_rounded,
                      color: const Color(0xFFB9E6FF),
                      size: 35,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'TAP TO ACTIVATE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  'NOVA AI  •  VERSION 1.0',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF9FC9E5), size: 24),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 9,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class ParticleSpherePainter extends CustomPainter {
  final double progress;
  final bool listening;

  ParticleSpherePainter({
    required this.progress,
    required this.listening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.37;
    final rotation = progress * math.pi * 2;

    // Soft atmosphere
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0x229BCFFF),
          const Color(0x0A77AACC),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius * 1.8),
      );

    canvas.drawCircle(center, radius * 1.8, glowPaint);

    // Particles
    const count = 700;

    for (int i = 0; i < count; i++) {
      final y = 1 - (2 * (i + 0.5) / count);
      final ringRadius = math.sqrt(1 - y * y);
      final angle = i * 2.399963 + rotation;

      final x = math.cos(angle) * ringRadius;
      final z = math.sin(angle) * ringRadius;

      // Sphere rotation
      final rotatedX = x * math.cos(rotation) - z * math.sin(rotation);
      final rotatedZ = x * math.sin(rotation) + z * math.cos(rotation);

      final depth = rotatedZ;

      final px = center.dx + rotatedX * radius;
      final py = center.dy + y * radius;

      final hue = (190 + 35 * math.sin(progress * 6.28 + i * 0.03)) % 360;

      final color = HSVColor.fromAHSV(
        0.18 + ((depth + 1) / 2) * 0.45,
        hue / 360,
        0.35,
        0.95,
      ).toColor();

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final dotSize = 0.7 + ((depth + 1) / 2) * 1.7;

      canvas.drawCircle(
        Offset(px, py),
        dotSize * (listening ? 1.3 : 1),
        dotPaint,
      );
    }

    // Outer subtle ring
    final ringPaint = Paint()
      ..color = const Color(0x229BCFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    canvas.drawCircle(center, radius * 1.08, ringPaint);
  }

  @override
  bool shouldRepaint(covariant ParticleSpherePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.listening != listening;
  }
}
