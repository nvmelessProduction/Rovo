import 'package:latlong2/latlong.dart';

import '../models/fuel_station.dart';
import '../models/itinerary.dart';
import '../models/stop.dart';

/// Dati di seed per la Milestone 1.
///
/// Tutto è locale e mock: nessuna chiamata di rete, così l'app funziona
/// anche offline. Dalla M2 questi dati arriveranno dal database sul server
/// personale, ma i tipi (Stop / FuelStation / Itinerary) restano identici.

/// Le 6 tappe de "La Via del Chianti" (Firenze -> Siena).
const List<Stop> _chiantiStops = [
  Stop(
    id: 'stop-1',
    numero: 1,
    titolo: 'Firenze — Piazzale Michelangelo',
    posizione: LatLng(43.7629, 11.2650),
    racconto:
        'Benvenuto sulla Via del Chianti. Partiamo da Piazzale Michelangelo, '
        'la terrazza più famosa di Firenze: da qui lo sguardo abbraccia il '
        'Duomo del Brunelleschi, la torre di Palazzo Vecchio e il nastro '
        'argentato dell\'Arno. È il punto di saluto perfetto alla città prima '
        'di scendere verso le colline. Allaccia le cinture: davanti a te si '
        'aprono i vigneti del Chianti.',
  ),
  Stop(
    id: 'stop-2',
    numero: 2,
    titolo: 'Strada in Chianti',
    posizione: LatLng(43.6710, 11.3040),
    racconto:
        'Siamo entrati nella Chiantigiana, la mitica strada regionale 222. '
        'Strada in Chianti è la prima porta del vino: un tempo qui passavano '
        'i mercanti che portavano le botti verso Firenze. Nota come il '
        'paesaggio cambia: file ordinate di viti, cipressi solitari e casali '
        'in pietra dorata. Ogni curva è una cartolina.',
  ),
  Stop(
    id: 'stop-3',
    numero: 3,
    titolo: 'Greve in Chianti',
    posizione: LatLng(43.5836, 11.3157),
    racconto:
        'Greve in Chianti è considerata la capitale del Gallo Nero, il '
        'simbolo del Chianti Classico. La sua piazza triangolare, Piazza '
        'Matteotti, è circondata da portici irregolari e botteghe di vino e '
        'salumi. Al centro spicca la statua di Giovanni da Verrazzano, il '
        'navigatore che per primo esplorò la baia di New York. Un buon momento '
        'per una sosta e un assaggio.',
  ),
  Stop(
    id: 'stop-4',
    numero: 4,
    titolo: 'Panzano in Chianti',
    posizione: LatLng(43.5460, 11.3130),
    racconto:
        'Arroccato su un colle, Panzano regala una delle viste più ampie sulla '
        'Conca d\'Oro, l\'anfiteatro di vigneti che produce alcuni dei rossi '
        'più celebri della Toscana. Il paese è famoso anche per la sua '
        'macelleria storica e la cultura della bistecca. Fermati un istante: '
        'il silenzio delle colline qui è parte del viaggio.',
  ),
  Stop(
    id: 'stop-5',
    numero: 5,
    titolo: 'Castellina in Chianti',
    posizione: LatLng(43.4700, 11.2870),
    racconto:
        'Castellina in Chianti conserva l\'anima medievale del territorio, con '
        'la sua rocca e la suggestiva Via delle Volte, un camminamento coperto '
        'che un tempo faceva parte delle mura difensive. Da borgo di confine '
        'tra Firenze e Siena, ha visto secoli di battaglie. Oggi è pace pura, '
        'tra enoteche e panorami che si perdono verso le crete senesi.',
  ),
  Stop(
    id: 'stop-6',
    numero: 6,
    titolo: 'Siena — Piazza del Campo',
    posizione: LatLng(43.3188, 11.3308),
    racconto:
        'Eccoci a Siena, meta del nostro viaggio. Piazza del Campo, a forma di '
        'conchiglia, è una delle piazze più belle del mondo e ospita due volte '
        'l\'anno il Palio. Sopra di essa svetta la Torre del Mangia, mentre i '
        'vicoli attorno raccontano una città rimasta intatta dal Medioevo. '
        'La Via del Chianti finisce qui: spegni il motore e goditi la meta.',
  ),
];

