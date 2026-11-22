
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() => runApp(const NovaAI());

class NovaAI extends StatelessWidget {
  const NovaAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
  late AnimationController animation;

  final speech = stt.SpeechToText();
  final tts = FlutterTts();
  final input = TextEditingController();
  final scroll = ScrollController();

  final List<Map<String, dynamic>> chats = [];

  bool listening = false;
  bool speaking = false;
  bool thinking = false;
  bool available = false;

  String status = 'NOVA ONLINE';

  @override
  void initState() {
    super.initState();

    animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    initializeAI();
  }

  Future<void> initializeAI() async {
    available = await speech.initialize();

    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.45);
    await tts.setPitch(1.0);

    if (!mounted) return;
    setState(() => status = 'NOVA ONLINE');
  }

  Future<void> listen() async {
    if (listening) {
      await speech.stop();
      setState(() {
        listening = false;
        status = 'NOVA ONLINE';
      });
      return;
    }

    if (!available) {
      available = await speech.initialize();
    }

    if (!available) {
      setState(() => status = 'VOICE UNAVAILABLE');
      return;
    }

    await tts.stop();

    setState(() {
      listening = true;
      speaking = false;
      status = 'LISTENING';
    });

    await speech.listen(
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        input.text = result.recognizedWords;

        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          listening = false;
          send(result.recognizedWords);
        }
      },
    );
  }

  String reply(String text) {
    final q = text.toLowerCase();

    if (q.contains('hello') || q.contains('hi')) {
      return 'Hello! I am Nova. How can I help you?';
    }
    if (q.contains('your name')) {
      return 'My name is Nova AI.';
    }
    if (q.contains('time')) {
      return 'The time is ${TimeOfDay.now().format(context)}.';
    }
    if (q.contains('date')) {
      final d = DateTime.now();
      return 'Today is ${d.day}/${d.month}/${d.year}.';
    }
    if (q.contains('who are you')) {
      return 'I am Nova, your mobile AI assistant.';
    }
    if (q.contains('thank')) {
      return 'You are welcome.';
    }
    if (q.contains('offline')) {
      return 'I can perform some basic commands offline.';
    }

    return 'I heard you say $text. My smart AI brain is being developed.';
  }

  Future<void> send([String? voice]) async {
    final text = (voice ?? input.text).trim();
    if (text.isEmpty) return;

    await speech.stop();
    input.clear();

    setState(() {
      listening = false;
      thinking = true;
      status = 'THINKING';
      chats.add({'text": text, "user": true});
    });

    await Future.delayed(const Duration(milliseconds: 650));

    final answer = reply(text);

    setState(() {
      thinking = false;
      chats.add({"text": answer, "user": false});
      status = 'NOVA ONLINE';
    });

    scrollDown();
    speak(answer);
  }

  Future<void> speak(String text) async {
    setState(() {
      speaking = true;
      status = 'SPEAKING';
    });

    await tts.stop();
    await tts.speak(text);

    if (!mounted) return;
    setState(() {
      speaking = false;
      status = 'NOVA ONLINE';
    });
  }

  void scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    animation.dispose();
    speech.stop();
    tts.stop();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = listening
        ? 1
        : thinking
            ? 2
            : speaking
                ? 3
                : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF02050C),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              'N O V A   A I',
              style: TextStyle(
                fontSize: 25,
                letterSpacing: 6,
                color: Color(0xFFB8E9FF),
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'MOBILE INTELLIGENCE',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 4,
                color: Colors.white38,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 330,
              width: double.infinity,
              child: AnimatedBuilder(
                animation: animation,
                builder: (_, __) => CustomPaint(
                  painter: HighBlueOrbPainter(
                    animation.value,
                    mode,
                  ),
                ),
              ),
            ),

            Text(
              status,
              style: TextStyle(
                color: listening
                    ? Colors.lightBlueAccent
                    : const Color(0xFF79DFFF),
                letterSpacing: 4,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 15),

            GestureDetector(
              onTap: listen,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF071726),
                  border: Border.all(
                    color: const Color(0xFF42CFFF),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF008CFF)
                          .withOpacity(listening ? 0.65 : 0.25),
                      blurRadius: listening ? 35 : 20,
                      spreadRadius: listening ? 5 : 1,
                    ),
                  ],
                ),
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: Colors.lightBlueAccent,
                  size: 32,
                ),
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'TAP TO SPEAK',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF080D16),
                  border: Border.all(color: Colors.white10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: chats.isEmpty
                    ? const Center(
                        child: Text(
                          'NOVA SYSTEM READY',
                          style: TextStyle(
                            color: Colors.white24,
                            letterSpacing: 2,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scroll,
                        itemCount: chats.length,
                        itemBuilder: (_, i) {
                          final user = chats[i]['user'] as bool;
                          return Align(
                            alignment: user
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              constraints:
                                  const BoxConstraints(maxWidth: 270),
                              decoration: BoxDecoration(
                                color: user
                                    ? const Color(0xFF073354)
                                    : const Color(0xFF151E2A),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                chats[i]['text'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      onSubmitted: (_) => send(),
                      decoration: InputDecoration(
                        hintText: 'Talk to NOVA...',
                        filled: true,
                        fillColor: const Color(0xFF101722),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: send,
                    icon: const Icon(Icons.arrow_upward),
                    color: Colors.cyanAccent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HighBlueOrbPainter extends CustomPainter {
  final double progress;
  final int mode;

  HighBlueOrbPainter(this.progress, this.mode);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final radius = 94.0;
    final rot = progress * math.pi * 2;
    final pulse = 1 + math.sin(progress * math.pi * 8) * 0.035;

    final intensity = mode == 1
        ? 1.0
        : mode == 2
            ? 0.9
            : mode == 3
                ? 0.85
                : 0.65;

    final glow = Paint()
      ..color = const Color(0xFF008CFF).withOpacity(0.14 * intensity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);

    canvas.drawCircle(c, radius * 1.4 * pulse, glow);

    // Energy rings
    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot * (i.isEven ? 1 : -1) * 0.45);

      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == 0 ? 1.4 : 0.7
        ..color = Color(0xFF16BFFF).withOpacity(0.13 * intensity);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: radius * (2.1 + i * 0.14),
          height: radius * (0.42 + i * 0.11),
        ),
        ringPaint,
      );

      canvas.restore();
    }

    // Orb core glow
    final coreGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF62DFFF).withOpacity(0.18 * intensity),
          const Color(0xFF006EFF).withOpacity(0.12 * intensity),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: c, radius: radius));

    canvas.drawCircle(c, radius, coreGlow);

    // Particle sphere
    const count = 1150;
    final random = math.Random(42);

    for (int i = 0; i < count; i++) {
      final y = 1 - (2 * (i + 0.5) / count);
      final r = math.sqrt(1 - y * y);
      final theta = i * 2.399963;

      final x = math.cos(theta) * r;
      final z = math.sin(theta) * r;

      final rx = x * math.cos(rot) - z * math.sin(rot);
      final rz = x * math.sin(rot) + z * math.cos(rot);

      final px = c.dx + rx * radius * pulse;
      final py = c.dy + y * radius * pulse;

      final depth = (rz + 1) / 2;
      final dotSize = 0.5 + random.nextDouble() * 1.1;
      final alpha = (0.12 + depth * 0.62) * intensity;

      final paint = Paint()
        ..color = Color.fromRGBO(80, 190, 255, alpha.clamp(0.0, 1.0));

      canvas.drawCircle(
        Offset(px, py),
        dotSize * (0.5 + depth),
        paint,
      );
    }

    // Bright orbit nodes
    for (int i = 0; i < 8; i++) {
      final a = rot + i * math.pi / 4;
      final x = c.dx + math.cos(a) * radius * 1.55;
      final y = c.dy + math.sin(a) * radius * 0.55;

      final nodePaint = Paint()
        ..color = const Color(0xFF39DFFF).withOpacity(0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawCircle(Offset(x, y), 3, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HighBlueOrbPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.mode != mode;
  }
}
