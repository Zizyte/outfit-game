import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data/cards.dart';
import 'models/outfit_card.dart';

const String kStripePaymentUrl = 'https://buy.stripe.com/test_4gM9AVegp1i821RdNC6sw00';

/// Keep this private.
/// Example owner link:
/// https://your-site.netlify.app/?owner=1
const String kOwnerBypassValue = '1';

void main() => runApp(const OutfitGameApp());

class OutfitGameApp extends StatelessWidget {
  const OutfitGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFFFAF7FF);
    const ink = Color(0xFF1E1E22);
    const accent = Color(0xFFFF6FAE);
    const accent2 = Color(0xFF7C6BFF);

    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: accent).copyWith(
        primary: accent,
        secondary: accent2,
        surface: Colors.white,
        onSurface: ink,
        onPrimary: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.4,
          color: ink,
        ),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Outfit Personality',
      theme: theme,
      home: const GateScreen(),
    );
  }
}

class AccessSession {
  final String token;
  final DateTime expiresAt;

  const AccessSession({
    required this.token,
    required this.expiresAt,
  });
}

class AccessService {
  static const _tokenKey = 'paid_access_token';
  static const _expiryKey = 'paid_access_expiry_ms';

  static Uri _functionUri(String name, [Map<String, String>? query]) {
    return Uri(
      path: '/.netlify/functions/$name',
      queryParameters: query,
    );
  }

  static bool get isOwnerBypass {
    return Uri.base.queryParameters['owner'] == kOwnerBypassValue;
  }

  static String? get sessionIdFromUrl {
    final value = Uri.base.queryParameters['session_id'];
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  static Future<AccessSession?> redeemCheckoutSession(String sessionId) async {
    try {
      final res = await http.get(
        _functionUri('redeem-session', {'session_id': sessionId}),
      );

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final token = (data['token'] ?? '').toString();
      final expiresAtRaw = (data['expiresAt'] ?? '').toString();

      if (token.isEmpty || expiresAtRaw.isEmpty) return null;

      return AccessSession(
        token: token,
        expiresAt: DateTime.parse(expiresAtRaw).toUtc(),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> validateToken(String token) async {
    try {
      final res = await http.get(
        _functionUri('validate-access', {'token': token}),
      );

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['active'] == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> cacheSession(AccessSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token);
    await prefs.setInt(_expiryKey, session.expiresAt.millisecondsSinceEpoch);
  }

  static Future<AccessSession?> getCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final expiryMs = prefs.getInt(_expiryKey);

    if (token == null || token.isEmpty || expiryMs == null) return null;

    return AccessSession(
      token: token,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiryMs, isUtc: true),
    );
  }

  static Future<void> clearCachedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiryKey);
  }
}

/// --------------------
/// GATE LOGIC
/// --------------------
class GateScreen extends StatefulWidget {
  const GateScreen({super.key});

  @override
  State<GateScreen> createState() => _GateScreenState();
}

enum _GateState {
  loading,
  notPaid,
  active,
  expired,
  error,
}

class _GateScreenState extends State<GateScreen> {
  _GateState _state = _GateState.loading;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _state = _GateState.loading;
      _message = '';
    });

    if (AccessService.isOwnerBypass) {
      if (!mounted) return;
      setState(() => _state = _GateState.active);
      return;
    }

    final sessionId = AccessService.sessionIdFromUrl;
    if (sessionId != null) {
      final redeemed = await AccessService.redeemCheckoutSession(sessionId);
      if (redeemed != null) {
        await AccessService.cacheSession(redeemed);
        if (!mounted) return;
        setState(() => _state = _GateState.active);
        return;
      } else {
        if (!mounted) return;
        setState(() {
          _state = _GateState.error;
          _message = 'Payment was detected, but access could not be activated.';
        });
        return;
      }
    }

    final cached = await AccessService.getCachedSession();
    if (cached == null) {
      if (!mounted) return;
      setState(() => _state = _GateState.notPaid);
      return;
    }

    if (DateTime.now().toUtc().isAfter(cached.expiresAt)) {
      await AccessService.clearCachedSession();
      if (!mounted) return;
      setState(() => _state = _GateState.expired);
      return;
    }

    final valid = await AccessService.validateToken(cached.token);
    if (valid) {
      if (!mounted) return;
      setState(() => _state = _GateState.active);
    } else {
      await AccessService.clearCachedSession();
      if (!mounted) return;
      setState(() => _state = _GateState.expired);
    }
  }

  Future<void> _openCheckout() async {
    final uri = Uri.parse(kStripePaymentUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case _GateState.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case _GateState.active:
        return const HomeScreen();
      case _GateState.notPaid:
        return StartScreen(
          onBuy: _openCheckout,
          title: 'Outfit Personality',
          subtitle:
              'Buy 3-day access and start playing instantly after payment.',
          buttonText: 'Buy 3-day access ✨',
        );
      case _GateState.expired:
        return ExpiredScreen(onBuyAgain: _openCheckout);
      case _GateState.error:
        return StartScreen(
          onBuy: _openCheckout,
          title: 'Access issue',
          subtitle: _message,
          buttonText: 'Try payment link again',
        );
    }
  }
}

