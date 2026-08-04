# Rova 🚗🍷

App mobile di **navigazione stradale** (stile Waze / Google Maps) con due funzioni in più:
- **Prezzi dei carburanti** dei distributori.
- **Guida turistica audio selezionabile** — il cuore del prodotto: quando fai un viaggio
  “esperienza”, attivi la modalità Turismo e l’app ti **racconta i luoghi mentre guidi**. Nella
  navigazione normale (es. casa → lavoro) l’app resta muta.

Questo repository contiene la **Milestone 1**: le fondamenta funzionanti dell’app, con dati locali
(mock). Backend, prezzi live, traffico e navigazione vocale arrivano nelle milestone successive
(vedi *Roadmap* in fondo).

---

## Cosa fa la Milestone 1

- 🗺️ **Mappa a tutto schermo** (OpenStreetMap) centrata sulla Toscana.
- 🍷 **Modalità Turismo** con l’itinerario **“La Via del Chianti” (Firenze → Siena)**: percorso
  disegnato sulla mappa, **6 tappe numerate** e **marker dei distributori**, tutti toccabili.
- 🎧 **Guida audio in italiano**: apri una tappa e premi **“Ascolta la guida”** — l’app legge il
  racconto con la sintesi vocale (TTS).
- ⛽ **Schermata Carburante**: lista dei distributori con il **più economico evidenziato**.
- 📋 **Scheda Turismo** con statistiche del viaggio (km, durata, tappe) e “Avvia esperienza”.

> La modalità Turismo si **attiva a mano**: di default l’app è una navigazione sobria e silenziosa.

---

## Requisiti

- **Flutter SDK** (canale stable). Guida ufficiale: <https://docs.flutter.dev/get-started/install>
- Verifica l’ambiente con:
  ```bash
  flutter doctor
  ```

Nessun token o chiave API è necessario: la mappa usa OpenStreetMap, **niente segreti nel codice**.

---

## Setup (una volta sola)

```bash
# dalla cartella del progetto
flutter pub get
```

---

## Come avviare l’app

### A) Anteprima veloce nel browser (la più semplice)
```bash
flutter run -d chrome
```
Si apre l’app nel browser. Utile per vedere subito schermate, liste e la guida audio.

### B) Su un telefono/emulatore **Android**
```bash
flutter devices        # controlla che il device sia visibile
flutter run            # se c'è un solo device parte lì
```
(Per l’emulatore serve Android Studio; per un telefono fisico attiva “Debug USB”.)

### C) Sul tuo **iPhone** — serve un **Mac con Xcode**
Apple permette di installare app iOS **solo da un Mac**. Sul Mac:
```bash
# 1) Installa Flutter e Xcode (vedi flutter doctor)
# 2) Collega l'iPhone via cavo e sbloccalo ("Fidati di questo computer")
cd ios && pod install && cd ..
flutter run            # seleziona il tuo iPhone
```
La prima volta Xcode chiede un **Apple ID** per firmare l’app (basta un account gratuito).
Apri `ios/Runner.xcworkspace` in Xcode, in *Signing & Capabilities* scegli il tuo team, poi riprova
`flutter run`.

### D) Sul tuo iPhone **senza computer** — build cloud (Codemagic) 👈 il tuo caso
Se lavori solo dal telefono, Codemagic compila l’app nel cloud (anche iOS, senza un Mac).
Nel repo c’è già il file `codemagic.yaml` con tre percorsi pronti (anteprima gratis, Android,
iPhone/TestFlight).

📖 **Guida passo-passo pensata per il telefono:** [`docs/CODEMAGIC.md`](docs/CODEMAGIC.md)

> In breve: per **vedere subito** l’app è gratis (anteprima nel browser). Per **installarla davvero
> sull’iPhone** Apple richiede un account **Apple Developer (99 $/anno)** — è un limite di Apple,
> non c’è modo gratuito di mettere un’app sul proprio iPhone senza un Mac.

---

## Struttura del progetto

```
lib/
  main.dart                 # avvio app + barra a 3 schede (Mappa · Turismo · Carburante)
  theme/app_theme.dart      # colori e tipografia (design centralizzato)
  models/                   # tipi dati: Stop, FuelStation, Report, Itinerary
  data/seed.dart            # dati mock: itinerario Via del Chianti + distributori
  services/tts_service.dart # guida audio (TTS italiano)
  state/app_state.dart      # stato leggero (modalità, tappa selezionata) via provider
  screens/                  # home (mappa), itinerario, guida, carburante
  components/               # marker, bottom sheet, riquadri statistiche
```

I tipi in `models/` sono pensati per mappare 1:1 le future tabelle del database: quando
passeremo dal seed al backend (M2) il modello dati non cambia.

---

## Note tecniche

- **Mappa**: `flutter_map` + tile **OpenStreetMap**. In sviluppo va benissimo; per la produzione, i
  tile pubblici OSM hanno limiti d’uso — in futuro useremo un tile server dedicato (anche sul server
  personale).
- **Guida audio**: `flutter_tts`, lingua `it-IT`. Su iOS/Android usa le voci di sistema. Su web
  alcune funzioni TTS sono limitate: per provare l’audio, meglio Android/iPhone.
- **Percorso**: in M1 la linea del percorso è un dato mock (approssima la SR222 Chiantigiana). Il
  calcolo reale del percorso arriva con il motore di routing (M4).

---

## Roadmap (visione completa)

| Milestone | Contenuto |
|-----------|-----------|
| **M1** ✅ | Fondamenta app + prima esperienza turistica (questa) — tutto mock |
| **M2** | Backend e database da zero su server personale; l’app legge dati reali |
| **M3** | Prezzi carburante **live** (open data Osservaprezzi MIMIT) |
| **M4** | Motore di routing + **navigazione vocale** turn-by-turn |
| **M5** | Traffico, stima orari, “quando partire”, **cantieri live** |
| **M6** | Segnalazioni community in tempo reale (stile Waze) |
| **M7** | Tanti itinerari turistici + pipeline contenuti |

---

## Comandi utili

```bash
flutter pub get        # installa le dipendenze
flutter analyze        # controlla il codice (deve dire "No issues found")
flutter test           # esegue i test
flutter run -d chrome  # avvia nel browser
```
