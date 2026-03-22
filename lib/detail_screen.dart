import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DetailScreen extends StatefulWidget {
  final dynamic coin;
  const DetailScreen({super.key, required this.coin});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _box = Hive.box('tradingBox');
  final TextEditingController _amountController = TextEditingController();

  double _calculatedTotal = 0.0;

  // Diese Funktion kümmert sich jetzt um beides: Kaufen (true) und Verkaufen (false)
  void _tradeCoin(bool isBuying) {
    double amountToTrade = double.tryParse(_amountController.text) ?? 0.0;
    if (amountToTrade <= 0) return;

    double price = (widget.coin['current_price'] as num).toDouble();
    double totalValue = price * amountToTrade;

    double balance = _box.get('guthaben', defaultValue: 10000.0);
    Map<dynamic, dynamic> portfolio = _box.get('portfolio', defaultValue: {});
    String symbol = widget.coin['symbol'].toUpperCase();
    double currentAmount = portfolio[symbol] ?? 0.0;

    if (isBuying) {
      // KAUFEN LOGIK
      if (balance >= totalValue) {
        _box.put('guthaben', balance - totalValue);
        portfolio[symbol] = currentAmount + amountToTrade;
        _box.put('portfolio', portfolio);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erfolgreich $amountToTrade $symbol gekauft!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nicht genug € Guthaben!'), backgroundColor: Colors.red)
        );
      }
    } else {
      // VERKAUFEN LOGIK
      if (currentAmount >= amountToTrade) {
        _box.put('guthaben', balance + totalValue);
        portfolio[symbol] = currentAmount - amountToTrade;

        // Wenn man alles verkauft hat, aufräumen
        if (portfolio[symbol] <= 0) {
          portfolio.remove(symbol);
        }

        _box.put('portfolio', portfolio);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erfolgreich $amountToTrade $symbol verkauft!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Du hast nicht so viele Coins!'), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<dynamic, dynamic> portfolio = _box.get('portfolio', defaultValue: {});
    String symbol = widget.coin['symbol'].toUpperCase();
    double myAmount = portfolio[symbol] ?? 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(widget.coin['name'])),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(widget.coin['image'], height: 100),
            const SizedBox(height: 20),

            Text('€${widget.coin['current_price']}', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Text('In deinem Besitz: $myAmount $symbol', style: const TextStyle(color: Colors.greenAccent, fontSize: 16)),
            const SizedBox(height: 40),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Menge eingeben',
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1B1E22),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                double amount = double.tryParse(value) ?? 0.0;
                double price = (widget.coin['current_price'] as num).toDouble();
                setState(() {
                  _calculatedTotal = amount * price;
                });
              },
            ),
            const SizedBox(height: 15),

            Text(
              'Wert: €${_calculatedTotal.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 30),

            // KAUFEN UND VERKAUFEN BUTTONS NEBENEINANDER
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent, // Rot für Verkaufen
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      // _tradeCoin(false) bedeutet: isBuying ist false -> Verkaufen
                      onPressed: () => _tradeCoin(false),
                      child: const Text('VERKAUFEN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, // Grün für Kaufen
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      // _tradeCoin(true) bedeutet: isBuying ist true -> Kaufen
                      onPressed: () => _tradeCoin(true),
                      child: const Text('KAUFEN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}