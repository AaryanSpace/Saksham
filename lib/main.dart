// ================= IMPORTS =================
import 'dart:ui'; // Required for Glass Blur
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

// Import your existing Grocery Game Screen
import 'screens/grocery_game_screen.dart';

// ================= THEME: MIDNIGHT GLASS =================
class AppTheme {
  static const Color bgTop = Color(0xFF2E3192); // Deep Indigo
  static const Color bgBottom = Color(0xFF1BFFFF); // Cyan Accent

  static const Color accentPink = Color(0xFFFF4081);
  static const Color accentYellow = Color(0xFFFFD740);
  static const Color accentGreen = Color(0xFF69F0AE);
  static const Color accentCyan = Color(0xFF00E5FF);
}

// ================= GLOBAL HELPERS & REAL-TIME STATS =================
final FlutterTts tts = FlutterTts();
final AudioPlayer audioPlayer = AudioPlayer();
String currentLanguage = "en-US";

class PlayerStats {
  static int xp = 0;
  static int tasksCompleted = 0;
  static int level = 1;

  static void addXP(int amount) {
    xp += amount;
    tasksCompleted++;
    if (xp >= level * 100) {
      level++;
    }
  }
}

Future<void> speak(String text) async {
  await tts.setLanguage(currentLanguage);
  await tts.setSpeechRate(0.4);
  await tts.speak(text);
}

// Fixed: Added simple sound player helper
void playSound(String fileName) async {
  try {
    await audioPlayer.play(AssetSource('sounds/$fileName'));
  } catch (e) {
    // Ignore if sound file missing
  }
}

String getLocalizedNumber(int number) {
  if (currentLanguage == 'en-US') return number.toString();
  const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
  const devanagari = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
  String num = number.toString();
  for (int i = 0; i < 10; i++) {
    num = num.replaceAll(english[i], devanagari[i]);
  }
  return num;
}

// ================= WIDGET: GLASS CARD =================
class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isInteractive;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 24,
    this.padding,
    this.isInteractive = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // FIXED: Replaced withOpacity with withValues for new Flutter versions
              color: color ?? Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                if (isInteractive)
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: -5,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ================= WIDGET: BACKGROUND WRAPPER =================
class BackgroundWrapper extends StatelessWidget {
  final Widget child;
  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purple.withValues(alpha: 0.3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.4),
                          blurRadius: 100)
                    ])),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blueAccent.withValues(alpha: 0.3),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.4),
                          blurRadius: 100)
                    ])),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

// ================= WIDGET: LANGUAGE BUTTON =================
class LanguageButton extends StatelessWidget {
  final VoidCallback onChanged;
  const LanguageButton({super.key, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: InkWell(
          onTap: () {
            if (currentLanguage == "en-US") {
              currentLanguage = "hi-IN";
              speak("हिंदी");
            } else if (currentLanguage == "hi-IN") {
              currentLanguage = "ne-NP";
              speak("नेपाली");
            } else {
              currentLanguage = "en-US";
              speak("English");
            }
            onChanged();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  currentLanguage == "en-US"
                      ? "EN"
                      : (currentLanguage == "hi-IN" ? "HI" : "NE"),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= MAIN APP START =================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const LifeLearningApp());
}

class LifeLearningApp extends StatelessWidget {
  const LifeLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Life Learning',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

// ================= HOME SCREEN =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedPeriod = "Today";

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
        .then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWrapper(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Hello, Pro 👋",
                          style:
                              TextStyle(fontSize: 16, color: Colors.white70)),
                      Text("Dashboard",
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                  LanguageButton(onChanged: () => setState(() {})),
                ],
              ),
            ),

            // GRID MENU
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _buildHomeCard(
                        Icons.pie_chart_rounded, "Count", Colors.purpleAccent,
                        () {
                      speak("Counting");
                      _navigateTo(const CountingScreen());
                    }),
                    _buildHomeCard(Icons.account_balance_wallet_rounded,
                        "Wallet", Colors.greenAccent, () {
                      speak("Money Practice");
                      _navigateTo(const MoneyScreen());
                    }),
                    _buildHomeCard(Icons.shopping_cart_rounded, "Market",
                        Colors.orangeAccent, () {
                      speak("Shopping");
                      _navigateTo(GroceryGameScreen(language: currentLanguage));
                    }),
                    _buildHomeCard(
                        Icons.public_rounded, "Travel", Colors.cyanAccent, () {
                      speak("Travel");
                      _navigateTo(const TravelScreen());
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // STATS PLATE
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: ["Today", "7 Days", "30 Days"].map((period) {
                        final bool isSelected = selectedPeriod == period;
                        return GestureDetector(
                          onTap: () => setState(() => selectedPeriod = period),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.accentCyan
                                  : Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              period,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.black
                                      : Colors.white60,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: (PlayerStats.xp % 100) / 100,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.white10,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          AppTheme.accentPink),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text("LVL",
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.white54)),
                                  Text("${PlayerStats.level}",
                                      style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMiniStat(
                                  "XP Gained",
                                  "${PlayerStats.xp}",
                                  AppTheme.accentYellow,
                                  (PlayerStats.xp % 1000) / 1000),
                              const SizedBox(height: 15),
                              _buildMiniStat(
                                  "Tasks",
                                  "${PlayerStats.tasksCompleted}",
                                  AppTheme.accentGreen,
                                  (PlayerStats.tasksCompleted % 50) / 50),
                            ],
                          ),
                        )
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard(
      IconData icon, String label, Color glowColor, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: glowColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: glowColor.withValues(alpha: 0.4), blurRadius: 15)
              ],
            ),
            child: Icon(icon, size: 30, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      String label, String value, Color color, double percent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        )
      ],
    );
  }
}

