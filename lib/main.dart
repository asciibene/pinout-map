import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'notes_store.dart';

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
      title: 'Pinout Map',
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
  static const _testAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const _productionAdUnitId =
      'ca-app-pub-8409044666841486/4867708430';

  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int? _requestedWidth;

  Future<void> _loadBannerAd(int width) async {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;

    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || _requestedWidth != width) return;
    if (size == null) {
      debugPrint('Unable to get an adaptive banner size for width $width.');
      return;
    }

    late final BannerAd bannerAd;
    bannerAd = BannerAd(
      adUnitId: kDebugMode ? _testAdUnitId : _productionAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !identical(_bannerAd, ad)) return;
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
          if (!mounted || !identical(_bannerAd, ad)) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );
    _bannerAd = bannerAd;
    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.truncate();
          if (width > 0 && width != _requestedWidth) {
            _requestedWidth = width;
            _loadBannerAd(width);
          }

          final bannerAd = _bannerAd;
          if (!_isLoaded || bannerAd == null) {
            return const SizedBox(height: 50, width: double.infinity);
          }

          return SizedBox(
            height: bannerAd.size.height.toDouble(),
            child: Center(
              child: SizedBox(
                width: bannerAd.size.width.toDouble(),
                height: bannerAd.size.height.toDouble(),
                child: AdWidget(ad: bannerAd),
              ),
            ),
          );
        },
      ),
    );
  }
}

// --- MODELS ---
class Pin {
  static final _digitalCapabilityPattern = RegExp(
    r'\bGPIO\b|\bDIGITAL I/O\b|\bDIGITAL PIN\b',
    caseSensitive: false,
  );
  static final _analogCapabilityPattern = RegExp(
    r'\bADC\d+(?:_CH\d+)?\b|\bADC\d*\s+INPUT\b|'
    r'ANALOG INPUT|ADC-CAPABLE|ADC CHANNEL',
    caseSensitive: false,
  );
  static final _i2cCapabilityPattern = RegExp(
    r'\bI2C\b|\bSDA\b|\bSCL\b',
    caseSensitive: false,
  );
  static final _spiCapabilityPattern = RegExp(
    r'\bSPI\b|\bMOSI\b|\bMISO\b|\bSCK\b',
    caseSensitive: false,
  );
  static final _uartCapabilityPattern = RegExp(
    r'\bUART\b|\bUSART\d*\b',
    caseSensitive: false,
  );
  static final _pwmCapabilityPattern = RegExp(r'\bPWM\b', caseSensitive: false);
  static final _touchCapabilityPattern =
      RegExp(r'\bTOUCH\b', caseSensitive: false);
  static final _interruptCapabilityPattern =
      RegExp(r'\bINTERRUPT(S)?\b', caseSensitive: false);
  static final _unsupportedCapabilityClausePattern = RegExp(
    r'\b(NO|WITHOUT|NOT SUPPORTED|NOT AVAILABLE)\b[^.;]*',
    caseSensitive: false,
  );

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

  List<PinCapability> get capabilities {
    final text = '$name $description';
    final normalizedType = type.toUpperCase();
    final capabilities = <PinCapability>[];

    if (normalizedType == 'GPIO' ||
        _hasDocumentedCapability(_digitalCapabilityPattern, text)) {
      capabilities.add(PinCapability.digital);
    }
    if (normalizedType == 'ADC' ||
        _hasDocumentedCapability(_analogCapabilityPattern, text)) {
      capabilities.add(PinCapability.analog);
    }
    if (_hasDocumentedCapability(_i2cCapabilityPattern, text)) {
      capabilities.add(PinCapability.i2c);
    }
    if (normalizedType == 'SPI' ||
        _hasDocumentedCapability(_spiCapabilityPattern, text)) {
      capabilities.add(PinCapability.spi);
    }
    if (normalizedType == 'UART' ||
        _hasDocumentedCapability(_uartCapabilityPattern, text)) {
      capabilities.add(PinCapability.uart);
    }
    if (_hasDocumentedCapability(_pwmCapabilityPattern, text)) {
      capabilities.add(PinCapability.pwm);
    }
    if (_hasDocumentedCapability(_touchCapabilityPattern, text)) {
      capabilities.add(PinCapability.touch);
    }
    if (_hasDocumentedCapability(_interruptCapabilityPattern, text)) {
      capabilities.add(PinCapability.interrupt);
    }

    return capabilities;
  }

  static bool _hasDocumentedCapability(RegExp pattern, String text) {
    final unsupportedClauses =
        _unsupportedCapabilityClausePattern.allMatches(text);
    return pattern.allMatches(text).any(
          (match) => !unsupportedClauses.any(
            (clause) =>
                match.start >= clause.start && match.end <= clause.end,
          ),
        );
  }

