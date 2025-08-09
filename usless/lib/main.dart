// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/api_service.dart';

void main() async {
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Excuse Generator',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _contextController = TextEditingController();
  String _category = 'general';
  String _tone = 'polite';
  String _length = 'short';
  bool _useAi = false;
  String _result = '';
  bool _loading = false;
  bool _serverOk = true;

  final List<String> categories = ['general', 'social', 'work', 'family'];
  final List<String> tones = ['polite', 'blunt', 'funny'];
  final List<String> lengths = ['short', 'medium', 'long'];

  @override
  void initState() {
    super.initState();
    _checkServer();
  }

  Future<void> _checkServer() async {
    final ok = await ApiService.healthCheck();
    setState(() {
      _serverOk = ok;
    });
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _result = '';
    });
    try {
      final resp = await ApiService.generateExcuse(
        context: _contextController.text.trim(),
        category: _category,
        tone: _tone,
        length: _length,
        useAi: _useAi,
      );
      setState(() {
        _result = resp['excuse'] ?? resp['error'] ?? 'No response';
      });
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _result));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverWarning = !_serverOk
        ? const Text(
            "Backend not reachable. Start Flask server and confirm baseUrl.",
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)))
        : const SizedBox.shrink();

    return Scaffold(
      backgroundColor: const Color(0xFFFFD09A),
      appBar: AppBar(title: Center(child: Text('Excuse Generator for Introverts',
                                                style: TextStyle(color: Colors.white,
                                                fontWeight: FontWeight.bold),
      )),
              backgroundColor: const Color(0xFFFF9800),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          serverWarning,
          SizedBox(height: 20),
          TextField(
            controller: _contextController,
            decoration: const InputDecoration(
              labelText: 'Optional context (where/how you want to avoid)',
              filled: true,
              fillColor: Color.fromARGB(132, 255, 192, 121),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25))

              ),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _category,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v!),
                  dropdownColor: const Color.fromARGB(255, 255, 193, 121),
                  decoration: const InputDecoration(labelText: 'Category',
                  filled: true,
              fillColor: Color(0x84FFC079),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))
                  )),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _tone,
                  items: tones
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setState(() => _tone = v!),
                  dropdownColor: const Color.fromARGB(255, 255, 193, 121),

                  decoration: const InputDecoration(labelText: 'Tone',
                  
                  filled: true,
              fillColor: Color.fromARGB(132, 255, 192, 121),
                   border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))
                  )
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _length,
                items: lengths
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _length = v!),
                dropdownColor: const Color.fromARGB(255, 255, 193, 121),
                decoration: const InputDecoration(labelText: 'Length',
                filled: true,
              fillColor: Color.fromARGB(132, 255, 192, 121),
                   border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(25))
                  )
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(children: [
              const Text('Use AI'),
              Switch(value: _useAi, onChanged: (v) => setState(() => _useAi = v))
            ])
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
  onPressed: _loading ? null : _generate,
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFFF9800),     // Background color
    foregroundColor: Colors.white,    // Text (and icon) color
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20), // Rounded corners
    ),
  ),
  child: _loading
      ? const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white), // Loader color
        )
      : const Text('Generate Excuse'),
),

          ),
          const SizedBox(height: 12),
          //expand
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(border: Border.all(color: const Color.fromARGB(255, 83, 83, 83)),
                  borderRadius: BorderRadius.circular(25)
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Generated:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_result),
                        const SizedBox(height: 50),
                        Row(
                          children: [
                
                                
                            const SizedBox(width: 8),
                            // ElevatedButton.icon(
                            //   onPressed: _result.isEmpty
                            //       ? null
                            //       : () {
                            //           // quick fallback share using Android/iOS native share is possible with share_plus package
                            //           Clipboard.setData(ClipboardData(text: _result));
                            //           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            //               content: Text('Copied to clipboard (use paste to share)')));
                            //         },
                            //   icon: const Icon(Icons.share),
                            //   label: const Text('Copy & Share'),
                            // ),
                          ],
                        ),
                    ElevatedButton.icon(
                                onPressed: _result.isEmpty ? null : _copyToClipboard,
                                icon: const Icon(Icons.copy, color: Colors.white), // Icon color
                                label: const Text(
                                  'Copy',
                                  style: TextStyle(color: Colors.white), // Text color
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF9800),   // Background color
                                  foregroundColor: const Color.fromARGB(255, 56, 37, 37),  // Text & icon color (if not overridden above)
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 4, // Shadow depth
                                ),
                              )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ]),
      ),
    );
  }
}
