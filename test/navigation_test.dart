// Test della logica di navigazione: frasi italiane delle manovre,
// avanzamento lungo il percorso e lettura della risposta di OSRM.

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:rova/models/route_step.dart';
import 'package:rova/services/instruction_builder.dart';
import 'package:rova/services/route_tracker.dart';
import 'package:rova/services/routing_service.dart';

RouteStep step({
  String tipo = 'turn',
  String? modificatore,
  String nome = '',
  int? uscita,
  double metri = 100,
}) {
  return RouteStep(
    tipo: tipo,
    modificatore: modificatore,
    nomeStrada: nome,
    uscitaRotonda: uscita,
    metri: metri,
    posizione: const LatLng(0, 0),
    indiceInizio: 0,
  );
}

void main() {
  group('InstructionBuilder - frasi', () {
    test('svolta a destra con nome della strada', () {
      expect(
        InstructionBuilder.frase(step(modificatore: 'right', nome: 'Via Roma')),
        'Gira a destra su Via Roma',
      );
    });

    test('svolta a sinistra senza nome', () {
      expect(
        InstructionBuilder.frase(step(modificatore: 'left')),
        'Gira a sinistra',
      );
    });

    test('inversione a U', () {
      expect(
        InstructionBuilder.frase(step(modificatore: 'uturn')),
        'Fai inversione',
      );
    });

    test('rotonda con numero di uscita in lettere', () {
      expect(
        InstructionBuilder.frase(
          step(tipo: 'roundabout', uscita: 2, nome: 'Via Aurelia'),
        ),
        'Alla rotonda prendi la seconda uscita su Via Aurelia',
      );
    });

    test('partenza e arrivo', () {
      expect(
        InstructionBuilder.frase(step(tipo: 'depart', nome: 'Via Mare')),
        'Parti su Via Mare',
      );
      expect(
        InstructionBuilder.frase(step(tipo: 'arrive')),
        'Sei arrivato a destinazione',
      );
    });

    test('uscita autostradale', () {
      expect(
        InstructionBuilder.frase(step(tipo: 'off ramp', nome: 'A12')),
        'Prendi l\'uscita su A12',
      );
    });
  });

  group('InstructionBuilder - annunci', () {
    test('annuncia la distanza prima della manovra', () {
      final testo = InstructionBuilder.annuncio(
        step(modificatore: 'right', nome: 'Via Roma'),
        300,
      );
      expect(testo, 'Tra 300 metri, gira a destra su Via Roma');
    });

    test('vicino alla manovra dice solo l\'istruzione', () {
      final testo = InstructionBuilder.annuncio(step(modificatore: 'left'), 40);
      expect(testo, 'Gira a sinistra');
    });

    test('arrivo imminente', () {
      expect(
        InstructionBuilder.annuncio(step(tipo: 'arrive'), 30),
        'Sei arrivato a destinazione',
      );
    });
  });

  group('InstructionBuilder - distanze', () {
    test('arrotonda le distanze parlate', () {
      expect(InstructionBuilder.distanzaParlata(287), '300 metri');
      expect(InstructionBuilder.distanzaParlata(44), '40 metri');
      expect(InstructionBuilder.distanzaParlata(1500), '1,5 chilometri');
      expect(InstructionBuilder.distanzaParlata(12000), '12 chilometri');
    });

    test('formato breve per lo schermo', () {
      expect(InstructionBuilder.distanzaBreve(287), '300 m');
      expect(InstructionBuilder.distanzaBreve(1500), '1,5 km');
    });
  });

  group('RouteTracker', () {
    // Percorso a L: 3 punti lungo meridiano/parallelo.
    final percorso = [
      const LatLng(45.0000, 9.0000),
      const LatLng(45.0100, 9.0000),
      const LatLng(45.0100, 9.0100),
    ];

    test('calcola la lunghezza totale del percorso', () {
      final t = RouteTracker(percorso);
      // ~1.11 km il primo tratto, ~0.79 km il secondo.
      expect(t.metriTotali, greaterThan(1800));
      expect(t.metriTotali, lessThan(2000));
    });

    test('proietta una posizione sul percorso e misura l\'avanzamento', () {
      final t = RouteTracker(percorso);
      // Punto a metà del primo tratto, leggermente fuori linea.
      final p = t.progresso(const LatLng(45.0050, 9.0001));

      expect(p.indiceSegmento, 0);
      expect(p.metriPercorsi, greaterThan(500));
      expect(p.metriPercorsi, lessThan(600));
      expect(p.metriDalPercorso, lessThan(20));
    });

    test('riconosce una posizione lontana dal percorso', () {
      final t = RouteTracker(percorso);
      final p = t.progresso(const LatLng(45.0050, 9.0100));

      expect(p.metriDalPercorso, greaterThan(400));
    });

    test('metriFinoA resta nei limiti anche con indici fuori scala', () {
      final t = RouteTracker(percorso);

      expect(t.metriFinoA(0), 0);
      expect(t.metriFinoA(999), t.metriTotali);
    });
  });

  group('RoutingService.parseRoute', () {
    test('estrae polyline, manovre e indici dagli step OSRM', () {
      final route = {
        'distance': 1500.0,
        'duration': 300.0,
        'legs': [
          {
            'steps': [
              {
                'name': 'Via Roma',
                'distance': 1000.0,
                'maneuver': {'type': 'depart', 'location': [9.0, 45.0]},
                'geometry': {
                  'coordinates': [
                    [9.0, 45.0],
                    [9.001, 45.001],
                  ],
                },
              },
              {
                'name': 'Via Milano',
                'distance': 500.0,
                'maneuver': {
                  'type': 'turn',
                  'modifier': 'right',
                  'location': [9.001, 45.001],
                },
                'geometry': {
                  'coordinates': [
                    [9.001, 45.001],
                    [9.002, 45.002],
                  ],
                },
              },
            ],
          },
        ],
      };

      final r = RoutingService.parseRoute(route);

      // Il punto di giunzione non viene duplicato.
      expect(r.polyline.length, 3);
      expect(r.steps.length, 2);
      expect(r.metri, 1500.0);
      expect(r.steps[1].tipo, 'turn');
      expect(r.steps[1].modificatore, 'right');
      expect(r.steps[1].nomeStrada, 'Via Milano');
      // Lo step successivo inizia dove finisce il precedente.
      expect(r.steps[1].indiceInizio, 1);
    });

    test('ripiega sulla geometria generale se mancano gli step', () {
      final route = {
        'distance': 100.0,
        'duration': 60.0,
        'geometry': {
          'coordinates': [
            [9.0, 45.0],
            [9.001, 45.001],
          ],
        },
      };

      final r = RoutingService.parseRoute(route);

      expect(r.polyline.length, 2);
      expect(r.steps, isEmpty);
    });
  });
}
