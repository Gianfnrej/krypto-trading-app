import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';
import 'dart:async';
import 'detail_screen.dart';
import 'qr_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> coins = [];
  final _box = Hive.box('tradingBox');

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchCoins();

    // Holt alle 60 Sekunden neue Live-Preise
    _timer = Timer.periodic(const Duration(seconds: 60), (timer) {
      fetchCoins();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchCoins() async {
    final url = Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=eur&order=market_cap_desc&per_page=20&page=1&sparkline=false');

    try {
      final response = await http.get(
        url,
        headers: {
          'x-cg-demo-api-key': 'CG-iRQFMey3ToC6jpxFjHxEE68W',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          coins = json.decode(response.body);
        });
      } else {
        print('Fehler beim Laden: ${response.statusCode}');
      }
    } catch (e) {
      print('Netzwerkfehler: $e');
    }
  }

  // Diese Funktion löscht die Datenbank und setzt alles auf 10.000€ zurück
  void _resetAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1E22),
        title: const Text('Konto zurücksetzen?', style: TextStyle(color: Colors.white)),
        content: const Text('Dein gesamtes Portfolio wird gelöscht und du startest wieder mit 10.000 €.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Abbrechen
            child: const Text('Abbrechen', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () {
              // DATENBANK LÖSCHEN
              _box.put('portfolio', {});
              _box.put('guthaben', 10000.0);

              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Ja, löschen', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double balance = _box.get('guthaben', defaultValue: 10000.0);
    Map<dynamic, dynamic> portfolio = _box.get('portfolio', defaultValue: {});

    double cryptoValue = 0.0;

    if (coins.isNotEmpty) {
      for (var entry in portfolio.entries) {
        String symbol = entry.key;
        double amount = entry.value;

        var liveCoin = coins.firstWhere(
                (c) => c['symbol'].toString().toUpperCase() == symbol,
            orElse: () => null
        );

        if (liveCoin != null) {
          double livePrice = (liveCoin['current_price'] as num).toDouble();
          cryptoValue += (amount * livePrice);
        }
      }
    }

    double totalPortfolioValue = balance + cryptoValue;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Portfolio', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          //  HIER IST DER NEUE LÖSCHEN-BUTTON
          IconButton(
            icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
            onPressed: _resetAccount,
          ),
          // Der QR-Scanner
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QRScanScreen())).then((_) => setState((){}));
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Dashboard
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1E22),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF5D5CFF).withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                const Text('GESAMTWERT (Live 🟢)', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(
                  '€ ${totalPortfolioValue.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('In Krypto', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('€ ${cryptoValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Bargeld (Übrig)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text('€ ${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Krypto-Liste
          Expanded(
            child: coins.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF5D5CFF)))
                : ListView.builder(
              itemCount: coins.length,
              itemBuilder: (context, index) {
                final coin = coins[index];
                String symbol = coin['symbol'].toString().toUpperCase();

                double myAmount = portfolio[symbol] ?? 0.0;
                double myLiveValue = myAmount * (coin['current_price'] as num).toDouble();

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Image.network(coin['image'], width: 40),
                    title: Text(coin['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: myAmount > 0
                        ? Text('In Besitz: $myAmount\nWert: €${myLiveValue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.amber))
                        : Text(symbol, style: const TextStyle(color: Colors.grey)),
                    trailing: Text('€${coin['current_price']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(coin: coin))).then((_) => setState((){}));
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}