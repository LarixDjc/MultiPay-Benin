import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multipay_frontend/models/transaction_data.dart';
import 'package:multipay_frontend/screens/settings_screen.dart';
import 'service_form_screen.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'historique_screen.dart';
import 'transactions_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'statistiques_screen.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String _searchQuery = "";
  bool _isBalanceVisible = false;
  bool _isCommissionsVisible = false;
  bool _isLoading = true;
String mtnBalance = "0";
String moovBalance = "0";
String celtiisBalance = "0";
String nomCommercial = "Chargement...";
String agentId = "BJ-00000";
String totalProfit = "0.00";
double _commissionsJour = 0;
double _totalCommissions = 0;
DateTime? _lastPressedAt;

Future<void> _loadDashboardData() async {
  setState(() => _isLoading = true);

 final statsData = await ApiService.consulterStats();
if (statsData['totalCommissions'] != null) {
  setState(() {
    _totalCommissions = statsData['totalCommissions'].toDouble();
    _commissionsJour = statsData['commissionsJour'].toDouble();
  });
}
 // Charger les soldes par opérateur
 final comptesData = await ApiService.consulterComptesOperateurs();
if (comptesData['comptes'] != null) {
  for (var compte in comptesData['comptes']) {
    if (compte['operateur'] == 'MTN') {
      setState(() => mtnBalance = compte['solde'].toString());
    } else if (compte['operateur'] == 'MOOV') {
      setState(() => moovBalance = compte['solde'].toString());
    } else if (compte['operateur'] == 'CELTIIS') {
      setState(() => celtiisBalance = compte['solde'].toString());
    }
  }
}
final headers = await ApiService.headersAvecToken();
final response = await http.get(
  Uri.parse('${Constants.baseUrl}/compte/operateurs'),
  headers: headers,
);

  final data = await ApiService.consulterSolde();

  if (data['soldePrincipal'] != null) {
    setState(() {
      mtnBalance = data['soldePrincipal'].toString();
      moovBalance = "0";
      celtiisBalance = "0";
      _isLoading = false;
    });
  } else {
    setState(() => _isLoading = false);
  }
}