class StartScreen extends StatelessWidget {
  final VoidCallback onBuy;
  final String title;
  final String subtitle;
  final String buttonText;

  const StartScreen({
    super.key,
    required this.onBuy,
    required this.title,
    required this.subtitle,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(title),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const _PastelBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "What is this?",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "A fun party game: choose 3 outfits that feel most like you — and get a stylish personality reading based on your picks.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "How access works",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const _Bullet("Access starts automatically after payment."),
                      const _Bullet("Each purchase unlocks 3 days of play."),
                      const _Bullet("If someone buys again later, they get a fresh 3-day access period."),
                      const SizedBox(height: 14),
                      Text(
                        "How to play",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const _Bullet("Tap a card to add it to the top row."),
                      const _Bullet("Tap a selected card again to remove it."),
                      const _Bullet("Pick 3 cards to reveal your result."),
                      const SizedBox(height: 14),
                      Text(
                        "Status",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _GlassCard(
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: cs.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "One payment = 3 days of access on this browser/device.",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onBuy,
                    child: Text(buttonText),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("•  "),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpiredScreen extends StatelessWidget {
  final VoidCallback onBuyAgain;

  const ExpiredScreen({super.key, required this.onBuyAgain});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          const _PastelBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 42, color: cs.primary),
                      const SizedBox(height: 12),
                      Text(
                        "Access expired",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Your 3-day access window has ended.\n\nBuy again to unlock a fresh 3-day period.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: onBuyAgain,
                          child: const Text("Buy again ✨"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------
/// HOME (PICKING)
/// --------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<OutfitCard> selected = [];
  final List<GlobalKey> slotKeys = List.generate(3, (_) => GlobalKey());
  final Map<String, GlobalKey> cardKeys = {};
  bool _animating = false;

  GlobalKey _keyForCard(OutfitCard card) {
    return cardKeys.putIfAbsent(card.id, () => GlobalKey());
  }

  Rect _globalRectFromKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return Rect.zero;
    final render = ctx.findRenderObject();
    if (render is! RenderBox) return Rect.zero;
    final offset = render.localToGlobal(Offset.zero);
    return offset & render.size;
  }

  Future<void> _sparkleBurstAt(Rect rect, int seed) async {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _BurstPainter(
                    t: curved.value,
                    center: rect.center,
                    seed: seed,
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose();
  }

  Future<void> _flyAssetBetweenMagic({
    required String asset,
    required Rect from,
    required Rect to,
    required int seed,
    BorderRadius borderRadius =
        const BorderRadius.all(Radius.circular(18)),
    Duration duration = const Duration(milliseconds: 650),
  }) async {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final controller = AnimationController(vsync: this, duration: duration);
    final curved = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = curved.value;

            final left = lerpDouble(from.left, to.left, t)!;
            final top = lerpDouble(from.top, to.top, t)!;
            final width = lerpDouble(from.width, to.width, t)!;
            final height = lerpDouble(from.height, to.height, t)!;

            final rotX = 2 * pi * t;
            final center = Offset(left + width / 2, top + height / 2);

            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _TrailSparklePainter(
                        t: t,
                        center: center,
                        seed: seed,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: width,
                  height: height,
                  child: IgnorePointer(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateX(rotX),
                      child: ClipRRect(
                        borderRadius: borderRadius,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  lerpDouble(0.18, 0.10, t)!,
                                ),
                                blurRadius: lerpDouble(18, 10, t)!,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.white,
                            child: Image.asset(asset, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    overlay.insert(entry);
    await controller.forward();
    entry.remove();
    controller.dispose();
  }

  Future<void> _selectWithAnimation(OutfitCard card) async {
    if (_animating) return;
    if (selected.contains(card)) return;
    if (selected.length >= 3) return;

    final slotIndex = selected.length;
    final from = _globalRectFromKey(_keyForCard(card));
    final to = _globalRectFromKey(slotKeys[slotIndex]);

    if (from == Rect.zero || to == Rect.zero) {
      setState(() => selected.add(card));
    } else {
      setState(() => _animating = true);

      await _flyAssetBetweenMagic(
        asset: card.frontImageAsset,
        from: from,
        to: to,
        seed: card.id.hashCode ^ DateTime.now().millisecondsSinceEpoch,
      );

      if (!mounted) return;

      setState(() {
        selected.add(card);
        _animating = false;
      });

      final landed = _globalRectFromKey(slotKeys[slotIndex]);
      if (landed != Rect.zero) {
        await _sparkleBurstAt(landed, card.id.hashCode);
      }
    }

    if (selected.length == 3 && mounted) {
      await Future.delayed(const Duration(milliseconds: 140));
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(picked: List.of(selected)),
        ),
      ).then((_) {
        if (!mounted) return;
        setState(() => selected.clear());
      });
    }
  }

  Future<void> _removeWithAnimation(OutfitCard card) async {
    if (_animating) return;

    final index = selected.indexOf(card);
    if (index == -1) return;

    final from = _globalRectFromKey(slotKeys[index]);
    final to = _globalRectFromKey(_keyForCard(card));

    if (from == Rect.zero || to == Rect.zero) {
      setState(() => selected.remove(card));
      return;
    }

    setState(() => _animating = true);

    await _flyAssetBetweenMagic(
      asset: card.frontImageAsset,
      from: from,
      to: to,
      seed: (card.id.hashCode * 31) ^ DateTime.now().millisecondsSinceEpoch,
      duration: const Duration(milliseconds: 600),
    );

    if (!mounted) return;

    setState(() {
      selected.remove(card);
      _animating = false;
    });

    if (to != Rect.zero) {
      await _sparkleBurstAt(to, card.id.hashCode ^ 999);
    }
  }

  void _handleGridCardTap(OutfitCard card) {
    if (_animating) return;

    final isSelected = selected.contains(card);
    if (isSelected) {
      _removeWithAnimation(card);
    } else {
      _selectWithAnimation(card);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text("Choose 3 outfits"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const _PastelBackground(),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Pick three cards.\nTap a selected card again to remove it.",
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.85),
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: cs.primary.withOpacity(0.12),
                            border: Border.all(
                              color: cs.primary.withOpacity(0.22),
                            ),
                          ),
                          child: Text(
                            "${selected.length}/3",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(color: cs.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (i) {
                      final has = i < selected.length;
                      final card = has ? selected[i] : null;

                      return _Slot(
                        key: slotKeys[i],
                        hasCard: has,
                        onTap: (!has || _animating)
                            ? null
                            : () => _removeWithAnimation(card!),
                        child: has
                            ? _LuxuryCardImage(asset: card!.frontImageAsset)
                            : const SizedBox.shrink(),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text(
                        "All outfits",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        _animating ? "✨ magic..." : "scroll",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.55),
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: cards.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 0.70,
                    ),
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      final isSelected = selected.contains(card);

                      return GestureDetector(
                        onTap: _animating ? null : () => _handleGridCardTap(card),
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: isSelected ? 0.28 : 1,
                          child: ClipRRect(
                            key: _keyForCard(card),
                            borderRadius: BorderRadius.circular(18),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: _LuxuryCardImage(
                                asset: card.frontImageAsset,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------
/// LONGER RESULT
/// --------------------
class ResultScreen extends StatelessWidget {
  final List<OutfitCard> picked;

  const ResultScreen({super.key, required this.picked});

  String _firstSentence(String text) {
    final t = text.trim();
    if (t.isEmpty) return "";
    final idx = t.indexOf('.');
    if (idx == -1) return t;
    return t.substring(0, idx + 1).trim();
  }

  List<String> _traitsFromFirstSentence(String sentence) {
    var s = sentence.trim();
    s = s.replaceFirst(RegExp(r'^You are\s+', caseSensitive: false), '');
    s = s.replaceAll('.', '').trim();

    return s
        .split(',')
        .expand((p) => p.split(RegExp(r'\s+and\s+', caseSensitive: false)))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _pickToneLine(List<String> traitsLower) {
    if (traitsLower.any(
      (t) => t.contains('command') ||
          t.contains('authorit') ||
          t.contains('decis'),
    )) {
      return "You walk in like a headline — and somehow the room agrees.";
    }
    if (traitsLower.any(
      (t) => t.contains('romantic') ||
          t.contains('luminous') ||
          t.contains('gentle'),
    )) {
      return "You don’t chase attention — you *attract* it.";
    }
    if (traitsLower.any(
      (t) => t.contains('playful') ||
          t.contains('upbeat') ||
          t.contains('energetic'),
    )) {
      return "Your vibe says: fun first, overthinking never.";
    }
    return "You make good taste look effortless — which is honestly unfair.";
  }

  String buildLongSummary() {
    final titles = picked.map((c) => c.title).toList();

    final traits = <String>[];
    for (final c in picked) {
      traits.addAll(_traitsFromFirstSentence(_firstSentence(c.description)));
    }

    final seen = <String>{};
    final uniqueTraits = <String>[];
    for (final t in traits) {
      final k = t.toLowerCase();
      if (seen.add(k)) uniqueTraits.add(t);
    }

    final traitsLower = uniqueTraits.map((e) => e.toLowerCase()).toList();

    final headline =
        "Your style signature blends ${titles[0]}, ${titles[1]}, and ${titles[2]}.";

    final core = uniqueTraits.isEmpty
        ? "At your core, you’re a rare mix of taste and personality — the kind that doesn’t need validation to feel certain."
        : "At your core, you’re ${uniqueTraits.take(3).join(', ')} — with a calm confidence that reads as ‘intentional’ in every room you enter.";

    final social =
        "Socially, you move with purpose. You know when to be warm, when to be sharp, and when to simply let the outfit do the talking. People feel your presence before you even speak — in the best way.";

    final relationships =
        "In friendships (and flirtation), you’re the one who sets the tone: you elevate plans, you notice details, and you bring a polished energy that makes everything feel curated — even if it was spontaneous.";

    final bullets = uniqueTraits.isEmpty
        ? "• Signature trait: effortlessly memorable\n• Strength: tasteful confidence\n• Hidden talent: setting the vibe"
        : "• Signature traits: ${uniqueTraits.take(2).join(' + ')}\n• Strength: ${uniqueTraits.length >= 3 ? uniqueTraits[2] : uniqueTraits.first}\n• Bonus power: main-character energy (quietly).";

    final finish = _pickToneLine(traitsLower);

    return "$headline\n\n$core\n\n$social\n\n$relationships\n\n$bullets\n\n$finish";
  }

  @override
  Widget build(BuildContext context) {
    final summary = buildLongSummary();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text("Your Personality ✨"),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const _PastelBackground(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: picked
                            .map(
                              (c) => ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  c.frontImageAsset,
                                  width: 92,
                                  height: 130,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your vibe",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        summary,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Play again 🔁"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// --------------------
/// VISUALS
/// --------------------
class _PastelBackground extends StatelessWidget {
  const _PastelBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF1F7),
            Color(0xFFF7F3FF),
            Color(0xFFEFF9FF),
          ],
        ),
      ),
      child: Align(
        alignment: const Alignment(0.9, -0.9),
        child: Container(
          width: 240,
          height: 240,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Color(0xFFFF6FAE).withOpacity(0.18),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.62),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  final bool hasCard;
  final VoidCallback? onTap;
  final Widget child;

  const _Slot({
    super.key,
    required this.hasCard,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 104,
            height: 146,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(hasCard ? 0.52 : 0.42),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hasCard
                    ? cs.primary.withOpacity(0.22)
                    : Colors.white.withOpacity(0.7),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: hasCard
                ? child
                : Center(
                    child: Icon(
                      Icons.add_rounded,
                      size: 26,
                      color: cs.onSurface.withOpacity(0.25),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _LuxuryCardImage extends StatelessWidget {
  final String asset;

  const _LuxuryCardImage({required this.asset});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  Colors.white.withOpacity(0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// --------------------
/// SPARKLES
/// --------------------
class _TrailSparklePainter extends CustomPainter {
  final double t;
  final Offset center;
  final int seed;

  _TrailSparklePainter({
    required this.t,
    required this.center,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (t < 0.18)
        ? (t / 0.18)
        : (t > 0.88)
            ? ((1 - t) / 0.12).clamp(0.0, 1.0)
            : 1.0;

    final rng = Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;
    final count = (14 * (1.0 - t * 0.2)).round();

    for (int i = 0; i < count; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final baseR = lerpDouble(14, 36, rng.nextDouble())!;
      final drift = lerpDouble(0, 22, t)!;
      final radius = baseR + drift * rng.nextDouble();
      final p = center + Offset(cos(angle), sin(angle)) * radius;

      final s = lerpDouble(2.0, 5.0, rng.nextDouble())!;
      final twinkle = (0.6 + 0.4 * sin((t * 6 + rng.nextDouble() * 2) * pi))
          .clamp(0.0, 1.0);

      const palette = [
        Color(0xFFFF6FAE),
        Color(0xFF7C6BFF),
        Color(0xFF7AD7FF),
      ];
      final c = palette[rng.nextInt(palette.length)];

      paint.color = c.withOpacity(0.52 * fade * twinkle);
      _drawStar(canvas, p, s, paint, points: rng.nextBool() ? 4 : 5);
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint,
      {int points = 5}) {
    final path = Path();
    final inner = r * 0.45;
    final step = pi / points;

    for (int i = 0; i < points * 2; i++) {
      final rr = i.isEven ? r : inner;
      final a = i * step - pi / 2;
      final x = c.dx + cos(a) * rr;
      final y = c.dy + sin(a) * rr;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailSparklePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.center != center ||
        oldDelegate.seed != seed;
  }
}

class _BurstPainter extends CustomPainter {
  final double t;
  final Offset center;
  final int seed;

  _BurstPainter({
    required this.t,
    required this.center,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random(seed);
    final paint = Paint()..style = PaintingStyle.fill;

    final fade = (1 - t).clamp(0.0, 1.0);
    final radius = lerpDouble(0, 58, Curves.easeOutCubic.transform(t))!;

    const palette = [
      Color(0xFFFF6FAE),
      Color(0xFF7C6BFF),
      Color(0xFF7AD7FF),
    ];

    for (int i = 0; i < 22; i++) {
      final a = rng.nextDouble() * 2 * pi;
      final r = radius * (0.5 + rng.nextDouble() * 0.5);
      final p = center + Offset(cos(a), sin(a)) * r;

      final s = lerpDouble(5.5, 1.2, t)! * (0.6 + rng.nextDouble() * 0.6);
      paint.color =
          palette[rng.nextInt(palette.length)].withOpacity(0.55 * fade);

      if (rng.nextDouble() < 0.3) {
        _drawStar(canvas, p, s, paint, points: 5);
      } else {
        canvas.drawCircle(p, s, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint,
      {int points = 5}) {
    final path = Path();
    final inner = r * 0.45;
    final step = pi / points;

    for (int i = 0; i < points * 2; i++) {
      final rr = i.isEven ? r : inner;
      final a = i * step - pi / 2;
      final x = c.dx + cos(a) * rr;
      final y = c.dy + sin(a) * rr;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.center != center ||
        oldDelegate.seed != seed;
  }
}