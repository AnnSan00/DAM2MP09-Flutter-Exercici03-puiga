import 'dart:io';
import 'dart:math';

const int numFilas = 6; // A..F
const int numColumnas = 10; // 0..9
const int totalMinas = 8;

class Casella {
  bool teMina = false;
  bool descoberta = false;
  bool teBandera = false;
  int minesAdjacents = 0;
}

class JocBuscamines {
  final Random _rng = Random();
  late List<List<Casella>> tauler;
  bool mostrarTrampes = false;
  bool primeraJugada = true;
  int tirades = 0;
  bool acabat = false;
  bool haGuanyat = false;

  JocBuscamines() {
    _inicialitzaTauler();
    _collocaMinas();
    _calculaMinesAdjacents();
  }

  void _inicialitzaTauler() {
    tauler = List.generate(
      numFilas,
      (_) => List.generate(numColumnas, (_) => Casella()),
    );
  }

  void _collocaMinas() {
    final quadrants = [
      [0, 2, 0, 4],
      [0, 2, 5, 9],
      [3, 5, 0, 4],
      [3, 5, 5, 9],
    ];

    int minesCollocades = 0;

    for (final q in quadrants) {
      int enAquestQuadrant = 0;
      while (enAquestQuadrant < 2) {
        final r = q[0] + _rng.nextInt(q[1] - q[0] + 1);
        final c = q[2] + _rng.nextInt(q[3] - q[2] + 1);
        if (!tauler[r][c].teMina) {
          tauler[r][c].teMina = true;
          enAquestQuadrant++;
          minesCollocades++;
        }
      }
    }

    while (minesCollocades < totalMinas) {
      final r = _rng.nextInt(numFilas);
      final c = _rng.nextInt(numColumnas);
      if (!tauler[r][c].teMina) {
        tauler[r][c].teMina = true;
        minesCollocades++;
      }
    }
  }

  bool _dinsLlimits(int r, int c) {
    return r >= 0 && r < numFilas && c >= 0 && c < numColumnas;
  }