void _showStatistiques() async {
  final data = await ApiService.consulterStats();
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (context) => SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text("📊 Statistiques", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            // Commissions par opérateur
            const Text("COMMISSIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 10),
            _buildStatRow(" Commissions du jour", "${data['commissionsJour']?.toStringAsFixed(0) ?? '0'} F", Colors.green),
            _buildStatRow(" Total commissions", "${data['totalCommissions']?.toStringAsFixed(0) ?? '0'} F", Colors.green),

            const SizedBox(height: 20),
            const Text("OPÉRATIONS", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 10),

            // Stats par type
            if (data['stats'] != null) ...[
              _buildStatRow("Dépôts", "${data['stats']['depot']?['count'] ?? 0} opérations", Colors.blue),
              _buildStatRow("Retraits", "${data['stats']['retrait']?['count'] ?? 0} opérations", Colors.red),
              _buildStatRow("Crédits", "${data['stats']['credit']?['count'] ?? 0} opérations", Colors.orange),
              _buildStatRow("Forfaits", "${data['stats']['forfait']?['count'] ?? 0} opérations", Colors.purple),
              _buildStatRow("SBEE", "${data['stats']['sbee']?['count'] ?? 0} opérations", Colors.yellow.shade800),
              _buildStatRow("SONEB", "${data['stats']['soneb']?['count'] ?? 0} opérations", Colors.cyan),
              _buildStatRow("Canal+", "${data['stats']['canal']?['count'] ?? 0} opérations", Colors.deepPurple),
              _buildStatRow("Scolarité", "${data['stats']['scolarite']?['count'] ?? 0} opérations", Colors.teal),
            ],

            const SizedBox(height: 20),
            const Text("ÉVOLUTION (7 JOURS)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 10),

            // Graphique
            Expanded(
              child: data['evolution'] != null
                ? _buildGraphique(data['evolution'])
                : const Center(child: Text("Pas de données")),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildStatRow(String label, String value, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    ),
  );
}

Widget _buildGraphique(List<dynamic> evolution) {
  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: evolution.map((e) => (e['montant'] as num).toDouble()).reduce((a, b) => a > b ? a : b) + 1000,
      barGroups: evolution.asMap().entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: (entry.value['montant'] as num).toDouble(),
              color: const Color(0xFF00A859),
              width: 20,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                evolution[value.toInt()]['jour'],
                style: const TextStyle(fontSize: 11),
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
  );
}

void _loadAgentInfo() async {
  final token = await ApiService.getToken();
  print('TOKEN: $token');
  
  final data = await ApiService.consulterProfil();
  print('PROFIL DATA: $data');

  if (data['revendeur'] != null) {
    setState(() {
      nomCommercial = data['revendeur']['nom'] ?? 'Agent Inconnu';
      agentId = 'BJ-${data['revendeur']['id'].toString().padLeft(3, '0')}';
    });
  }
}
  final Color pureGreen = const Color(0xFF00A859);
   final List<TransactionData> _historiqueData = [
    TransactionData(
      id: "REF8829301",
      operator: "MTN",
      service: "Dépôts",
      number: "67000000",
      name: "Moustapha ABDOULAYE",
      amount: "5000",
      dateTime: DateTime.now(),
      isSuccess: true,
    ),
    TransactionData(
      id: "REF8829302",
      operator: "MOOV",
      service: "Retraits",
      number: "95123456",
      amount: "2500",
      dateTime: DateTime.now().subtract(const Duration(minutes: 15)),
      isSuccess: true,
    ),
    TransactionData(
      id: "REF8829303",
      operator: "CELTIIS",
      service: "Crédit",
      number: "40001122",
      amount: "1000",
      dateTime: DateTime.now().subtract(const Duration(hours: 1)),
      isSuccess: true,
    ),
  ];

  // --- DONNÉES DE TEST (Opérateur - Opération - Cible - Montant - Statut) ---
  // NOUVEAU CODE

  void showStatusNotification(String message, String status) {
    Color bgColor = status == 'success' ? Colors.green : (status == 'error' ? Colors.red : Colors.orange);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height - 100, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Bloque le retour automatique immédiat
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final now = DateTime.now();
        // Vérifie s'il s'agit du premier clic ou si le dernier clic remonte à plus de 2 secondes
        if (_lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
          _lastPressedAt = now;

          // Affiche le petit message d'avertissement en bas
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Appuyez à nouveau pour quitter l\'application',
                style: TextStyle(color: Color.fromARGB(255, 12, 11, 11), fontWeight: FontWeight.bold),
              ),
              backgroundColor: Color.fromARGB(255, 255, 88, 66), // Fond sombre pro
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        // Si le deuxième clic est fait en moins de 2 secondes, on ferme l'application
        Navigator.of(context).pop(result);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F4F5),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHome(),          // Index 0
                  _buildStatistiquesPage(),  // Index 1 (Dépôts / Retraits)
                  _buildHistoryPage(),       // Index 2 (Tout)
                  _buildSettingsPage(),      // Index 3
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: pureGreen,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Accueil"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: "Statistiques"),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "Historique"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Paramètres"),
          ],
        ),
      ),
    );
  }

   Widget buildProfitCard() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    padding: const EdgeInsets.all(15),
   decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15), // <-- Il manquait "borderRadius:" ici
      boxShadow: [
        BoxShadow(
          color: Colors.black12, 
          blurRadius: 5,
          offset: Offset(0, 2), // Optionnel: donne un petit effet de profondeur
        )
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.trending_up, color: Colors.green),
            SizedBox(width: 10),
            Text("Mon Profit (Commissions)", style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        Text("$totalProfit FCFA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
      ],
    ),
  );
}

  // --- HEADER CLIQUABLE ---
  Widget _buildHeader() {
    // On récupère l'état du mode sombre
    bool isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical:20, horizontal: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] // Couleurs sombres
