import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  final Color primaryGreen = const Color(0xFF00A859);
  
  // Opérateur sélectionné par défaut
  String _selectedOperator = "MTN";

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    setState(() => _isLoading = true);
    final data = await ApiService.consulterStats();
    setState(() {
      _stats = data;
      _isLoading = false;
    });
  }

  // Fonction utilitaire pour savoir si une opération est une entrée ou une sortie de caisse
  bool _isEntreeCaisse(String operation) {
    final op = operation.toLowerCase();
    if (op.contains('depot') || op.contains('credit') || op.contains('forfait')) {
      return false; // Sortie de caisse -> Rouge
    }
    return true; // Entrée de caisse -> Vert
  }

  @override
  Widget build(BuildContext context) {
    final statsOps = _stats['stats'] ?? {};
    final evolution = _stats['evolution'] ?? [];

    // Couleurs claires pour entrée/sortie
    final Color couleurEntree = Colors.green.shade400;
    final Color couleurSortie = Colors.red.shade400;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F8),
      appBar: AppBar(
        title: const Text('Statistiques', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _chargerStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // --- 1. FILTRE PAR OPÉRATEUR EN HAUT (CORRIGÉ AVEC COULEURS) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ["MTN", "MOOV", "CELTIIS"].map((op) {
                        final isSelected = _selectedOperator == op;
                        
                        Color activeColor;
                        if (op == "MTN") {
                          activeColor = const Color(0xFFFFCC00); // Jaune MTN
                        } else if (op == "MOOV") {
                          activeColor = const Color.fromARGB(255, 1, 146, 21); // Bleu Moov
                        } else {
                          activeColor = const Color.fromARGB(255, 5, 27, 228); // Vert Celtiis
                        }

                        return ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedOperator = op;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected ? activeColor : Colors.white,
                            foregroundColor: isSelected 
                                ? (op == "MTN" ? Colors.black : Colors.white) 
                                : Colors.black,
                            elevation: isSelected ? 3 : 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(op, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // --- 2. LIGNE DES COMMISSIONS FIXE ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total: ${(_stats['totalCommissions'] ?? 0).toStringAsFixed(0)} F",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        Text(
                          "Commissions du jour: ${(_stats['commissionsJour'] ?? 0).toStringAsFixed(0)} F",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryGreen),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- 3. LISTE DES OPÉRATIONS SELON L'OPÉRATEUR ---
                    _buildSectionTitle("Opérations du réseau $_selectedOperator"),
                    _buildCard([
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Expanded(child: Text("Opération", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13))),
                            Expanded(child: Text("Nbre/jour", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13), textAlign: TextAlign.center)),
                            Expanded(child: Text("Montant total", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13), textAlign: TextAlign.end)),
                          ],
                        ),
                      ),
                      const Divider(),
                      
                      // Liste filtrée dynamiquement
                      ..._buildFilteredOpRows(statsOps, couleurEntree, couleurSortie),
                    ]),

                    const SizedBox(height: 20),

                    // --- 4. LIGNE GÉNÉRAL ---
                    _buildSectionTitle("Général"),
                    _buildCard([
                      _buildGeneralRow("Total opération", "${_totalOperations(statsOps)}"),
                      const Divider(height: 10),
                      _buildGeneralRow("Volume total", "${_volumeTotal(statsOps).toStringAsFixed(0)} F"),
                      const Divider(height: 10),
                      _buildGeneralRow("Commission totale", "${(_stats['totalCommissions'] ?? 0).toStringAsFixed(0)} F"),
                    ]),

                    const SizedBox(height: 20),

                    // --- 5. GRAPHE D'ÉVOLUTION ---
                    _buildSectionTitle("Évolution (7 derniers jours)"),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
                      ),
                      height: 220,
                      child: evolution.isEmpty
                          ? const Center(child: Text("Pas de données"))
                          : BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: _maxEvolution(List<dynamic>.from(evolution)) + 1000,
                                barGroups: List<BarChartGroupData>.from(
                                  (evolution as List).asMap().entries.map((entry) {
                                    return BarChartGroupData(
                                      x: entry.key,
                                      barRods: [
                                        BarChartRodData(
                                          toY: (entry.value['montant'] as num).toDouble(),
                                          color: primaryGreen,
                                          width: 20,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ],
                                    );
                                  }),
                                ),
                                titlesData: FlTitlesData(
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 || idx >= evolution.length) return const Text('');
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Text(
                                            evolution[idx]['jour'],
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),
                                gridData: const FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                              ),
                            ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  // --- LES FONCTIONS SONT PLACÉES ICI, JUSTE APRÈS LE BUILD ---

  List<Widget> _buildFilteredOpRows(dynamic statsOps, Color couleurEntree, Color couleurSortie) {
    if (_stats.isEmpty || _stats['statsParOperateur'] == null) {
      return [const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text("Aucune donnée disponible", style: TextStyle(color: Colors.grey)),
      )];
    }
    
    final opStats = _stats['statsParOperateur']?[_selectedOperator] ?? {};
    List<Widget> rows = [];
    
    final categories = ['depot', 'retrait', 'credit', 'forfait', 'sbee', 'soneb', 'canal', 'scolarite'];
    final labels = {
      'depot': 'Dépôts', 'retrait': 'Retraits', 'credit': 'Crédits', 
      'forfait': 'Forfaits', 'sbee': 'SBEE', 'soneb': 'SONEB', 
      'canal': 'Canal+', 'scolarite': 'Scolarité'
    };

    for (var cat in categories) {
      int count = 0;
      double montant = 0.0;

     final montantKey = 'montant${cat.substring(0, 1).toUpperCase()}${cat.substring(1)}';
count = opStats[cat] ?? 0;
montant = (opStats[montantKey] ?? 0).toDouble();

      final label = labels[cat] ?? cat;
      final isEntree = _isEntreeCaisse(cat);
      final Color textColor = isEntree ? couleurEntree : couleurSortie;

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
              Expanded(child: Text("$count", style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
              Expanded(child: Text("${montant.toStringAsFixed(0)} F", style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ],
          ),
        )
      );
    }
    return rows;
  }

  Widget _buildGeneralRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen)),
        ],
      ),
    );
  }

  int _totalOperations(dynamic statsOps) {
    if (statsOps == null || statsOps is! Map) return 0;
    int total = 0;
    for (var op in statsOps.values) {
      total += (op['count'] as int? ?? 0);
    }
    return total;
  }

  double _volumeTotal(dynamic statsOps) {
    if (statsOps == null || statsOps is! Map) return 0;
    double total = 0;
    for (var op in statsOps.values) {
      total += (op['montantTotal'] as num? ?? 0).toDouble();
    }
    return total;
  }

  double _maxEvolution(List<dynamic> evolution) {
    if (evolution.isEmpty) return 1000;
    return evolution
        .map((e) => (e['montant'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(children: children),
    );
  }
}