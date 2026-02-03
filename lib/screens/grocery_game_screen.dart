import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';

class GroceryGameScreen extends StatefulWidget {
  final String language;

  const GroceryGameScreen({super.key, required this.language});

  @override
  State<GroceryGameScreen> createState() => _GroceryGameScreenState();
}

class _GroceryGameScreenState extends State<GroceryGameScreen>
    with TickerProviderStateMixin {
  final FlutterTts tts = FlutterTts();
  final AudioPlayer audioPlayer = AudioPlayer();
  final Random random = Random();

  // ---------------- DATA ----------------
  final List<String> languages = ['English', 'Hindi', 'Nepali'];
  late String selectedLanguage;

  final List<int> availableNotes = [5, 10, 20, 50, 100, 500];

  final List<Map<String, dynamic>> products = [
    {
      "image": "assets/products/rice.png",
      "name": "Rice",
      "name_hi": "चावल",
      "name_ne": "चामल"
    },
    {
      "image": "assets/products/biscuit.png",
      "name": "Biscuit",
      "name_hi": "बिस्कुट",
      "name_ne": "बिस्कुट"
    },
    {
      "image": "assets/products/milk.png",
      "name": "Milk",
      "name_hi": "दूध",
      "name_ne": "दूध"
    },
    {
      "image": "assets/products/soap.png",
      "name": "Soap",
      "name_hi": "साबुन",
      "name_ne": "साबुन"
    },
    {
      "image": "assets/products/chips.png",
      "name": "Chips",
      "name_hi": "चिप्स",
      "name_ne": "चिप्स"
    },
    {
      "image": "assets/products/bread.png",
      "name": "Bread",
      "name_hi": "ब्रेड",
      "name_ne": "ब्रेड"
    },
  ];

  late Map<String, dynamic> currentProduct;
  int currentPrice = 0;
  int currentMoneyGiven = 0;
  List<int> notesOnCounter = [];

  // Game State
  int score = 0;
  int level = 1;
  int correctInRow = 0;
  List<Widget> flyingMoneyWidgets = [];

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.language;

    if (!languages.contains(selectedLanguage)) {
      if (selectedLanguage == 'hi')
        selectedLanguage = 'Hindi';
      else if (selectedLanguage == 'ne')
        selectedLanguage = 'Nepali';
      else
        selectedLanguage = 'English';
    }

    _nextProduct();
  }

  // ---------------- LOGIC ----------------

  void _generatePriceForLevel() {
    List<int> possiblePrices = [];

    if (level == 1) {
      possiblePrices = availableNotes;
    } else if (level == 2) {
      for (int a in availableNotes) {
        for (int b in availableNotes) {
          int sum = a + b;
          if (sum <= 200 && !possiblePrices.contains(sum))
            possiblePrices.add(sum);
        }
      }
      for (int n in availableNotes) {
        if (n > 20 && !possiblePrices.contains(n)) possiblePrices.add(n);
      }
    } else {
      for (int a in availableNotes) {
        for (int b in availableNotes) {
          for (int c in availableNotes) {
            int sum = a + b + c;
            if (sum <= 500 && !possiblePrices.contains(sum))
              possiblePrices.add(sum);
          }
        }
      }
    }

    if (possiblePrices.isNotEmpty) {
      currentPrice = possiblePrices[random.nextInt(possiblePrices.length)];
    } else {
      currentPrice = 10;
    }
  }

  void _nextProduct() {
    setState(() {
      currentProduct = products[random.nextInt(products.length)];
      _generatePriceForLevel();
      currentMoneyGiven = 0;
      notesOnCounter.clear();
    });
    _speakPrice();
  }

  void _playSound(String fileName) {
    try {
      audioPlayer.play(AssetSource('sounds/$fileName'));
    } catch (e) {
      // Ignore
    }
  }

  void _changeLevel(int newLevel) {
    setState(() {
      level = newLevel;
      correctInRow = 0;
    });
    _nextProduct();
  }

  void _triggerFlyAnimation(int amount) {
    int maxNotesAllowed = level;

    if (notesOnCounter.length >= maxNotesAllowed) {
      String warning = "";
      if (selectedLanguage == "Hindi")
        warning = "केवल $maxNotesAllowed नोट का उपयोग करें!";
      else if (selectedLanguage == "Nepali")
        warning = "$maxNotesAllowed नोट मात्र प्रयोग गर्नुहोस्!";
      else
        warning = "Only $maxNotesAllowed notes allowed!";

      tts.speak(warning);
      return;
    }

    _playSound("coin.mp3");
    Key key = UniqueKey();

    setState(() {
      flyingMoneyWidgets.add(
        Positioned(
          key: key,
          bottom: 50,
          left: MediaQuery.of(context).size.width / 2 - 70,
          child: TweenAnimationBuilder(
            tween:
                Tween<Offset>(begin: Offset.zero, end: const Offset(0, -350)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, Offset offset, child) {
              return Transform.translate(
                offset: offset,
                child: Opacity(
                  opacity: 1.0 - (offset.dy / -400).abs().clamp(0.0, 1.0),
                  child:
                      Image.asset("assets/money/money_$amount.jpg", width: 140),
                ),
              );
            },
            onEnd: () {
              setState(() {
                flyingMoneyWidgets.removeWhere((w) => w.key == key);
                currentMoneyGiven += amount;
                notesOnCounter.add(amount);
              });
            },
          ),
        ),
      );
    });
  }

  void _confirmPayment() {
    if (currentMoneyGiven == 0) {
      _speakText("Please put money on counter");
      return;
    }

    if (currentMoneyGiven < currentPrice) {
      _speakText("Not enough money");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Not enough money!", style: TextStyle(fontSize: 16)),
          backgroundColor: Colors.red));
      return;
    }

    if (currentMoneyGiven == currentPrice) {
      _playSound("success.mp3");
      _handleWin(0);
    } else {
      int change = currentMoneyGiven - currentPrice;
      _playSound("success.mp3");
      _handleWin(change);
    }
  }

  void _speakText(String enText) async {
    String text = enText;
    if (selectedLanguage == 'Hindi') {
      if (enText.contains("Not enough")) text = "पैसे कम हैं";
      if (enText.contains("Please put")) text = "कृपया पैसे रखें";
    } else if (selectedLanguage == 'Nepali') {
      if (enText.contains("Not enough")) text = "पैसा पुगेन";
      if (enText.contains("Please put")) text = "कृपया पैसा राख्नुहोस्";
    }
    await tts.speak(text);
  }

  void _handleWin(int change) {
    setState(() {
      score += 10;
      correctInRow++;

      if (correctInRow >= 5 && level < 3) {
        level++;
        correctInRow = 0;
        _showLevelUpDialog();
        return;
      }
    });

    _showResult(true, change);
  }

  void _resetCurrentRound() {
    setState(() {
      currentMoneyGiven = 0;
      notesOnCounter.clear();
    });
  }

  List<int> _getChangeNotes(int amount) {
    List<int> changeNotes = [];
    List<int> sortedNotes = List.from(availableNotes)
      ..sort((a, b) => b.compareTo(a));

    for (int note in sortedNotes) {
      if (amount >= note) {
        int count = amount ~/ note;
        for (int i = 0; i < count; i++) {
          changeNotes.add(note);
        }
        amount %= note;
      }
    }
    return changeNotes;
  }

  // ---------------- TTS ----------------
  Future<void> _speakPrice() async {
    String textToSpeak = "";
    if (selectedLanguage == 'English') {
      await tts.setLanguage("en-US");
      textToSpeak = "${currentProduct['name']} costs $currentPrice rupees";
    } else if (selectedLanguage == 'Hindi') {
      await tts.setLanguage("hi-IN");
      textToSpeak =
          "${currentProduct['name_hi']} की कीमत $currentPrice रुपये है";
    } else if (selectedLanguage == 'Nepali') {
      await tts.setLanguage("ne-NP");
      textToSpeak =
          "${currentProduct['name_ne']} को मूल्य $currentPrice रुपैयाँ हो";
    }
    await tts.speak(textToSpeak);
  }

  Future<void> _speakResult(bool correct, int change) async {
    String text = "";
    if (correct) {
      if (change > 0) {
        if (selectedLanguage == 'English')
          text = "Good! Take $change rupees change.";
        else if (selectedLanguage == 'Hindi')
          text = "बहुत अच्छे! $change रुपये वापस लो।";
        else
          text = "राम्रो! $change रुपैयाँ फिर्ता लिनुहोस्।";
      } else {
        if (selectedLanguage == 'English')
          text = "Good Job! Exact amount.";
        else if (selectedLanguage == 'Hindi')
          text = "बहुत अच्छे! सही पैसे।";
        else
          text = "धेरै राम्रो! सही रकम।";
      }
    }
    await tts.speak(text);
  }

  void _cycleLanguage() {
    setState(() {
      int index = languages.indexOf(selectedLanguage);
      selectedLanguage = languages[(index + 1) % languages.length];
    });
    _speakPrice();
  }

  void _showLevelUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.amber, width: 3)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 80),
                const SizedBox(height: 10),
                const Text("LEVEL UP!",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black)),
                Text("Now Level $level",
                    style: const TextStyle(fontSize: 20, color: Colors.grey)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _nextProduct();
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text("Start Next Level",
                      style: TextStyle(color: Colors.black)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showResult(bool correct, int change) {
    _speakResult(correct, change);
    List<int> changeNotes = change > 0 ? _getChangeNotes(change) : [];

    String shopImage = "assets/shop/shopkeeper_happy.png";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 3)),
                  child: ClipOval(
                    child: Image.asset(shopImage,
                        height: 80, width: 80, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  change > 0 ? "Change: ₹$change" : "Exact Amount!",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                if (change > 0) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                    child: Text("Shopkeeper gives back:",
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500)),
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 5,
                    runSpacing: 5,
                    children: changeNotes.map((note) {
                      return Image.asset(
                        "assets/money/money_$note.jpg",
                        width: 70,
                        fit: BoxFit.contain,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _nextProduct();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  child: const Text("Next Item"),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- UI (FULLY ADAPTIVE FIX) ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                "Shop ($selectedLanguage)",
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    shadows: [Shadow(color: Colors.black, blurRadius: 5)]),
              ),
            ),

            // LEVEL
            PopupMenuButton<int>(
              onSelected: _changeLevel,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 1, child: Text("Level 1 (Easy)")),
                const PopupMenuItem(value: 2, child: Text("Level 2 (Medium)")),
                const PopupMenuItem(value: 3, child: Text("Level 3 (Hard)")),
              ],
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Row(
                  children: [
                    Text("Lvl $level",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                    const Icon(Icons.arrow_drop_down,
                        color: Colors.white, size: 20)
                  ],
                ),
              ),
            ),

            // SCORE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white)),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 18),
                  const SizedBox(width: 5),
                  Text("$score",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black)),
                ],
              ),
            )
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: _cycleLanguage,
            tooltip: "Change Language",
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            "assets/shop/shop_bg.jpg",
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.3),
            colorBlendMode: BlendMode.darken,
          ),

          // Main Layout - Using Expanded/Flexible to fit ANY screen
          SafeArea(
            child: Column(
              children: [
                // 1. PRODUCT (35% of space)
                Expanded(
                  flex: 35,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1.5),
                                boxShadow: [
                                  const BoxShadow(
                                      blurRadius: 10, color: Colors.black12)
                                ]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.asset(currentProduct["image"],
                                  fit: BoxFit.cover),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                selectedLanguage == 'English'
                                    ? currentProduct['name']
                                    : selectedLanguage == 'Hindi'
                                        ? currentProduct['name_hi']
                                        : currentProduct['name_ne'],
                                style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                          color: Colors.black, blurRadius: 10)
                                    ]),
                              ),
                              const SizedBox(width: 15),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(30),
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: Text(
                                  "Price: ₹$currentPrice",
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                // 2. COUNTER AREA (35% of space)
                Expanded(
                  flex: 35,
                  child: Container(
                    width: double.infinity,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1.5)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        FittedBox(
                          child: Text("Money on Counter: ₹$currentMoneyGiven",
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        Text("Max Notes: $level",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11)),
                        const Divider(color: Colors.white54, height: 8),

                        // NOTES STACK
                        Expanded(
                          child: LayoutBuilder(builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: max(constraints.maxWidth,
                                    (notesOnCounter.length * 40.0) + 100),
                                height: constraints.maxHeight,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: List.generate(notesOnCounter.length,
                                      (index) {
                                    return Positioned(
                                      left: index * 40.0,
                                      top: 0,
                                      bottom: 0,
                                      child: Image.asset(
                                        "assets/money/money_${notesOnCounter[index]}.jpg",
                                        fit: BoxFit.contain,
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          }),
                        ),

                        // ACTION BUTTONS
                        FittedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: currentMoneyGiven > 0
                                    ? _resetCurrentRound
                                    : null,
                                icon: const Icon(Icons.refresh,
                                    color: Colors.white, size: 18),
                                label: const Text("Clear"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton.icon(
                                onPressed: currentMoneyGiven > 0
                                    ? _confirmPayment
                                    : null,
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.white, size: 18),
                                label: const Text("PAY"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                // 3. WALLET AREA (30% of space)
                Expanded(
                  flex: 30,
                  child: Container(
                    color: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FittedBox(
                          child: Text("Tap notes to put on counter:",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 4)
                                  ])),
                        ),
                        const SizedBox(height: 5),
                        Expanded(
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            children: availableNotes.map((amount) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                child: GestureDetector(
                                  onTap: () => _triggerFlyAnimation(amount),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Dynamic scaling image
                                        Flexible(
                                          child: Image.asset(
                                              "assets/money/money_$amount.jpg",
                                              fit: BoxFit.contain),
                                        ),
                                        const SizedBox(height: 2),
                                        Text("₹$amount",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.white))
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. ANIMATION LAYER
          ...flyingMoneyWidgets,
        ],
      ),
    );
  }
}