: [const Color(0xFF00A859), const Color(0xFF78B596)],          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(15),
          bottomRight: Radius.circular(15),
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = 3),
        child: Row(
          children: [
                const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bienvenue  $nomCommercial",
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25)),
                Text("ID Agent: $agentId",
                    style: const TextStyle(color: Colors.white70, fontSize: 15)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- PAGE ACCUEIL ---
  Widget _buildHome() {
  return RefreshIndicator(
    onRefresh: () async {
      await _loadDashboardData();
    },
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBalanceSection(),
          _buildCommissionsCard(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text("SERVICES PRINCIPAUX", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A717E), fontSize: 19)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                Row(
                  children: [ 
                    Expanded(child: _mainServiceCard(context, Icons.credit_card, "Crédits",  Colors.orange)),
                    const SizedBox(width: 25),
                    Expanded(child: _mainServiceCard(context, Icons.inventory_2_outlined, "Forfaits", Colors.green)),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(child: _mainServiceCard(context, Icons.arrow_downward, "Dépôts", const Color.fromARGB(255, 146, 238, 161))),
                    const SizedBox(width: 25),
                    Expanded(child: _mainServiceCard(context, Icons.arrow_upward, "Retraits", Colors.red)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("AUTRES SERVICES", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5A717E), fontSize: 17)),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _otherServiceCircle(context, Icons.school, "Scolarité", Colors.blue),
                    _otherServiceCircle(context, Icons.tv, "Canal+", Colors.red),
                    _otherServiceCircle(context, Icons.water_drop, "SONEB", Colors.cyan),
                    _otherServiceCircle(context, Icons.electric_bolt, "SBEE", Colors.orange),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
      
  // --- SECTION SOLDES ---
  Widget _buildBalanceSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _balanceItem("MTN", mtnBalance, Colors.amber),
              _balanceItem("MOOV", moovBalance, Colors.green),
              _balanceItem("CELTIIS", celtiisBalance, Colors.blue),
            ],
          ),
          const Divider(height: 35),
          InkWell(
            onTap: () => setState(() => _isBalanceVisible = !_isBalanceVisible),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isBalanceVisible ? Icons.visibility_off : Icons.visibility, color: const Color.fromARGB(255, 73, 73, 73), size: 25),
                const SizedBox(width: 15),
                Text(_isBalanceVisible ? "Masquer les soldes" : "Afficher les soldes", style: const TextStyle(color: Color.fromARGB(255, 27, 27, 27), fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

 Widget _buildCommissionsCard() {
  return GestureDetector(
    onTap: () => setState(() => _isCommissionsVisible = !_isCommissionsVisible),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00A859), Color(0xFF78B596)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Commissions du jour",
                style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                _isCommissionsVisible ? "${_commissionsJour.toStringAsFixed(0)} F" : "••••••",
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text("Total commissions",
                style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text(
                _isCommissionsVisible ? "${_totalCommissions.toStringAsFixed(0)} F" : "••••••",
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Icon(
            _isCommissionsVisible ? Icons.visibility_off : Icons.visibility,
            color: Colors.white70,
            size: 20,
          ),
        ],
      ),
    ),
  );
}

  Widget _balanceItem(String label, String amount, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 18, backgroundColor: color.withOpacity(0.1), child: Text(label[0], style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        const SizedBox(height: 15),
        Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        Text(_isBalanceVisible ? "$amount F" : "••••••", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }
// --- PAGES TRANSACTIONS & HISTORIQUE (UNIFORMISÉES) ---
 Widget _buildStatistiquesPage() {
  return const StatistiquesScreen();
}
Widget _buildHistoryPage() {
  return const HistoriqueScreen();
}

  Widget _buildListViewPage(String title, List<TransactionData> data) {
  // LOGIQUE DE FILTRE : On filtre la liste 'data' selon la saisie
  final filteredData = data.where((tx) {
    final query = _searchQuery.toLowerCase();
    return tx.number.contains(query) || 
           tx.id.toLowerCase().contains(query) || 
           tx.service.toLowerCase().contains(query);
  }).toList();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // TITRE ET BARRE DE RECHERCHE
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            
            // CHAMP DE RECHERCHE
            TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value; // Met à jour et redessine la liste
                });
              },
              decoration: InputDecoration(
                hintText: "Rechercher un numéro ou une réf...",
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ],
        ),
      ),

      // AFFICHAGE DES RÉSULTATS
      Expanded(
        child: filteredData.isEmpty 
          ? _buildEmptySearch() // Si aucun résultat
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: filteredData.length,
              itemBuilder: (context, index) => _buildTransactionItem(filteredData[index]),
            ),
      ),
    ],
  );
}

