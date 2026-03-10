import 'dart:async';
import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

/// === A VARIANTAS: atskiri jaunajai klausimai ===
/// Bride questions (įdėk visus 20 — gali palikti ir šituos, bet geriau sukelti visus)
const brideQuestions = <String>[
  "When did you first realize he was “the one”?",
  "What was your first impression of him?",
  "What is one habit of his you secretly love?",
  "What moment with him made you feel the most loved?",
  "When did you know you wanted to marry him?",
  "What’s one thing you hope never changes in your relationship?",
  "What’s your favorite memory from your first year together?",
  "What was your reaction after the proposal?",
  "Which of the girls here has known you the longest?",
  "Who was there for you during your worst heartbreak?",
  "What is your funniest memory with the girls?",
  "Which friend knows your biggest secrets?",
  "Who gives you the best relationship advice?",
  "Who was the most protective of you in past relationships?",
  "What moment with the girls made you feel the most loved?",
  "What is one crazy memory you’ll never forget with them?",
  "Who changed you the most in a positive way?",
  "What is something you’ve learned about love from your friendships?",
  "Who do you call first when something dramatic happens?",
  "If your friendship with these girls had a title, what would it be?",
];

/// Girls questions (įdėk visus 30 — čia palikau tavo mix)
const girlsQuestions = <String>[
  "When did you first meet the bride, and what was your first impression?",
  "What’s the funniest thing the bride has ever done in front of you?",
  "What’s the most iconic “bride quote” you’ve heard from her?",
  "If the bride were a movie character, who would she be?",
  "What’s the most unforgettable memory you have with the bride?",
  "When did you first realize the groom was serious about her?",
  "What’s something you genuinely admire about the groom?",
  "What’s the sweetest moment you’ve witnessed between them?",
  "If you had to describe their relationship in 3 words, what would they be?",
  "What’s one thing you think they do really well as a couple?",
  "What’s one thing the bride taught you about love or relationships?",
  "What’s one thing the bride does that makes her an amazing friend?",
  "What’s the best advice you’ve ever given the bride?",
  "What’s the best advice the bride has ever given you?",
  "What’s a moment when the bride surprised you (in a good way)?",
  "Who in this group is most likely to cry during the wedding, and why?",
  "Who in this group is the “planner,” and who is the “chaos queen”?",
  "What’s the funniest group memory you all share?",
  "What’s one thing you all should do together again in the future?",
  "What’s the most “we understand each other without words” moment in this group?",
  "What was the bride like when she was single?",
  "What’s the funniest “dating era” story you remember about her?",
  "What’s a green flag the groom has that makes you happy for her?",
  "What’s one red flag the bride used to ignore in dating (before him)?",
  "What’s one thing you hope the groom never changes about how he treats her?",
  "What do you think is the bride’s love language?",
  "What do you think is the groom’s love language?",
  "What’s one tradition or ritual you think they should start as a couple?",
  "If you could give them one rule for a happy marriage, what would it be?",
  "What’s one wish you have for the bride — and one for their relationship?",
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bachelorette News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const CoverScreen(),
    );
  }
}

