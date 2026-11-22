
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const NovaAI());
}

class NovaAI extends StatelessWidget {
  const NovaAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF080B12),
      ),
      home: const NovaHome(),
    );
  }
}

class NovaMessage {
  final String text;
  final bool isUser;

  NovaMessage(this.text, this.isUser);
}

class NovaHome extends StatefulWidget {
  const NovaHome({super.key});

  @override
  State<NovaHome> createState() => _NovaHomeState();
}

class _NovaHomeState extends State<NovaHome>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();
  final TextEditingController input = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final List<NovaMessage> messages = [];

  bool speechAvailable = false;
  bool listening = false;
  bool speaking = false;
  String status = 'NOVA IS READY';

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    initializeVoice();
  }

  Future<void> initializeVoice() async {
    speechAvailable = await speech.initialize(
      onStatus: (value) {
        if (!mounted) return;
        if (value == 'notListening' && listening) {
          setState(() => listening = false);
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          listening = false;
          status = 'VOICE ERROR';
        });
      },
    );

    await tts.setLanguage('en-US');
    await tts.setSpeechRate(0.45);
    await tts.setPitch(1.0);
    await tts.setVolume(0.7);

    if (mounted) {
      setState(() {
        status = speechAvailable ? 'NOVA IS READY' : 'VOICE UNAVAILABLE';
      });
    }
  }

  Future<void> startListening() async {
    if (!speechAvailable) {
      await initializeVoice();
    }

    if (!speechAvailable) {
      setState(() => status = 'VOICE NOT AVAILABLE');
      return;
    }

    await tts.stop();

    setState(() {
      listening = true;
      speaking = false;
      status = 'LISTENING...';
    });

    await speech.listen(
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        if (!mounted) return;

        setState(() {
          input.text = result.recognizedWords;
        });

        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          listening = false;
          sendMessage(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await speech.stop();
    if (!mounted) return;

    setState(() {
      listening = false;
      status = 'NOVA IS READY';
    });
  }

  String getReply(String text) {
    final q = text.toLowerCase().trim();

    if (q.contains('hello') || q.contains('hi')) {
      return 'Hello! I am Nova. How can I help you?';
    }

    if (q.contains('your name')) {
      return 'My name is Nova. Your mobile AI assistant.';
    }

    if (q.contains('time')) {
      final now = DateTime.now();
      final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
      final minute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'PM' : 'AM';
      return 'The current time is $hour $minute $period.';
    }

    if (q.contains('date') || q.contains('today')) {
      final now = DateTime.now();
      return 'Today is ${now.day}/${now.month}/${now.year}.';
    }

    if (q.contains('who are you')) {
      return 'I am Nova, a mobile voice assistant. I am ready to help.';
    }

    if (q.contains('thank')) {
      return 'You are welcome!';
    }

    if (q.contains('battery')) {
      return 'I cannot read your phone battery yet. Battery access will be added in a future update.';
    }

    if (q.contains('offline')) {
      return 'I can respond to some basic commands offline. Advanced AI answers require an AI service connection.';
    }

    return 'I received your message: $text. My offline brain is still developing. Online AI intelligence will be added in a future update.';
  }

  Future<void> sendMessage([String? voiceText]) async {
    final text = (voiceText ?? input.text).trim();
    if (text.isEmpty) return;

    input.clear();
    if (listening) await speech.stop();

    final reply = getReply(text);

    setState(() {
      listening = false;
      messages.add(NovaMessage(text, true));
      messages.add(NovaMessage(reply, false));
      status = 'THINKING...';
    });

    scrollToBottom();
    await speak(reply);
  }

  Future<void> speak(String text) async {
    await tts.stop();

    setState(() {
      speaking = true;
      status = 'NOVA SPEAKING';
    });

    await tts.speak(text);

    setState(() {
      speaking = false;
      status = 'NOVA IS READY';
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    speech.stop();
    tts.stop();
    input.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            const Text(
              'N O V A',
              style: TextStyle(
                fontSize: 25,
                letterSpacing: 9,
                color: Color(0xFFD4EFFF),
                fontWeight: FontWeight.w300,
              ),
            ),

            const SizedBox(height: 5),

            const Text(
              'PERSONAL AI ASSISTANT',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 12),

            AnimatedBuilder(
              animation: controller,
              builder: (context, child) {
                return CustomPaint(
                  size: const Size(280, 280),
                  painter: NovaSpherePainter(controller.value),
                );
              },
            ),

            Text(
              status,
              style: const TextStyle(
                color: Color(0xFF9FC8DF),
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: listening ? stopListening : startListening,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: listening
                      ? const Color(0xFF18394B)
                      : const Color(0xFF101824),
                  border: Border.all(
                    color: const Color(0xFF9ADFFF).withOpacity(0.55),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7BD9FF)
                          .withOpacity(listening ? 0.25 : 0.08),
                      blurRadius: listening ? 25 : 12,
                    ),
                  ],
                ),
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_none_rounded,
                  color: const Color(0xFFD1F0FF),
                  size: 29,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'TAP TO SPEAK',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: Colors.white38,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C111A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Your conversation with NOVA starts here.',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];

                          return Align(
                            alignment: msg.isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              constraints: const BoxConstraints(maxWidth: 280),
                              decoration: BoxDecoration(
                                color: msg.isUser
                                    ? const Color(0xFF173043)
                                    : const Color(0xFF171D27),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                msg.text,
                                style: const TextStyle(
                                  color: Color(0xFFDCEAF4),
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
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      onSubmitted: (_) => sendMessage(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Message NOVA...',
                        hintStyle: const TextStyle(color: Colors.white30),
                        filled: true,
                        fillColor: const Color(0xFF111722),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => sendMessage(),
                    icon: const Icon(Icons.arrow_upward_rounded),
                    color: const Color(0xFFD3F0FF),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF193246),
                    ),
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

class NovaSpherePainter extends CustomPainter {
  final double progress;

  NovaSpherePainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.34;

    final glow = Paint()
      ..color = const Color(0xFF85DFFF).withOpacity(0.035)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(center, radius * 1.6, glow);

    final ringPaint = Paint()
      ..color = const Color(0xFFB8E9FF).withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    canvas.drawCircle(center, radius * 1.35, ringPaint);

    final random = math.Random(17);
    const total = 900;
    final rotation = progress * math.pi * 2;

    for (int i = 0; i < total; i++) {
      final y = 1 - (2 * (i + 0.5) / total);
      final r = math.sqrt(1 - y * y);
      final theta = i * 2.399963;

      final x = math.cos(theta) * r;
      final z = math.sin(theta) * r;

      final rx = x * math.cos(rotation) - z * math.sin(rotation);
      final rz = x * math.sin(rotation) + z * math.cos(rotation);

      final depth = (rz + 1) / 2;
      final px = center.dx + rx * radius;
      final py = center.dy + y * radius;

      final sizeDot = 0.5 + random.nextDouble() * 1.1;
      final alpha = (0.12 + depth * 0.35).clamp(0.0, 0.55);

      final paint = Paint()
        ..color = Color.fromARGB(
          (alpha * 255).round(),
          175,
          225,
          255,
        );

      canvas.drawCircle(
        Offset(px, py),
        sizeDot * (0.5 + depth * 0.7),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant NovaSpherePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
