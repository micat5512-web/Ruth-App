import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const GastosRuthApp());
}

class Transaction {
  String id;
  String description;
  double amount;
  bool isExpense;
  String category;
  DateTime date;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.isExpense,
    required this.category,
    required this.date,
  });
}

class Apartado {
  String id;
  String title;
  double amount;
  String note;

  Apartado({
    required this.id,
    required this.title,
    required this.amount,
    this.note = '',
  });
}

class GastosRuthApp extends StatelessWidget {
  const GastosRuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastos Ruth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009688),
          primary: const Color(0xFF009688),
          secondary: const Color(0xFF80CBC4),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  double startingBalancePastWeek = 1500.0;

  final List<String> _categories = [
    'Alimentación',
    'Comida Mascotas',
    'Transporte',
    'Servicios',
    'Entretenimiento',
    'Salud',
    'Otros',
  ];

  final List<Transaction> _transactions = [
    Transaction(
      id: '1',
      description: 'Sueldo Semana Pasada',
      amount: 2500.0,
      isExpense: false,
      category: 'Otros',
      date: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Transaction(
      id: '2',
      description: 'Compra Despensa',
      amount: 450.0,
      isExpense: true,
      category: 'Alimentación',
      date: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: '3',
      description: 'Croquetas Croqueta',
      amount: 280.0,
      isExpense: true,
      category: 'Comida Mascotas',
      date: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: '4',
      description: 'Farmacia / Medicamento',
      amount: 150.0,
      isExpense: true,
      category: 'Salud',
      date: DateTime.now(),
    ),
    Transaction(
      id: '5',
      description: 'Cobro Trabajo Extra (Proyectado)',
      amount: 800.0,
      isExpense: false,
      category: 'Otros',
      date: DateTime.now().add(const Duration(days: 3)),
    ),
  ];

  final List<Apartado> _apartados = [
    Apartado(
      id: 'a1',
      title: 'Fondo de Emergencia Salud',
      amount: 500.0,
      note: 'Reservado para gastos médicos inesperados',
    ),
  ];

  double get totalIncome => _transactions
      .where((t) => !t.isExpense && t.date.isBefore(DateTime.now().add(const Duration(seconds: 1))))
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalExpenses => _transactions
      .where((t) => t.isExpense && t.date.isBefore(DateTime.now().add(const Duration(seconds: 1))))
      .fold(0.0, (sum, item) => sum + item.amount);

  double get totalBalance => totalIncome - totalExpenses;

  double get totalApartados => _apartados.fold(0.0, (sum, item) => sum + item.amount);

  double get availableBalance => totalBalance - totalApartados;

  void _addTransaction(Transaction tx) {
    setState(() {
      _transactions.add(tx);
    });
  }

  void _editTransaction(Transaction tx) {
    setState(() {
      int index = _transactions.indexWhere((element) => element.id == tx.id);
      if (index != -1) {
        _transactions[index] = tx;
      }
    });
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((tx) => tx.id == id);
    });
  }

  void _addApartado(Apartado ap) {
    setState(() {
      _apartados.add(ap);
    });
  }

  void _deleteApartado(String id) {
    setState(() {
      _apartados.removeWhere((ap) => ap.id == id);
    });
  }

  void _addCategory(String newCat) {
    if (newCat.trim().isNotEmpty && !_categories.contains(newCat.trim())) {
      setState(() {
        _categories.add(newCat.trim());
      });
    }
  }

  void _showCortePdfDialog() {
    String corteType = 'Diario';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.red),
                SizedBox(width: 8),
                Text('Generar Corte PDF'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: corteType,
                  decoration: const InputDecoration(labelText: 'Tipo de Corte'),
                  items: ['Diario', 'Semanal', 'Mensual'].map((String val) {
                    return DropdownMenuItem(value: val, child: Text('Corte $val'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => corteType = val);
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Generar PDF'),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _generateAndShowPdf(corteType, selectedDate);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _generateAndShowPdf(String type, DateTime date) async {
    final pdf = pw.Document();

    DateTime startPeriod;
    DateTime endPeriod;

    if (type == 'Diario') {
      startPeriod = DateTime(date.year, date.month, date.day);
      endPeriod = DateTime(date.year, date.month, date.day, 23, 59, 59);
    } else if (type == 'Semanal') {
      startPeriod = date.subtract(Duration(days: date.weekday - 1));
      startPeriod = DateTime(startPeriod.year, startPeriod.month, startPeriod.day);
      endPeriod = startPeriod.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
    } else {
      startPeriod = DateTime(date.year, date.month, 1);
      endPeriod = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
    }

    double initialBalance = _transactions
        .where((t) => t.date.isBefore(startPeriod))
        .fold(0.0, (sum, t) => sum + (t.isExpense ? -t.amount : t.amount));

    List<Transaction> periodTransactions = _transactions.where((t) {
      return t.date.isAfter(startPeriod.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(endPeriod.add(const Duration(seconds: 1)));
    }).toList();

    double periodIncomes = periodTransactions
        .where((t) => !t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    double periodExpenses = periodTransactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    double finalBalance = initialBalance + periodIncomes - periodExpenses;

    final currencyFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Gastos Ruth - Reporte de Corte $type',
                        style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text('Rango: ${DateFormat('dd/MM/yyyy').format(startPeriod)} al ${DateFormat('dd/MM/yyyy').format(endPeriod)}'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.teal),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Saldo Inicial:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text(currencyFmt.format(initialBalance)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('(+) Ingresos del periodo:', style: const pw.TextStyle(color: PdfColors.green)),
                        pw.Text(currencyFmt.format(periodIncomes), style: const pw.TextStyle(color: PdfColors.green)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('(-) Gastos del periodo:', style: const pw.TextStyle(color: PdfColors.red)),
                        pw.Text(currencyFmt.format(periodExpenses), style: const pw.TextStyle(color: PdfColors.red)),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Saldo Final:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text(currencyFmt.format(finalBalance), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Detalle de Movimientos', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['Fecha', 'Descripción', 'Categoría', 'Tipo', 'Monto'],
                data: periodTransactions.map((t) {
                  return [
                    DateFormat('dd/MM/yy').format(t.date),
                    t.description,
                    t.category,
                    t.isExpense ? 'Gasto' : 'Ingreso',
                    currencyFmt.format(t.amount),
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Corte_${type}_GastosRuth.pdf',
    );
  }

  void _openTransactionFormModal({Transaction? transactionToEdit, bool isExpense = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return TransactionFormModal(
          categories: _categories,
          isExpenseInitial: transactionToEdit != null ? transactionToEdit.isExpense : isExpense,
          transactionToEdit: transactionToEdit,
          onSave: (tx) {
            if (transactionToEdit == null) {
              _addTransaction(tx);
            } else {
              _editTransaction(tx);
            }
          },
          onAddCategory: _addCategory,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(
        availableBalance: availableBalance,
        totalBalance: totalBalance,
        totalApartados: totalApartados,
        transactions: _transactions,
        onEditTransaction: (tx) => _openTransactionFormModal(transactionToEdit: tx),
        onDeleteTransaction: _deleteTransaction,
        onOpenForm: _openTransactionFormModal,
      ),
      ApartadosScreen(
        apartados: _apartados,
        availableBalance: availableBalance,
        onAddApartado: _addApartado,
        onDeleteApartado: _deleteApartado,
      ),
      AnalyticsScreen(
        transactions: _transactions,
        categories: _categories,
      ),
      CalendarScreen(
        transactions: _transactions,
      ),
      WeeklySummaryScreen(
        transactions: _transactions,
        startingBalancePastWeek: startingBalancePastWeek,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.pets, color: Colors.white),
            SizedBox(width: 8),
            Text('Gastos Ruth', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF009688),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Generar Corte PDF',
            onPressed: _showCortePdfDialog,
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF009688),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.savings), label: 'Apartados'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Gráficos'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Futuro'),
          BottomNavigationBarItem(icon: Icon(Icons.date_range), label: 'Semanas'),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF009688),
              onPressed: () => _openTransactionFormModal(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }
}

class HomeScreen extends StatelessWidget {
  final double availableBalance;
  final double totalBalance;
  final double totalApartados;
  final List<Transaction> transactions;
  final Function(Transaction) onEditTransaction;
  final Function(String) onDeleteTransaction;
  final Function({required bool isExpense}) onOpenForm;

  const HomeScreen({
    super.key,
    required this.availableBalance,
    required this.totalBalance,
    required this.totalApartados,
    required this.transactions,
    required this.onEditTransaction,
    required this.onDeleteTransaction,
    required this.onOpenForm,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final pastTransactions = transactions
        .where((t) => t.date.isBefore(DateTime.now().add(const Duration(seconds: 1))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF009688),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('Saldo Libre Disponible', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency.format(availableBalance),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Saldo Total', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(formatCurrency.format(totalBalance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('En Apartados', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(formatCurrency.format(totalApartados), style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Ingreso'),
                  onPressed: () => onOpenForm(isExpense: false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Gasto'),
                  onPressed: () => onOpenForm(isExpense: true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Historial de Movimientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          pastTransactions.isEmpty
              ? const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No hay movimientos registrados')))
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pastTransactions.length,
                  itemBuilder: (context, index) {
                    final tx = pastTransactions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tx.isExpense ? Colors.red.shade100 : Colors.green.shade100,
                          child: Icon(
                            tx.isExpense ? Icons.remove : Icons.add,
                            color: tx.isExpense ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${tx.category} • ${DateFormat('dd/MM/yyyy').format(tx.date)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${tx.isExpense ? '-' : '+'}${formatCurrency.format(tx.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: tx.isExpense ? Colors.red : Colors.green,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                              onPressed: () => onEditTransaction(tx),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.grey),
                              onPressed: () => onDeleteTransaction(tx.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}

class ApartadosScreen extends StatefulWidget {
  final List<Apartado> apartados;
  final double availableBalance;
  final Function(Apartado) onAddApartado;
  final Function(String) onDeleteApartado;

  const ApartadosScreen({
    super.key,
    required this.apartados,
    required this.availableBalance,
    required this.onAddApartado,
    required this.onDeleteApartado,
  });

  @override
  State<ApartadosScreen> createState() => _ApartadosScreenState();
}

class _ApartadosScreenState extends State<ApartadosScreen> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  void _submitData() {
    final title = _titleController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final note = _noteController.text;

    if (title.isEmpty || amount <= 0) return;

    widget.onAddApartado(Apartado(
      id: DateTime.now().toString(),
      title: title,
      amount: amount,
      note: note,
    ));

    _titleController.clear();
    _amountController.clear();
    _noteController.clear();
    Navigator.of(context).pop();
  }

  void _openCreateModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nuevo Apartado', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: '¿Para qué es este dinero? (Ej: Renta)')),
            TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto a apartar (\$)')),
            TextField(controller: _noteController, decoration: const InputDecoration(labelText: 'Nota opcional')),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688), foregroundColor: Colors.white),
              onPressed: _submitData,
              child: const Text('Guardar Apartado'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.amber.shade100,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.savings, size: 40, color: Colors.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Saldo Libre Restante', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(fmt.format(widget.availableBalance), style: const TextStyle(fontSize: 18)),
                      ],
                    ),
                  ),
                  ElevatedButton(onPressed: _openCreateModal, child: const Text('+ Crear'))
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Mis Apartados Guardados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: widget.apartados.isEmpty
                ? const Center(child: Text('No tienes dinero separado en apartados'))
                : ListView.builder(
                    itemCount: widget.apartados.length,
                    itemBuilder: (ctx, i) {
                      final ap = widget.apartados[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.lock, color: Colors.white)),
                          title: Text(ap.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(ap.note.isNotEmpty ? ap.note : 'Sin notas'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(fmt.format(ap.amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => widget.onDeleteApartado(ap.id),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

class AnalyticsScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final List<String> categories;

  const AnalyticsScreen({super.key, required this.transactions, required this.categories});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final expenses = transactions.where((t) => t.isExpense).toList();
    final totalExpenseSum = expenses.fold(0.0, (sum, t) => sum + t.amount);

    Map<String, double> categoryTotals = {};
    for (var cat in categories) {
      categoryTotals[cat] = 0.0;
    }
    for (var t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0.0) + t.amount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Control de Gastos por Categoría', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          totalExpenseSum == 0
              ? const Center(child: Text('No hay gastos registrados para analizar'))
              : Column(
                  children: categories.map((cat) {
                    final amount = categoryTotals[cat] ?? 0.0;
                    final pct = totalExpenseSum > 0 ? (amount / totalExpenseSum) : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(cat, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${fmt.format(amount)} (${(pct * 100).toStringAsFixed(1)}%)'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: pct,
                            minHeight: 10,
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xFF009688),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}

class CalendarScreen extends StatelessWidget {
  final List<Transaction> transactions;

  const CalendarScreen({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final sortedTx = List<Transaction>.from(transactions)..sort((a, b) => a.date.compareTo(b.date));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Proyección de Ingresos y Gastos Futuros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: sortedTx.length,
              itemBuilder: (ctx, i) {
                final tx = sortedTx[i];
                final isFuture = tx.date.isAfter(DateTime.now());
                return Card(
                  color: isFuture ? Colors.blue.shade50 : Colors.white,
                  child: ListTile(
                    leading: Icon(
                      isFuture ? Icons.event : Icons.history,
                      color: isFuture ? Colors.blue : Colors.grey,
                    ),
                    title: Text(tx.description),
                    subtitle: Text('${DateFormat('dd/MM/yyyy').format(tx.date)} • ${tx.isExpense ? 'Gasto' : 'Ingreso'}'),
                    trailing: Text(
                      '${tx.isExpense ? '-' : '+'}${fmt.format(tx.amount)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: tx.isExpense ? Colors.red : Colors.green),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}

class WeeklySummaryScreen extends StatelessWidget {
  final List<Transaction> transactions;
  final double startingBalancePastWeek;

  const WeeklySummaryScreen({super.key, required this.transactions, required this.startingBalancePastWeek});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final now = DateTime.now();
    final currentWeekTransactions = transactions.where((t) {
      final diff = now.difference(t.date).inDays;
      return diff <= 7 && diff >= 0;
    }).toList();

    double weekIncomes = currentWeekTransactions.where((t) => !t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    double weekExpenses = currentWeekTransactions.where((t) => t.isExpense).fold(0.0, (sum, t) => sum + t.amount);
    double endingBalance = startingBalancePastWeek + weekIncomes - weekExpenses;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cierre Semanal y Traspaso de Saldo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo con que saliste la semana pasada:'),
                      Text(fmt.format(startingBalancePastWeek), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('(+) Ingresos esta semana:'),
                      Text(fmt.format(weekIncomes), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('(-) Gastos esta semana:'),
                      Text(fmt.format(weekExpenses), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo para la siguiente semana:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(fmt.format(endingBalance), style: const TextStyle(color: Color(0xFF009688), fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class TransactionFormModal extends StatefulWidget {
  final List<String> categories;
  final bool isExpenseInitial;
  final Transaction? transactionToEdit;
  final Function(Transaction) onSave;
  final Function(String) onAddCategory;

  const TransactionFormModal({
    super.key,
    required this.categories,
    required this.isExpenseInitial,
    this.transactionToEdit,
    required this.onSave,
    required this.onAddCategory,
  });

  @override
  State<TransactionFormModal> createState() => _TransactionFormModalState();
}

class _TransactionFormModalState extends State<TransactionFormModal> {
  late bool _isExpense;
  late String _selectedCategory;
  DateTime _selectedDate = DateTime.now();

  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isExpense = widget.isExpenseInitial;
    _selectedCategory = widget.categories.first;

    if (widget.transactionToEdit != null) {
      _descriptionController.text = widget.transactionToEdit!.description;
      _amountController.text = widget.transactionToEdit!.amount.toString();
      _isExpense = widget.transactionToEdit!.isExpense;
      _selectedCategory = widget.transactionToEdit!.category;
      _selectedDate = widget.transactionToEdit!.date;
    }
  }

  void _submitData() {
    final desc = _descriptionController.text;
    final amount = double.tryParse(_amountController.text) ?? 0.0;

    if (desc.isEmpty || amount <= 0) return;

    widget.onSave(Transaction(
      id: widget.transactionToEdit?.id ?? DateTime.now().toString(),
      description: desc,
      amount: amount,
      isExpense: _isExpense,
      category: _selectedCategory,
      date: _selectedDate,
    ));

    Navigator.of(context).pop();
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: _newCategoryController,
          decoration: const InputDecoration(labelText: 'Nombre de la categoría'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (_newCategoryController.text.isNotEmpty) {
                widget.onAddCategory(_newCategoryController.text);
                setState(() {
                  _selectedCategory = _newCategoryController.text.trim();
                });
                _newCategoryController.clear();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.transactionToEdit != null ? 'Editar Movimiento' : 'Nuevo Movimiento', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Row(
            children: [
              ChoiceChip(
                label: const Text('Gasto'),
                selected: _isExpense,
                selectedColor: Colors.red.shade100,
                onSelected: (val) => setState(() => _isExpense = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Ingreso'),
                selected: !_isExpense,
                selectedColor: Colors.green.shade100,
                onSelected: (val) => setState(() => _isExpense = false),
              ),
            ],
          ),
          TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Descripción')),
          TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto (\$)')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: widget.categories.contains(_selectedCategory) ? _selectedCategory : widget.categories.first,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: widget.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
              ),
              IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF009688)), onPressed: _showAddCategoryDialog),
            ],
          ),
          ListTile(
            title: Text('Fecha: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF009688), foregroundColor: Colors.white),
              onPressed: _submitData,
              child: const Text('Guardar Movimiento'),
            ),
          )
        ],
      ),
    );
  }
}