/// === 1) VIRŠELIS / INTRO ===
class CoverScreen extends StatelessWidget {
  const CoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  "BACHELORETTE NEWS ✨",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Sveiki atvykę į naujienų puslapį, kuriame sužinosite įdomių ir gal net spicy prisipažinimų apie merginas ir jaunąją 💋",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, height: 1.15),
              ),
              const SizedBox(height: 14),
              Text(
                "Tiesiog suvesk merginų vardus ir kiekvienai ateis jos eilė.\nJaunoji pasirodys dažniau – kad būtų įdomiau 👰‍♀️",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black.withOpacity(0.65), height: 1.35),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD6E8), Color(0xFFFFB7D5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                      color: Colors.black.withOpacity(0.10),
                    )
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BrideNameScreen()),
                    );
                  },
                  child: const Text(
                    "PRADĖTI 📰",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// === 2) JAUNOSIOS VARDAS ===
class BrideNameScreen extends StatefulWidget {
  const BrideNameScreen({super.key});

  @override
  State<BrideNameScreen> createState() => _BrideNameScreenState();
}

class _BrideNameScreenState extends State<BrideNameScreen> {
  final controller = TextEditingController();

  void _next() {
    final name = controller.text.trim();
    if (name.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GirlsNamesScreen(brideName: name),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        title: const Text("Jaunoji"),
        backgroundColor: const Color(0xFFFFF7FB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            const Text(
              "Koks mūsų gražiosios kaltininkės vardas? 👰‍♀️\nTikėtina šiandien ji apsirengusi baltais…",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.25),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _next(),
              decoration: InputDecoration(
                hintText: "Jaunosios vardas",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text("Toliau ➜", style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// === 3) MERGINŲ VARDŲ ĮVEDIMAS DINAMIŠKAI (1 laukelis → atsiranda kitas) ===
class GirlsNamesScreen extends StatefulWidget {
  final String brideName;
  const GirlsNamesScreen({super.key, required this.brideName});

  @override
  State<GirlsNamesScreen> createState() => _GirlsNamesScreenState();
}

class _GirlsNamesScreenState extends State<GirlsNamesScreen> {
  static const maxGirls = 15;

  final List<TextEditingController> controllers = [TextEditingController()];

  void _maybeAddNewField() {
    // jei paskutinis laukas užpildytas, pridedam naują (iki 15)
    final last = controllers.last.text.trim();
    if (last.isNotEmpty && controllers.length < maxGirls) {
      setState(() => controllers.add(TextEditingController()));
    }
  }

  void _start() {
    final names = controllers
        .map((c) => c.text.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    if (names.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          brideName: widget.brideName,
          girls: names,
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        title: const Text("Merginos"),
        backgroundColor: const Color(0xFFFFF7FB),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Įvesk merginų vardus (iki $maxGirls).\nĮvedus vieną vardą, atsiras kitas laukelis ✨",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black.withOpacity(0.65), height: 1.35),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                itemCount: controllers.length,
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextField(
                      controller: controllers[i],
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _maybeAddNewField(),
                      onSubmitted: (_) => _maybeAddNewField(),
                      decoration: InputDecoration(
                        hintText: "Mergina ${i + 1}",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _start,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                child: const Text("Pradėti žaidimą 🎉", style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// === 4) GAME: beige shuffle → viena kortelė „išlenda“ → flip → klausimas ===
/// + bride question kas 2 arba 3 kartus (random)
class GameScreen extends StatefulWidget {
  final String brideName;
  final List<String> girls;

  const GameScreen({
    super.key,
    required this.brideName,
    required this.girls,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum TargetType { bride, girl }

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final rnd = Random();

  late List<String> brideDeck;
  late List<String> girlsDeck;

  int girlIndex = 0; // merginos eilės tvarka
  int stepsUntilBride = 2; // po kiek klausimų vėl jaunajai (2 arba 3)

  // UI states
  bool isShuffling = false;
  bool isRevealed = false;

  TargetType? currentTarget;
  String currentName = "";
  String currentQuestion = "";

  // Animations
  late final AnimationController shuffleController;
  late final AnimationController flipController;
  late final ConfettiController confettiController;

  @override
  void initState() {
    super.initState();
    brideDeck = List<String>.from(brideQuestions)..shuffle(rnd);
    girlsDeck = List<String>.from(girlsQuestions)..shuffle(rnd);

    stepsUntilBride = _pickBrideInterval(); // 2 or 3

    shuffleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    confettiController = ConfettiController(duration: const Duration(milliseconds: 420));
  }

  @override
  void dispose() {
    shuffleController.dispose();
    flipController.dispose();
    confettiController.dispose();
    super.dispose();
  }

  int _pickBrideInterval() => 2 + rnd.nextInt(2); // 2 or 3

  String _drawFromDeck(List<String> deck, List<String> original) {
    if (deck.isEmpty) {
      deck.addAll(original);
      deck.shuffle(rnd);
    }
    return deck.removeLast();
  }

  TargetType _nextTargetType() {
    // Jaunoji dažniau: kas 2–3 kartus (random), todėl jos bus daugiau
    if (stepsUntilBride <= 0) {
      stepsUntilBride = _pickBrideInterval();
      return TargetType.bride;
    }
    stepsUntilBride -= 1;
    return TargetType.girl;
  }

  Future<void> nextQuestion() async {
    if (isShuffling) return;

    setState(() {
      isShuffling = true;
      isRevealed = false;
    });

    // tactile + click
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    // 1) beige kortelių maišymas
    shuffleController.reset();
    await shuffleController.forward();

    // 2) parenkam kas atsako + klausimą
    final target = _nextTargetType();
    String name;
    String q;

    if (target == TargetType.bride) {
      name = widget.brideName;
      q = _drawFromDeck(brideDeck, brideQuestions);
    } else {
      name = widget.girls[girlIndex % widget.girls.length];
      girlIndex += 1;
      q = _drawFromDeck(girlsDeck, girlsQuestions);
    }

    setState(() {
      currentTarget = target;
      currentName = name;
      currentQuestion = q;
    });

    // 3) flip reveal
    flipController.reset();
    await Future.delayed(const Duration(milliseconds: 180));
    await flipController.forward();

    // 4) confetti
    confettiController.play();

    setState(() {
      isShuffling = false;
      isRevealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final headline = (currentTarget == TargetType.bride)
        ? "${widget.brideName} answers 👰‍♀️"
        : (currentTarget == TargetType.girl)
            ? "$currentName answers 👯"
            : "Tap Next Question";

    return Scaffold(
      backgroundColor: const Color(0xFFFFF7FB),
      appBar: AppBar(
        title: const Text("Bachelorette News"),
        backgroundColor: const Color(0xFFFFF7FB),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Text(
                  headline,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),

                // === Beige "shuffle" + flip card area ===
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 340,
                      height: 430,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background stacked cards (beige)
                          _BeigeStackedCards(animation: shuffleController),

                          // Foreground flip card (appears after shuffle)
                          if (currentTarget != null)
                            AnimatedBuilder(
                              animation: flipController,
                              builder: (context, child) {
                                // flip from 0 -> pi
                                final t = flipController.value;
                                final angle = t * pi;

                                final showFront = angle < (pi / 2);

                                return Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.0012)
                                    ..rotateY(angle),
                                  child: showFront
                                      ? _CardFaceFront(label: "Breaking News…")
                                      : Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.identity()..rotateY(pi),
                                          child: _CardFaceBack(
                                            name: currentName,
                                            isBride: currentTarget == TargetType.bride,
                                            question: currentQuestion,
                                          ),
                                        ),
                                );
                              },
                            ),

                          if (currentTarget == null)
                            _CardFaceFront(
                              label: "Tap Next Question\n🎴",
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isShuffling ? null : nextQuestion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      isShuffling ? "Shuffling…" : "Next Question 📰",
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Merginos eina eilės tvarka, o jaunoji pasirodo kas 2–3 kartus ✨",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black.withOpacity(0.55)),
                ),
              ],
            ),
          ),

          // Confetti top
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.22,
              numberOfParticles: 18,
              gravity: 0.35,
              minimumSize: const Size(6, 3),
              maximumSize: const Size(10, 6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Beige cards that “shuffle” (simple, classy animation)
class _BeigeStackedCards extends StatelessWidget {
  final Animation<double> animation;
  const _BeigeStackedCards({required this.animation});

  @override
  Widget build(BuildContext context) {
    // 4 cards in the back, wobble a bit during shuffle
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        final wobble = sin(t * pi * 6) * 6; // degrees-ish
        final slide = (1 - t) * 14;

        Widget card(int i) {
          final base = i * 10.0;
          return Transform.translate(
            offset: Offset((i.isEven ? -1 : 1) * slide, base),
            child: Transform.rotate(
              angle: (wobble * (i + 1) / 300),
              child: Container(
                width: 320,
                height: 410,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E7D6), // beige
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                      color: Colors.black.withOpacity(0.08),
                    )
                  ],
                ),
              ),
            ),
          );
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            card(3),
            card(2),
            card(1),
            card(0),
          ],
        );
      },
    );
  }
}

class _CardFaceFront extends StatelessWidget {
  final String label;
  const _CardFaceFront({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 410,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E7D6), // beige
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.10),
          )
        ],
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.black.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}

class _CardFaceBack extends StatelessWidget {
  final String name;
  final bool isBride;
  final String question;

  const _CardFaceBack({
    required this.name,
    required this.isBride,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: 410,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD6E8), Color(0xFFFFB7D5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 10),
            color: Colors.black.withOpacity(0.12),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isBride ? "$name 👰‍♀️" : "$name 👯",
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