// ================= SCREEN 1: COUNTING =================
class CountingScreen extends StatefulWidget {
  const CountingScreen({super.key});
  @override
  State<CountingScreen> createState() => _CountingScreenState();
}

class _CountingScreenState extends State<CountingScreen> {
  int start = 1;
  int targetNumber = 0;
  final Random random = Random();
  bool isLearningMode = true;
  Map<int, Color> cardColors = {};

  @override
  void initState() {
    super.initState();
    _pickRandomTarget();
  }

  void _pickRandomTarget() {
    setState(() {
      cardColors.clear();
      targetNumber = start + random.nextInt(10);
    });
    if (!isLearningMode) {
      speak(currentLanguage == "en-US"
          ? "Find $targetNumber"
          : getLocalizedNumber(targetNumber));
    }
  }

  List<int> get currentNumbers => List.generate(10, (index) => start + index);

  void onNumberTap(int number) async {
    if (isLearningMode) {
      speak(getLocalizedNumber(number));
      setState(() =>
          cardColors[number] = AppTheme.accentPink.withValues(alpha: 0.5));
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => cardColors.remove(number));
    } else {
      if (number == targetNumber) {
        PlayerStats.addXP(10);
        setState(() => cardColors[number] = AppTheme.accentGreen);
        speak("Correct!");
        await Future.delayed(const Duration(milliseconds: 1000));
        _pickRandomTarget();
      } else {
        setState(() => cardColors[number] = Colors.redAccent);
        speak("Try again");
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() => cardColors.remove(number));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
            "${getLocalizedNumber(start)} - ${getLocalizedNumber(start + 9)}",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [LanguageButton(onChanged: () => setState(() {}))],
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: BackgroundWrapper(
        child: Column(
          children: [
            const SizedBox(height: 56),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
              child: GlassCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isLearningMode
                          ? (currentLanguage == "en-US"
                              ? "Tap to Learn"
                              : "सीखें")
                          : (currentLanguage == "en-US"
                              ? "Find: $targetNumber"
                              : "खोजें: ${getLocalizedNumber(targetNumber)}"),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Switch(
                      value: !isLearningMode,
                      onChanged: (val) => setState(() {
                        isLearningMode = !val;
                        _pickRandomTarget();
                      }),
                      activeColor: AppTheme.accentYellow,
                    )
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.2,
                ),
                itemCount: currentNumbers.length,
                itemBuilder: (context, index) {
                  final number = currentNumbers[index];
                  final bool isSelected = cardColors.containsKey(number);
                  return GlassCard(
                    onTap: () => onNumberTap(number),
                    color: isSelected ? cardColors[number] : null,
                    child: Center(
                      child: Text(
                        getLocalizedNumber(number),
                        style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.blueAccent,
                                  blurRadius: 15)
                            ]),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                      child: GlassCard(
                          onTap: () => setState(() {
                                if (start > 1) start -= 10;
                                _pickRandomTarget();
                              }),
                          child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                  child: Icon(Icons.arrow_back_ios,
                                      color: Colors.white))))),
                  const SizedBox(width: 20),
                  Expanded(
                      child: GlassCard(
                          onTap: () => setState(() {
                                if (start < 91) start += 10;
                                _pickRandomTarget();
                              }),
                          child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(
                                  child: Icon(Icons.arrow_forward_ios,
                                      color: Colors.white))))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ================= SCREEN 2: MONEY =================
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});
  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final Random random = Random();
  late Map<String, dynamic> targetNote;
  List<bool> noteSides = [];
  int? _animatingIndex;

  final List<Map<String, dynamic>> allNotes = [
    {
      "value": 5,
      "front": "assets/notes/front/5.jpg",
      "back": "assets/notes/back/5.jpg"
    },
    {
      "value": 10,
      "front": "assets/notes/front/10.jpg",
      "back": "assets/notes/back/10.jpg"
    },
    {
      "value": 20,
      "front": "assets/notes/front/20.jpg",
      "back": "assets/notes/back/20.jpg"
    },
    {
      "value": 50,
      "front": "assets/notes/front/50.jpg",
      "back": "assets/notes/back/50.jpg"
    },
    {
      "value": 100,
      "front": "assets/notes/front/100.jpg",
      "back": "assets/notes/back/100.jpg"
    },
    {
      "value": 500,
      "front": "assets/notes/front/500.jpg",
      "back": "assets/notes/back/500.jpg"
    },
  ];

  @override
  void initState() {
    super.initState();
    _pickRandomNote();
  }

  void _pickRandomNote() {
    setState(() {
      targetNote = allNotes[random.nextInt(allNotes.length)];
      noteSides = List.generate(allNotes.length, (index) => random.nextBool());
    });

    speak(currentLanguage == "en-US"
        ? "Find ${targetNote['value']} rupees"
        : (currentLanguage == "hi-IN"
            ? "${targetNote['value']} रुपये खोजें"
            : "${targetNote['value']} रुपैयाँ खोज्नुहोस्"));
  }

  void _handleTap(int index, int value) async {
    setState(() {
      _animatingIndex = index;
    });
    await Future.delayed(const Duration(milliseconds: 150));
    _checkAnswer(value);
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted)
      setState(() {
        _animatingIndex = null;
      });
  }

  void _checkAnswer(int value) {
    if (value == targetNote['value']) {
      PlayerStats.addXP(50);
      speak("Correct!");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Correct! +50 XP",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: AppTheme.accentGreen,
          duration: Duration(milliseconds: 500)));
      Future.delayed(const Duration(milliseconds: 1000), _pickRandomNote);
    } else {
      speak("Try again");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Money Practice"),
        actions: [
          LanguageButton(
              onChanged: () => setState(() {
                    _pickRandomNote();
                  }))
        ],
      ),
      body: BackgroundWrapper(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      currentLanguage == "en-US"
                          ? "Find: ₹${targetNote['value']}"
                          : "खोजें: ₹${getLocalizedNumber(targetNote['value'])}",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Opacity(
                      opacity: 0.8,
                      child: Image.asset(targetNote['front'],
                          height: 60, fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                itemCount: allNotes.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 35),
                itemBuilder: (ctx, i) {
                  final note = allNotes[i];
                  final bool showFront = noteSides[i];
                  final String imagePath =
                      showFront ? note['front'] : note['back'];
                  final bool isAnimating = _animatingIndex == i;

                  return Center(
                    child: GestureDetector(
                      onTap: () => _handleTap(i, note['value']),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeOutBack,
                        transform: Matrix4.identity()
                          ..scale(isAnimating ? 1.15 : 1.0)
                          ..rotateZ(
                              isAnimating ? (i % 2 == 0 ? 0.05 : -0.05) : 0),
                        decoration: BoxDecoration(
                            color: Colors.transparent,
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 25,
                                  offset: const Offset(0, 15))
                            ]),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              imagePath,
                              height: 180,
                              fit: BoxFit.contain,
                              errorBuilder: (c, o, s) => const Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.white54),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "₹${getLocalizedNumber(note['value'])}",
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black54, blurRadius: 10)
                                  ]),
                            )
                          ],
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
    );
  }
}

