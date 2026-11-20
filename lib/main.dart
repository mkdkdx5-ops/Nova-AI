
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
      theme: ThemeData.dark(),
      home: const NovaHome(),
    );
  }
}

class ChatItem {
  final String text;
  final bool user;

  ChatItem(this.text, this.user);
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

  final List<ChatItem> messages = [];

  bool listening = false;
  bool speechReady = false;
  bool hindi = true;

  String status = 'NOVA READY';

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    messages.add(
      ChatItem('नमस्ते! मैं NOVA हूँ। बताइए, मैं आपकी क्या मदद करूँ?', false),
    );

    setupVoice();
  }

  Future<void> setupVoice() async {
    speechReady = await speech.initialize(
      onStatus: (s) {
        if ((s == 'notListening' || s == 'done') && mounted) {
          setState(() {
            listening = false;
            status = 'NOVA READY';
          });
        }
      },
      onError: (e) {
        if (mounted) {
          setState(() {
            listening = false;
            status = 'VOICE ERROR';
          });
        }
      },
    );

    await setLanguage();

    if (mounted) setState(() {});
  }

  Future<void> setLanguage() async {
    await tts.setLanguage(hindi ? 'hi-IN' : 'en-US');
    await tts.setSpeechRate(0.45);
    await tts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await tts.stop();
    await tts.speak(text);
  }

  void changeLanguage() async {
    if (listening) await speech.stop();

    setState(() {
      listening = false;
      hindi = !hindi;
      status = 'NOVA READY';
    });

    await setLanguage();

    final message = hindi
        ? 'भाषा हिंदी कर दी गई है।'
        : 'Language changed to English.';

    addMessage(message, false);
    speak(message);
  }

  void addMessage(String text, bool user) {
    if (!mounted) return;

    setState(() {
      messages.add(ChatItem(text, user));
      status = user ? 'MESSAGE RECEIVED' : 'NOVA RESPONDING';
    });

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

  Future<void> toggleMic() async {
    if (!speechReady) await setupVoice();

    if (!speechReady) {
      setState(() => status = 'VOICE NOT AVAILABLE');
      return;
    }

    if (listening) {
      await speech.stop();
      setState(() {
        listening = false;
        status = 'NOVA READY';
      });
      return;
    }

    await tts.stop();

    setState(() {
      listening = true;
      status = hindi ? 'सुन रही हूँ...' : 'LISTENING...';
    });

    await speech.listen(
      localeId: hindi ? 'hi-IN' : 'en-US',
      onResult: (result) {
        if (!mounted) return;

        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          final spokenText = result.recognizedWords.trim();
          addMessage(spokenText, true);
          respond(spokenText);
        }
      },
    );
  }

  String getTime() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  String getDate() {
    final now = DateTime.now();

    const days = [
      'Sunday', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday'
    ];

    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    const hindiDays = [
      'रविवार', 'सोमवार', 'मंगलवार', 'बुधवार',
      'गुरुवार', 'शुक्रवार', 'शनिवार'
    ];

    const hindiMonths = [
      'जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
      'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'
    ];

    if (hindi) {
      return '${hindiDays[now.weekday % 7]}, ${now.day} '
          '${hindiMonths[now.month - 1]} ${now.year}';
    }

    return '${days[now.weekday % 7]}, ${now.day} '
        '${months[now.month - 1]} ${now.year}';
  }

  String? calculate(String text) {
    final normalized = text
        .replaceAll('×', '*')
        .replaceAll('x', '*')
        .replaceAll('÷', '/')
        .replaceAll('plus', '+')
        .replaceAll('minus', '-')
        .replaceAll('multiply', '*')
        .replaceAll('into', '*')
        .replaceAll('divided by', '/');

    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*([+\-*/])\s*(-?\d+(?:\.\d+)?)',
    ).firstMatch(normalized);

    if (match == null) return null;

    final a = double.parse(match.group(1)!);
    final op = match.group(2)!;
    final b = double.parse(match.group(3)!);

    double result;

    switch (op) {
      case '+':
        result = a + b;
        break;
      case '-':
        result = a - b;
        break;
      case '*':
        result = a * b;
        break;
      case '/':
        if (b == 0) {
          return hindi
              ? 'शून्य से भाग नहीं कर सकते।'
              : 'Cannot divide by zero.';
        }
        result = a / b;
        break;
      default:
        return null;
    }

    final formatted = result == result.roundToDouble()
        ? result.toInt().toString()
        : result.toStringAsFixed(2);

    return hindi ? 'उत्तर है $formatted' : 'The answer is $formatted';
  }

  void respond(String message) {
    final text = message.toLowerCase().trim();
    String answer;

    final mathAnswer = calculate(text);

    if (mathAnswer != null) {
      answer = mathAnswer;
    } else if (text.contains('time') ||
        text.contains('समय') ||
        text.contains('कितने बजे')) {
      answer = hindi
          ? 'अभी समय है ${getTime()}'
          : 'The time is ${getTime()}';
    } else if (text.contains('date') ||
        text.contains('तारीख') ||
        text.contains('today') ||
        text.contains('दिन')) {
      answer = hindi ? 'आज ${getDate()} है।' : 'Today is ${getDate()}.';
    } else if (text.contains('hello') ||
        text == 'hi' ||
        text.contains('नमस्ते') ||
        text.contains('हेलो')) {
      answer = hindi
          ? 'नमस्ते! मैं NOVA हूँ। बताइए, मैं क्या मदद करूँ?'
          : 'Hello! I am NOVA. How can I help you?';
    } else if (text.contains('your name') ||
        text.contains('नाम') ||
        text.contains('who are you')) {
      answer = hindi
          ? 'मेरा नाम NOVA AI है।'
          : 'My name is NOVA AI.';
    } else if (text.contains('how are you') ||
        text.contains('कैसी हो') ||
        text.contains('कैसे हो')) {
      answer = hindi
          ? 'मैं तैयार हूँ! बताइए, क्या करना है?'
          : 'I am ready to help!';
    } else if (text.contains('thank') || text.contains('धन्यवाद')) {
      answer = hindi ? 'आपका स्वागत है!' : 'You are welcome!';
    } else if (text.contains('help') || text.contains('मदद')) {
      answer = hindi
          ? 'आप समय, तारीख, आसान गणित या मुझसे बातचीत कर सकते हैं।'
          : 'Ask me about time, date, simple math or chat.';
    } else {
      answer = hindi
          ? 'मैंने सुना: $message। अभी मैं बेसिक कमांड समझती हूँ।'
          : 'I heard: $message. I currently understand basic commands.';
    }

    addMessage(answer, false);
    setState(() => status = 'NOVA RESPONDING');
    speak(answer);
  }

  void sendMessage() {
    final message = input.text.trim();
    if (message.isEmpty) return;

    input.clear();
    addMessage(message, true);
    respond(message);
  }

  @override
  void dispose() {
    controller.dispose();
    input.dispose();
    scrollController.dispose();
    speech.stop();
    tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05090F),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            const Text(
              'N O V A',
              style: TextStyle(
                color: Color(0xFFBDEBFF),
                fontSize: 25,
                letterSpacing: 8,
                fontWeight: FontWeight.w300,
              ),
            ),

            const Text(
              'ARTIFICIAL INTELLIGENCE',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 4,
              ),
            ),

            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: changeLanguage,
                child: Text(
                  hindi ? 'हिंदी | EN' : 'EN | हिंदी',
                  style: const TextStyle(color: Color(0xFFBDEBFF)),
                ),
              ),
            ),

            SizedBox(
              height: 190,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) => CustomPaint(
                  size: const Size(230, 190),
                  painter: OrbPainter(controller.value),
                ),
              ),
            ),

            Text(
              status,
              style: const TextStyle(
                color: Color(0xFF9DDFFF),
                letterSpacing: 3,
                fontSize: 10,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final item = messages[index];

                  return Align(
                    alignment: item.user
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(13),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(
                        color: item.user
                            ? const Color(0xFF163246)
                            : const Color(0xFF111A24),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0x338EDCFF),
                        ),
                      ),
                      child: Text(
                        item.text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            GestureDetector(
              onTap: toggleMic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: listening ? 70 : 60,
                height: listening ? 70 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0C1923),
                  border: Border.all(color: const Color(0xFF9DDFFF)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8EDCFF)
                          .withOpacity(listening ? 0.3 : 0.1),
                      blurRadius: listening ? 28 : 14,
                    ),
                  ],
                ),
                child: Icon(
                  listening ? Icons.stop_rounded : Icons.mic_none_rounded,
                  color: const Color(0xFFBDEBFF),
                  size: 28,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              listening ? 'TAP TO STOP' : 'TAP TO SPEAK',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9,
                letterSpacing: 3,
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      onSubmitted: (_) => sendMessage(),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: hindi
                            ? 'NOVA से बात करें...'
                            : 'Message NOVA...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0xFF101822),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    color: const Color(0xFFBDEBFF),
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

class OrbPainter extends CustomPainter {
  final double progress;

  OrbPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.34;

    final glow = Paint()
      ..color = const Color(0xFF8EDCFF).withOpacity(0.035)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    canvas.drawCircle(center, radius * 1.5, glow);

    final ring = Paint()
      ..color = const Color(0xFFB5E8FF).withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    canvas.drawCircle(center, radius * 1.23, ring);

    final dotPaint = Paint()..style = PaintingStyle.fill;
    const count = 900;

    for (int i = 0; i < count; i++) {
      final y = 1 - (2 * (i + 0.5) / count);
      final r = math.sqrt(1 - y * y);
      final theta = i * 2.399963 + progress * 2 * math.pi;

      final x = math.cos(theta) * r;
      final z = math.sin(theta) * r;

      const tilt = 0.35;

      final rotatedY = y * math.cos(tilt) - z * math.sin(tilt);
      final rotatedZ = y * math.sin(tilt) + z * math.cos(tilt);
      final depth = (rotatedZ + 1) / 2;

      final px = center.dx + x * radius;
      final py = center.dy + rotatedY * radius;

      final alpha = (0.12 + depth * 0.38).clamp(0.0, 1.0);
      final dotSize = 0.5 + depth * 1.15;

      dotPaint.color = Color.fromRGBO(170, 220, 245, alpha);
      canvas.drawCircle(Offset(px, py), dotSize, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant OrbPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