  factory Pin.fromJson(Map<String, dynamic> json, {required String context}) {
    return Pin(
      number: _requiredInt(json, 'number', context: context),
      name: _requiredString(json, 'name', context: context),
      type: _requiredString(json, 'type', context: context),
      description: _requiredString(json, 'description', context: context),
    );
  }
}

enum PinCapability {
  digital('Digital I/O', Icons.input, Colors.lightBlueAccent),
  analog('Analog input (ADC)', Icons.show_chart, Colors.amberAccent),
  i2c('I²C', Icons.swap_horiz, Colors.cyanAccent),
  spi('SPI', Icons.memory, Colors.purpleAccent),
  uart('UART', Icons.sync_alt, Colors.greenAccent),
  pwm('PWM', Icons.tune, Colors.orangeAccent),
  touch('Touch sensing', Icons.touch_app, Colors.pinkAccent),
  interrupt('External interrupt', Icons.bolt, Colors.yellowAccent);

  const PinCapability(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
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

enum _BoardMenuAction { switchView, about, licenses }

class _BoardListScreenState extends State<BoardListScreen> {
  String _searchQuery = '';
  bool _isGridView = false;
  late final Future<List<Board>> _boardsFuture;
  final _notesStore = NotesStore();
  Map<String, Map<int, String>> _boardNotes = {};
  String? _notesError;
  bool _notesLoading = true;
  late Future<void> _notesLoadFuture;

  @override
  void initState() {
    super.initState();
    _boardsFuture = _loadBoards();
    _notesLoadFuture = _loadSavedNotes();
  }

  Future<void> _loadSavedNotes() async {
    try {
      final boards = await _boardsFuture;
      final errors = <String>[];
      final results = await Future.wait<MapEntry<String, Map<int, String>>?>(
        boards.map((board) async {
          try {
            return MapEntry(
              board.id,
              await _notesStore.loadBoardNotes(board.id),
            );
          } catch (error) {
            errors.add('${board.name}: $error');
            return null;
          }
        }),
      );
      final notes = <String, Map<int, String>>{};
      for (final result in results) {
        if (result != null) {
          notes[result.key] = result.value;
        }
      }
      if (!mounted) return;
      setState(() {
        _boardNotes = notes;
        _notesError = errors.isEmpty
            ? null
            : 'Could not load ${errors.length} board note file(s): ${errors.first}';
        _notesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _notesError = 'Could not load saved notes: $error';
        _notesLoading = false;
      });
    }
  }

  Future<void> _retryLoadingNotes() async {
    setState(() {
      _notesLoading = true;
      _notesError = null;
    });
    _notesLoadFuture = _loadSavedNotes();
    await _notesLoadFuture;
  }

  Future<void> _openBoard(Board board) async {
    await _notesLoadFuture;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoardDetailScreen(
          board: board,
          initialNotes: _boardNotes[board.id] ?? const {},
          onNotesChanged: (notes) {
            setState(() {
              _boardNotes[board.id] = Map<int, String>.of(notes);
            });
          },
        ),
      ),
    );
  }