// ================= SCREEN 3: TRAVEL =================
class TravelScreen extends StatefulWidget {
  const TravelScreen({super.key});
  @override
  State<TravelScreen> createState() => _TravelScreenState();
}

class _TravelScreenState extends State<TravelScreen> {
  final List<Map<String, dynamic>> vehicles = [
    {
      "name": "Bus",
      "icon": Icons.directions_bus,
      "sound": "Bus goes Honk Honk!"
    },
    {"name": "Train", "icon": Icons.train, "sound": "Train goes Choo Choo!"},
    {"name": "Taxi", "icon": Icons.local_taxi, "sound": "Taxi says Beep Beep!"},
    {"name": "Bike", "icon": Icons.pedal_bike, "sound": "Bike goes Ring Ring!"},
  ];

  int? _shakingIndex;

  void _playVehicle(int index, String name, String sound) {
    PlayerStats.addXP(5);
    setState(() => _shakingIndex = index);
    speak(name);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _shakingIndex = null);
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      speak(sound);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Travel Mode",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [LanguageButton(onChanged: () => setState(() {}))],
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: BackgroundWrapper(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                ),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  final bool isShaking = _shakingIndex == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    transform: Matrix4.identity()
                      ..translate(
                          isShaking ? (index % 2 == 0 ? 5.0 : -5.0) : 0.0),
                    child: GlassCard(
                      onTap: () => _playVehicle(index, v['name'], v['sound']),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(v['icon'], size: 60, color: AppTheme.accentPink),
                          const SizedBox(height: 15),
                          Text(v['name'],
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
