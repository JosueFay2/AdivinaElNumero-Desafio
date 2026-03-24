import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('historial');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class Nivel {
  final String nombre;
  final int maxNumero;
  final int intentos;

  Nivel(this.nombre, this.maxNumero, this.intentos);
}

final niveles = [
  Nivel("Fácil", 10, 5),
  Nivel("Medio", 20, 8),
  Nivel("Avanzado", 100, 15),
  Nivel("Extremo", 1000, 25),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final box = Hive.box('historial');

  final controller = TextEditingController();

  double nivelIndex = 0;

  int numeroSecreto = 0;
  int intentosRestantes = 0;

  List<int> mayores = [];
  List<int> menores = [];

  List<Map<String, dynamic>> historial = [];

  void cargarHistorial() {
    final data = box.values.toList();

    historial = data.map((e) {
      return {"numero": e["numero"], "estado": e["estado"]};
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    cargarHistorial();
    iniciarJuego(niveles[0]);
  }

  void iniciarJuego(Nivel nivel) {
    final random = Random();

    numeroSecreto = random.nextInt(nivel.maxNumero) + 1;
    intentosRestantes = nivel.intentos;

    mayores.clear();
    menores.clear();

    setState(() {});
  }

  void validarIntento(Nivel nivel) {
    final input = int.tryParse(controller.text);

    if (input == null) return;

    if (input < 1 || input > nivel.maxNumero) {
      Fluttertoast.showToast(
        msg: "Fuera de rango (1 - ${nivel.maxNumero})",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (input == numeroSecreto) {
      historial.add({"numero": input, "estado": "win"});
      box.add({"numero": input, "estado": "win"});

      Fluttertoast.showToast(
        msg: "¡Winner Winner Chicken Dinner!",
        backgroundColor: Colors.greenAccent,
      );

      controller.clear();
      iniciarJuego(niveles[nivelIndex.toInt()]);
      cargarHistorial();
      setState(() {});

      return;
    }

    if (input < numeroSecreto) {
      intentosRestantes--;
      menores.add(input);
    } else {
      intentosRestantes--;
      mayores.add(input);
    }

    if (intentosRestantes <= 0) {
      historial.add({"numero": numeroSecreto, "estado": "lose"});
      box.add({"numero": numeroSecreto, "estado": "lose"});
      Fluttertoast.showToast(
        msg: "Perdiste El Número era: $numeroSecreto",
        backgroundColor: Colors.red,
      );
      cargarHistorial();
      iniciarJuego(niveles[nivelIndex.toInt()]);
    }

    controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final nivelActual = niveles[nivelIndex.toInt()];

    return Scaffold(
      backgroundColor: const Color(0xFF2B2B2B),
      appBar: AppBar(
        title: const Text("Adivina el Numero"),
        centerTitle: true,
        backgroundColor: Colors.black54,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => validarIntento(nivelActual),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Número",
                      labelStyle: const TextStyle(color: Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      hintText: "Ingresa un número",
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text("Intentos"),
                    Text(
                      "$intentosRestantes",
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 250,
              child: Row(
                children: [
                  _buildBox("Mayor que", mayores),
                  const SizedBox(width: 10),
                  _buildBox("Menor que", menores),
                  const SizedBox(width: 10),
                  _buildHistorial(),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Column(
              children: [
                Text(nivelActual.nombre),
                Slider(
                  activeColor: Colors.blueAccent,
                  thumbColor: Colors.blueAccent,
                  value: nivelIndex,
                  min: 0,
                  max: 3,
                  divisions: 3,
                  label: nivelActual.nombre,
                  onChanged: (value) {
                    setState(() {
                      controller.clear();
                      nivelIndex = value;
                      iniciarJuego(niveles[value.toInt()]);
                    });
                  },
                ),
                Text("1 - ${nivelActual.maxNumero}"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(String title, List<int> items) {
    return Expanded(
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(title),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return Center(child: Text("${items[index]}"));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorial() {
    return Expanded(
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Expanded(
          child: Column(
            children: [
              const Text("Historial"),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: historial.length,
                  itemBuilder: (context, index) {
                    final e = historial[index];

                    Color color = e["estado"] == "win"
                        ? Colors.green
                        : Colors.red;

                    return Center(
                      child: Text(
                        "${e["numero"]}",
                        style: TextStyle(color: color),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