// Widget pour quand la recherche ne trouve rien
Widget _buildEmptySearch() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
        const SizedBox(height: 10),
        const Text("Aucune transaction trouvée", style: TextStyle(color: Colors.grey)),
      ],
    ),
  );
}
@override
void initState() {
  super.initState();
  _loadDashboardData(); 
  _loadAgentInfo(); 
}// Charge les données du backend dès l'ouverture

  // WIDGET D'ITEM UNIFORMISÉ (Opérateur - Opération - Cible - Montant - Statut)
  Widget _buildTransactionItem(TransactionData tx) {
  // Définition de la couleur selon l'opérateur
  Color opColor;
  if (tx.operator == 'MTN') {
    opColor = Colors.amber;
  } else if (tx.operator == 'MOOV') {
    opColor = Colors.green;
  } else {
    opColor = Colors.blue;
  }

  bool isDepot = tx.service == "Dépôts";

  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15), 
      side: BorderSide(color: Colors.grey.withOpacity(0.1))
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: opColor.withOpacity(0.1), 
              child: Text(
                tx.operator[0], 
                style: TextStyle(color: opColor, fontWeight: FontWeight.bold)
              )
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${tx.operator} - ${tx.service}", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.blueGrey)
                ),
                // Affichage de la date et l'heure
                Text(
                  "${tx.dateTime.day}/${tx.dateTime.month} ${tx.dateTime.hour}:${tx.dateTime.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logique : Nom + Numéro si Dépôt, sinon Numéro seul
                  if (isDepot && tx.name != null) ...[
                    Text(tx.name!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                    Text(tx.number, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ] else ...[
                    Text(tx.number, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                  ],
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${tx.amount} F", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                // Badge de statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tx.isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    tx.isSuccess ? 'Réussi' : 'Échec', 
                    style: TextStyle(
                      color: tx.isSuccess ? Colors.green : Colors.red, 
                      fontSize: 9, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ],
            ),
          ),
          // Ligne discrète pour le Code de Référence (ID)
          Padding(
            padding: const EdgeInsets.only(left: 72, right: 16, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.fingerprint, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  "RÉF: ${tx.id}",
                  style: TextStyle(
                    fontSize: 10, 
                    color: Colors.grey.shade500, 
                    fontFamily: 'monospace',
                    letterSpacing: 0.5
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  // --- PAGE PARAMÈTRES ---
  Widget _buildSettingsPage() {
    return const SettingsScreen();
  }

  Widget settingsTile(IconData icon, String title, String sub, Color col) {
    return ListTile(
      leading: Icon(icon, color: col),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
    );
  }

  // --- WIDGETS SERVICES ---
  Widget _mainServiceCard(BuildContext context,IconData icon, String label, Color color) {
    return Container(
      height: 90,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: InkWell(
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ServiceFormScreen(
        serviceName: label, // Ex: "Dépôts"
        themeColor: color,  // Ex: Colors.orange
      ),
    ),
  );
},        borderRadius: BorderRadius.circular(20),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ]),
      ),
    );
  }

  Widget _otherServiceCircle(BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceFormScreen(serviceName: label, themeColor: color))),
      child: Column(children: [
        Container(height: 45, width: 45, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ]),
    );
  }
  }