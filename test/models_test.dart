// Test della logica dei modelli: lettura dei dati dei servizi e formattazione
// mostrata all'utente (durata, distanza, orario di arrivo).

import 'package:flutter_test/flutter_test.dart';
import 'package:rova/models/place.dart';
import 'package:rova/models/route_result.dart';

void main() {
  group('Place.fromNominatim', () {
    test('separa nome e descrizione dal display_name', () {
      final p = Place.fromNominatim({
        'osm_type': 'node',
        'osm_id': 123,
        'lat': '41.9552',
        'lon': '12.0803',
        'display_name': 'Ladispoli, Roma, Lazio, Italia',
      });

      expect(p.nome, 'Ladispoli');
      expect(p.descrizione, 'Roma, Lazio, Italia');
      expect(p.posizione.latitude, closeTo(41.9552, 0.0001));
      expect(p.posizione.longitude, closeTo(12.0803, 0.0001));
    });

    test('gestisce un display_name senza virgole', () {
      final p = Place.fromNominatim({
        'osm_id': 1,
        'lat': '43.0',
        'lon': '11.0',
        'display_name': 'Colosseo',
      });

      expect(p.nome, 'Colosseo');
      expect(p.descrizione, '');
    });
  });

  group('RouteResult', () {
    test('formatta durata e distanza per un tragitto lungo', () {
      const r = RouteResult(polyline: [], metri: 71000, secondi: 5700);

      expect(r.distanzaLabel, '71 km');
      expect(r.durataLabel, '1h 35min');
      expect(r.minuti, 95);
    });

    test('usa i metri sotto il chilometro', () {
      const r = RouteResult(polyline: [], metri: 850, secondi: 120);

      expect(r.distanzaLabel, '850 m');
      expect(r.durataLabel, '2min');
    });

    test('mostra un decimale per distanze brevi in km', () {
      const r = RouteResult(polyline: [], metri: 4300, secondi: 600);

      expect(r.distanzaLabel, '4.3 km');
    });

    test('omette i minuti quando la durata è in ore piene', () {
      const r = RouteResult(polyline: [], metri: 200000, secondi: 7200);

      expect(r.durataLabel, '2h');
    });

    test('orario di arrivo formattato hh:mm', () {
      const r = RouteResult(polyline: [], metri: 1000, secondi: 600);

      expect(r.arrivoLabel, matches(r'^\d{2}:\d{2}$'));
    });
  });
}
