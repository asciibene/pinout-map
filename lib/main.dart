import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  runApp(const PinoutApp());
}

class PinoutApp extends StatelessWidget {
  const PinoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pinout Pocket',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blueGrey,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const BoardListScreen(),
    );
  }
}

class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox(
        height: 50,
        width: double.infinity,
      );
    }

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}

// --- MODELS ---
class Pin {
  final int number;
  final String name;
  final String type;
  final String description;

  const Pin({
    required this.number,
    required this.name,
    required this.type,
    required this.description,
  });

  factory Pin.fromJson(Map<String, dynamic> json, {required String context}) {
    return Pin(
      number: _requiredInt(json, 'number', context: context),
      name: _requiredString(json, 'name', context: context),
      type: _requiredString(json, 'type', context: context),
      description: _requiredString(json, 'description', context: context),
    );
  }
}

class Board {
  final String id;
  final String name;
  final String category;
  final String microcontroller;
  final String imageAsset;
  final List<Pin> pins;

  const Board({
    required this.id,
    required this.name,
    required this.category,
    required this.microcontroller,
    required this.imageAsset,
    required this.pins,
  });

  factory Board.fromJson(Map<String, dynamic> json) {
    final pins = json['pins'];
    if (pins is! List) {
      throw const FormatException('Board.pins must be a list');
    }

    return Board(
      id: _requiredString(json, 'id', context: 'Board'),
      name: _requiredString(json, 'name', context: 'Board'),
      category: _requiredString(json, 'category', context: 'Board'),
      microcontroller:
          _requiredString(json, 'microcontroller', context: 'Board'),
      imageAsset: _requiredString(json, 'image', context: 'Board'),
      pins: [
        for (var index = 0; index < pins.length; index++)
          Pin.fromJson(
            _requiredObject(pins[index], context: 'Board.pins[$index]'),
            context: 'Board.pins[$index]',
          ),
      ],
    );
  }
}

String _requiredString(
  Map<String, dynamic> json,
  String key, {
  required String context,
}) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$context.$key must be a string');
  }
  return value;
}

int _requiredInt(
  Map<String, dynamic> json,
  String key, {
  required String context,
}) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$context.$key must be an integer');
  }
  return value;
}

Map<String, dynamic> _requiredObject(
  Object? value, {
  required String context,
}) {
  if (value is! Map) {
    throw FormatException('$context must be an object');
  }
  return Map<String, dynamic>.from(value);
}

Future<List<Board>> _loadBoards() async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  final boardPaths = manifest
      .listAssets()
      .where((path) =>
          path.startsWith('assets/boards/') &&
          path.toLowerCase().endsWith('.json'))
      .toList()
    ..sort();

  final boards = <Board>[];
  for (final path in boardPaths) {
    final content = await rootBundle.loadString(path);
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        throw const FormatException('must contain a JSON object');
      }
      boards.add(Board.fromJson(Map<String, dynamic>.from(decoded)));
    } on FormatException catch (error) {
      throw FormatException('Invalid board file "$path": ${error.message}');
    }
  }
  return boards;
}

// --- SEARCHABLE GRID SCREEN ---
class BoardListScreen extends StatefulWidget {
  const BoardListScreen({super.key});

  @override
  State<BoardListScreen> createState() => _BoardListScreenState();
}

class _BoardListScreenState extends State<BoardListScreen> {
  String _searchQuery = '';
  late final Future<List<Board>> _boardsFuture;

  @override
  void initState() {
    super.initState();
    _boardsFuture = _loadBoards();
  }

  void _filterBoards(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinout Workbench'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterBoards,
                decoration: InputDecoration(
                  hintText:
                      'Search boards, microcontrollers, or pins (e.g. SDA)...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFF1E1E1E),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Board>>(
                future: _boardsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Could not load boards: ${snapshot.error}'),
                    );
                  }

                  final query = _searchQuery.toLowerCase();
                  final boards = snapshot.data!
                      .where((board) =>
                          board.name.toLowerCase().contains(query) ||
                          board.category.toLowerCase().contains(query) ||
                          board.microcontroller.toLowerCase().contains(query) ||
                          board.pins.any(
                            (pin) => pin.name.toLowerCase().contains(query),
                          ))
                      .toList();

                  if (boards.isEmpty) {
                    return const Center(child: Text('No microcontrollers found'));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: boards.length,
                    itemBuilder: (context, index) =>
                        BoardCard(board: boards[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AdBanner(),
    );
  }
}

class BoardCard extends StatelessWidget {
  final Board board;
  const BoardCard({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BoardDetailScreen(board: board),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 76,
                width: double.infinity,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ColoredBox(
                        color: const Color(0xFF171717),
                        child: SizedBox.expand(
                          child: board.imageAsset.isEmpty
                              ? const Center(
                                  child: Icon(
                                    Icons.developer_board,
                                    size: 48,
                                    color: Colors.blueGrey,
                                  ),
                                )
                              : Image.asset(
                                  board.imageAsset,
                                  fit: BoxFit.contain,
                                  semanticLabel: '${board.name} board',
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC121212),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          board.category,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                board.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                board.microcontroller,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.developer_board, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${board.pins.length} Pins',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- DETAIL PINOUT SCREEN ----------
class BoardDetailScreen extends StatelessWidget {
  final Board board;
  const BoardDetailScreen({super.key, required this.board});

  Color _getPinColor(String type) {
    switch (type.toUpperCase()) {
      case 'POWER':
        return Colors.redAccent;
      case 'GND':
        return Colors.grey;
      case 'ADC':
        return Colors.yellowAccent;
      case 'UART':
        return Colors.greenAccent;
      case 'SPI' :
        return Colors.purpleAccent;
      case 'GPIO':
      default:
        return Colors.blueAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(board.name),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF1E1E1E),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    board.microcontroller,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Pins: ${board.pins.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: ListView.separated(
                itemCount: board.pins.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFF2C2C2C)),
                itemBuilder: (context, index) {
                  final pin = board.pins[index];
                  final pinColor = _getPinColor(pin.type);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: pinColor.withValues(alpha: 0.2),
                      child: Text(
                        '${pin.number}',
                        style: TextStyle(
                          color: pinColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    title: Text(
                      pin.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      pin.description,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: pinColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pin.type,
                        style: TextStyle(
                          color: pinColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
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
      bottomNavigationBar: const AdBanner(),
    );
  }
}