/// Geometria approssimata del percorso lungo la SR222 Chiantigiana.
/// In M1 è hardcoded (mock); dalla M4 arriverà da un motore di routing.
const List<LatLng> _chiantiRoute = [
  LatLng(43.7629, 11.2650), // Firenze
  LatLng(43.7480, 11.2760),
  LatLng(43.7310, 11.2880),
  LatLng(43.7120, 11.2960),
  LatLng(43.6910, 11.3010),
  LatLng(43.6710, 11.3040), // Strada in Chianti
  LatLng(43.6520, 11.3080),
  LatLng(43.6330, 11.3120),
  LatLng(43.6120, 11.3150),
  LatLng(43.5836, 11.3157), // Greve in Chianti
  LatLng(43.5680, 11.3150),
  LatLng(43.5460, 11.3130), // Panzano in Chianti
  LatLng(43.5230, 11.3050),
  LatLng(43.5010, 11.2960),
  LatLng(43.4700, 11.2870), // Castellina in Chianti
  LatLng(43.4380, 11.2900),
  LatLng(43.4050, 11.3010),
  LatLng(43.3720, 11.3150),
  LatLng(43.3440, 11.3260),
  LatLng(43.3188, 11.3308), // Siena
];

/// L'itinerario turistico completo usato in M1.
final Itinerary viaDelChianti = Itinerary(
  id: 'via-del-chianti',
  titolo: 'La Via del Chianti',
  sottotitolo: 'Firenze → Siena · SR222 Chiantigiana',
  stops: _chiantiStops,
  routePolyline: _chiantiRoute,
  km: 71,
  durataMin: 95,
);

/// Distributori mock lungo il percorso. Il più economico (benzina) verrà
/// evidenziato in automatico dalla schermata Carburante.
const List<FuelStation> fuelStationsMock = [
  FuelStation(
    id: 'fuel-1',
    nome: 'Q8 Grassina',
    brand: 'Q8',
    posizione: LatLng(43.6980, 11.3050),
    prezzoBenzina: 1.879,
    prezzoGasolio: 1.769,
    indirizzo: 'Via Chiantigiana 12, Grassina (FI)',
  ),
  FuelStation(
    id: 'fuel-2',
    nome: 'Eni Station Greve',
    brand: 'Eni',
    posizione: LatLng(43.5900, 11.3170),
    prezzoBenzina: 1.849,
    prezzoGasolio: 1.739,
    indirizzo: 'Viale Vittorio Veneto 3, Greve in Chianti (FI)',
  ),
  FuelStation(
    id: 'fuel-3',
    nome: 'IP Panzano',
    brand: 'IP',
    posizione: LatLng(43.5480, 11.3110),
    prezzoBenzina: 1.899,
    prezzoGasolio: 1.789,
    indirizzo: 'Via Chiantigiana 88, Panzano (FI)',
  ),
  FuelStation(
    id: 'fuel-4',
    nome: 'Esso Castellina',
    brand: 'Esso',
    posizione: LatLng(43.4720, 11.2850),
    prezzoBenzina: 1.829, // il più economico
    prezzoGasolio: 1.719,
    indirizzo: 'Località Il Ponte 4, Castellina in Chianti (SI)',
  ),
  FuelStation(
    id: 'fuel-5',
    nome: 'Tamoil Siena Nord',
    brand: 'Tamoil',
    posizione: LatLng(43.3440, 11.3200),
    prezzoBenzina: 1.859,
    prezzoGasolio: 1.749,
    indirizzo: 'Strada di Pescaia 21, Siena (SI)',
  ),
];