  int _comptaMinesAdjacents(int r, int c) {
    int comptador = 0;
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = r + dr;
        final nc = c + dc;
        if (_dinsLlimits(nr, nc) && tauler[nr][nc].teMina) {
          comptador++;
        }
      }
    }
    return comptador;
  }

  void _calculaMinesAdjacents() {
    for (int r = 0; r < numFilas; r++) {
      for (int c = 0; c < numColumnas; c++) {
        tauler[r][c].minesAdjacents = _comptaMinesAdjacents(r, c);
      }
    }
  }

  void _mouMinaAPosicioBuida(int rActual, int cActual) {
    final lliures = <List<int>>[];
    for (int r = 0; r < numFilas; r++) {
      for (int c = 0; c < numColumnas; c++) {
        if ((r != rActual || c != cActual) && !tauler[r][c].teMina) {
          lliures.add([r, c]);
        }
      }
    }

    if (lliures.isNotEmpty) {
      final triada = lliures[_rng.nextInt(lliures.length)];
      tauler[rActual][cActual].teMina = false;
      tauler[triada[0]][triada[1]].teMina = true;
      _calculaMinesAdjacents();
    }
  }

  // Retorna 'true' si explota, 'false' altrament
  bool destapaCasella(
    int r,
    int c,
    bool esPrimeraJugada,
    bool esJugadaUsuari,
  ) {
    if (!_dinsLlimits(r, c)) {
      return false;
    }

    final casella = tauler[r][c];

    if (casella.descoberta) {
      return false;
    }

    if (!esJugadaUsuari && casella.teBandera) {
      return false;
    }

    if (esJugadaUsuari && casella.teBandera) {
      casella.teBandera = false;
    }

    if (casella.teMina) {
      if (esPrimeraJugada) {
        _mouMinaAPosicioBuida(r, c);
      } else if (esJugadaUsuari) {
        casella.descoberta = true;
        return true; // Indica explosió
      } else {
        return false;
      }
    }

    final numMines = casella.minesAdjacents;
    casella.descoberta = true;

    if (numMines == 0) {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          destapaCasella(r + dr, c + dc, false, false);
        }
      }
    }

    return false;
  }

  void alternaBandera(int r, int c) {
    if (!_dinsLlimits(r, c)) {
      print('Coordenada fora de límits.');
      return;
    }
    final casella = tauler[r][c];
    if (casella.descoberta) {
      print('No pots posar o treure una bandera en una casella ja descoberta.');
      return;
    }
    casella.teBandera = !casella.teBandera;
  }

  void _comprovaVictoria() {
    for (int r = 0; r < numFilas; r++) {
      for (int c = 0; c < numColumnas; c++) {
        final casella = tauler[r][c];
        if (!casella.teMina && !casella.descoberta) {
          return;
        }
      }
    }
    acabat = true;
    haGuanyat = true;
  }

  String _caracterJoc(int r, int c, {bool revelarMines = false}) {
    final casella = tauler[r][c];

    if (revelarMines && casella.teMina) {
      return '*';
    }

    if (casella.teBandera && !revelarMines) {
      return '#';
    }

    if (!casella.descoberta) {
      return '·';
    }

    if (casella.teMina) {
      return '*';
    }

    return casella.minesAdjacents == 0 ? ' ' : '${casella.minesAdjacents}';
  }

  String _caracterTrampa(int r, int c) {
    final casella = tauler[r][c];
    if (casella.teMina) {
      return '*';
    }
    if (!casella.descoberta) {
      return '·';
    }
    return casella.minesAdjacents == 0 ? ' ' : '${casella.minesAdjacents}';
  }

  void mostraTauler({bool finalJoc = false}) {
    const capcalera = ' 0123456789';
    print('');
    if (mostrarTrampes && !finalJoc) {
      print('$capcalera      $capcalera');
      for (int r = 0; r < numFilas; r++) {
        final lletra = String.fromCharCode('A'.codeUnitAt(0) + r);
        final filaJoc =
            List.generate(numColumnas, (c) => _caracterJoc(r, c)).join();
        final filaTrampa =
            List.generate(numColumnas, (c) => _caracterTrampa(r, c)).join();
        print('$lletra$filaJoc     $lletra$filaTrampa');
      }
    } else {
      print(capcalera);
      for (int r = 0; r < numFilas; r++) {
        final lletra = String.fromCharCode('A'.codeUnitAt(0) + r);
        final fila = List.generate(
          numColumnas,
          (c) => _caracterJoc(r, c, revelarMines: finalJoc),
        ).join();
        print('$lletra$fila');
      }
    }
  }

  void mostraAjuda() {
    print('');
    print('Comandes disponibles:');
    print('  <Fila><Col>          : Descobreix una casella (ex: C3, B2, F1)');
    print('  <Fila><Col> flag     : Posa o treu una bandera (també "bandera")');
    print('  trampes / cheat      : Mostra o amaga el tauler amb les mines');
    print('  ajuda / help         : Mostra aquesta ajuda');
  }

  List<int>? _parsejaCoordenada(String text) {
    final net = text.trim().toUpperCase();
    final match = RegExp(r'^([A-F])([0-9])$').firstMatch(net);
    if (match == null) return null;

    final fila = match.group(1)!.codeUnitAt(0) - 'A'.codeUnitAt(0);
    final col = int.parse(match.group(2)!);
    return [fila, col];
  }

  void processarComanda(String linia) {
    final parts = linia.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return;

    final primera = parts[0].toLowerCase();

    if (parts.length == 1 && (primera == 'trampes' || primera == 'cheat')) {
      mostrarTrampes = !mostrarTrampes;
      return;
    }

    if (parts.length == 1 && (primera == 'ajuda' || primera == 'help')) {
      mostraAjuda();
      return;
    }

    final coords = _parsejaCoordenada(parts[0]);
    if (coords == null) {
      print('Comanda no vàlida. Escriu "ajuda" o "help" per veure les opcions.');
      return;
    }

    if (parts.length == 2) {
      final accio = parts[1].toLowerCase();
      if (accio == 'flag' || accio == 'bandera') {
        alternaBandera(coords[0], coords[1]);
      } else {
        print('Acció no reconeguda. Fes servir "flag" o "bandera".');
      }
      return;
    }

    if (parts.length == 1) {
      final explota = destapaCasella(coords[0], coords[1], primeraJugada, true);
      primeraJugada = false;
      tirades++;

      if (explota) {
        acabat = true;
        haGuanyat = false;
      } else {
        _comprovaVictoria();
      }
      return;
    }

    print('Format de comanda no vàlid.');
  }

  void jugar() {
    while (!acabat) {
      mostraTauler();
      stdout.write('Escriu una comanda: ');
      final entrada = stdin.readLineSync();
      if (entrada == null) break;
      processarComanda(entrada);
    }

    mostraTauler(finalJoc: true);
    if (haGuanyat) {
      print('Has guanyat!');
    } else {
      print('Has perdut!');
    }
    print('Número de tirades: $tirades');
  }
}

void main() {
  final joc = JocBuscamines();
  joc.jugar();
}