  void _filterBoards(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _handleMenuAction(_BoardMenuAction action) {
    switch (action) {
      case _BoardMenuAction.switchView:
        setState(() {
          _isGridView = !_isGridView;
        });
        break;
      case _BoardMenuAction.about:
        showAboutDialog(
          context: context,
          applicationName: 'Pinout Map',
          applicationVersion: '0.3.0',
          children: const [
            Text('created by ASCII BENE'),
          ],
        );
        break;
      case _BoardMenuAction.licenses:
        showLicensePage(
          context: context,
          applicationName: 'Pinout Map',
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinout Map'),
        centerTitle: true,
        actions: [
          PopupMenuButton<_BoardMenuAction>(
            tooltip: 'More options',
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _BoardMenuAction.switchView,
                child: Row(
                  children: [
                    Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                    const SizedBox(width: 12),
                    Text(_isGridView ? 'List view' : 'Grid view'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: _BoardMenuAction.about,
                child: Text('About'),
              ),
              const PopupMenuItem(
                value: _BoardMenuAction.licenses,
                child: Text('Licences'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_notesLoading) const LinearProgressIndicator(),
            if (_notesError != null)
              MaterialBanner(
                content: Text(_notesError!),
                actions: [
                  TextButton(
                    onPressed: _retryLoadingNotes,
                    child: const Text('Retry'),
                  ),
                ],
              ),
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

                  if (_isGridView) {
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: boards.length,
                      itemBuilder: (context, index) {
                        final board = boards[index];
                        return BoardCard(
                          board: board,
                          hasNotes:
                              _boardNotes[board.id]?.isNotEmpty ?? false,
                          notesLoading: _notesLoading,
                          onTap: () => _openBoard(board),
                        );
                      },
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: boards.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final board = boards[index];
                      return BoardListTile(
                        board: board,
                        hasNotes:
                            _boardNotes[board.id]?.isNotEmpty ?? false,
                        notesLoading: _notesLoading,
                        onTap: () => _openBoard(board),
                      );
                    },
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

class BoardListTile extends StatelessWidget {
  final Board board;
  final bool hasNotes;
  final bool notesLoading;
  final VoidCallback onTap;

  const BoardListTile({
    super.key,
    required this.board,
    required this.hasNotes,
    required this.notesLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: hasNotes ? const Color(0xFF254238) : const Color(0xFF1E1E1E),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: SizedBox(
          width: 52,
          height: 52,
          child: board.imageAsset.isEmpty
              ? const Icon(Icons.developer_board, color: Colors.blueGrey)
              : Image.asset(
                  board.imageAsset,
                  fit: BoxFit.contain,
                  semanticLabel: '${board.name} board',
                ),
        ),
        title: Text(
          board.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${board.microcontroller}\n${board.category} - ${board.pins.length} pins',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasNotes)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.sticky_note_2_outlined, size: 18),
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: notesLoading ? null : onTap,
      ),
    );
  }
}

class BoardCard extends StatelessWidget {
  final Board board;
  final bool hasNotes;
  final bool notesLoading;
  final VoidCallback onTap;

  const BoardCard({
    super.key,
    required this.board,
    required this.hasNotes,
    required this.notesLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: hasNotes ? const Color(0xFF254238) : const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: notesLoading ? null : onTap,
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
                    if (hasNotes)
                      const Positioned(
                        top: 6,
                        right: 6,
                        child: Icon(
                          Icons.sticky_note_2_outlined,
                          semanticLabel: 'Has personal notes',
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
class BoardDetailScreen extends StatefulWidget {
  final Board board;
  final Map<int, String> initialNotes;
  final ValueChanged<Map<int, String>> onNotesChanged;

  const BoardDetailScreen({
    super.key,
    required this.board,
    required this.initialNotes,
    required this.onNotesChanged,
  });

  @override
  State<BoardDetailScreen> createState() => _BoardDetailScreenState();
}

class _BoardDetailScreenState extends State<BoardDetailScreen> {
  final _notesStore = NotesStore();
  late Map<int, String> _notes;
  bool _isSavingNote = false;

  @override
  void initState() {
    super.initState();
    _notes = Map<int, String>.of(widget.initialNotes);
  }

  Future<void> _editNote(Pin pin) async {
    final controller = TextEditingController(text: _notes[pin.number] ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note for ${pin.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 3,
          maxLines: 8,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Add a personal note for this pin',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (_notes.containsKey(pin.number))
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('Delete note'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null) return;

    final updatedNotes = Map<int, String>.of(_notes);
    if (note.trim().isEmpty) {
      updatedNotes.remove(pin.number);
    } else {
      updatedNotes[pin.number] = note.trim();
    }

    setState(() {
      _isSavingNote = true;
    });
    try {
      await _notesStore.saveBoardNotes(widget.board.id, updatedNotes);
      if (!mounted) return;
      setState(() {
        _notes = updatedNotes;
        _isSavingNote = false;
      });
      widget.onNotesChanged(updatedNotes);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSavingNote = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save note: $error')),
      );
    }
  }

  Color _getPinColor(String type) {
    switch (type.toUpperCase()) {
      case 'POWER':
        return Colors.redAccent;
      case 'GND':
        return Colors.grey;
      case 'ADC':
        return Colors.yellowAccent;
      case 'CTRL':
        return Colors.brown;
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
      appBar: AppBar(title: Text(widget.board.name)),
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
                    widget.board.microcontroller,
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Pins: ${widget.board.pins.length}',
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
                itemCount: widget.board.pins.length,
                separatorBuilder: (context, index) =>
                    const Divider(height: 1, color: Color(0xFF2C2C2C)),
                itemBuilder: (context, index) {
                  final pin = widget.board.pins[index];
                  final pinColor = _getPinColor(pin.type);
                  final note = _notes[pin.number];

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
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PinCapabilityIndicators(
                            capabilities: pin.capabilities,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pin.description,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                          if (note != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Note: $note',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF9FE0BD),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (note != null)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.sticky_note_2_outlined,
                              color: Color(0xFF9FE0BD),
                              size: 18,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
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
                      ],
                    ),
                    onTap: _isSavingNote ? null : () => _editNote(pin),
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

class PinCapabilityIndicators extends StatelessWidget {
  final List<PinCapability> capabilities;

  const PinCapabilityIndicators({super.key, required this.capabilities});

  @override
  Widget build(BuildContext context) {
    if (capabilities.isEmpty) {
      return Text(
        'No capabilities listed',
        style: TextStyle(color: Colors.grey[600], fontSize: 10),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final capability in capabilities)
          Tooltip(
            message: capability.label,
            child: Semantics(
              label: capability.label,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: capability.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  capability.icon,
                  size: 15,
                  color: capability.color,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
