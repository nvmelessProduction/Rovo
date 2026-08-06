# Rova — Security Review & Guida alla ricerca delle falle

> **A cosa serve questo documento.** È un audit di sicurezza dell'app **Rova** (codice tuo,
> per renderla più sicura). Contiene: (1) come ragiona chi cerca vulnerabilità, (2) le cose
> trovate sul codice attuale con la relativa gravità e correzione, (3) un metodo sistematico
> per trovare falle che "nessuno troverebbe", (4) i rischi che arriveranno con il backend (M2).
>
> **Regola d'oro etica/legale:** questo vale **solo sulla TUA app e sui TUOI server**. Testare
> sistemi di altri (inclusi i server pubblici OpenStreetMap/OSRM) senza permesso scritto è
> illegale. Quando avrai il tuo server, testa **quello**, non le infrastrutture altrui.

---

## 0. Come pensa chi cerca falle (il metodo, prima degli strumenti)

Le falle "che nessuno trova" non si scoprono a caso: si trovano **modellando il sistema** e
poi attaccando i punti dove i dati **attraversano un confine di fiducia** (trust boundary).

Tre domande guida, da farsi per ogni funzione:
1. **Da dove entrano i dati?** (input utente, rete, file, sensori) → è la *superficie d'attacco*.
2. **Di chi mi fido?** (l'utente? il server OSRM? il sistema operativo?) → ogni fiducia è un rischio.
3. **Cosa succede se quel dato è ostile?** (troppo lungo, malformato, malevolo, assente).

Modello mentale **STRIDE** (una minaccia per lettera):
- **S**poofing — qualcuno finge di essere un altro (es. server finto).
- **T**ampering — qualcuno altera i dati (es. risposta di rete modificata).
- **R**epudiation — azioni non tracciabili (log assenti).
- **I**nformation disclosure — fuga di dati (es. la posizione GPS dell'utente).
- **D**enial of service — rendere l'app/servizio inutilizzabile.
- **E**levation of privilege — ottenere permessi non propri (rilevante col backend).

---

## 1. Mappa dell'app (superficie d'attacco attuale)

Rova oggi è **solo client** (nessun backend, nessun login, nessun dato salvato sul server).
I confini di fiducia attuali:

```
[Utente] --testo ricerca--> [App Rova] --HTTPS--> [Nominatim]  (geocoding)
[GPS]    --coordinate----->  [App Rova] --HTTPS--> [OSRM]       (percorso)
                                        --HTTPS--> [tile.osm]   (mappa)
```

Punti di ingresso dei dati:
- **Barra di ricerca** → `lib/services/geocoding_service.dart`
- **Coordinate GPS** (sensore) → `lib/services/location_service.dart`
- **Risposte JSON di rete** (Nominatim, OSRM) → `geocoding_service.dart`, `routing_service.dart`
- **Tile immagini** della mappa → `home_screen.dart`, `navigation_screen.dart`

File sensibili di configurazione:
- `ios/Runner/Info.plist` (permessi, crittografia)
- `android/app/src/main/AndroidManifest.xml` (permessi)
- `codemagic.yaml` (build/firma — **non** contiene segreti: usa chiavi salvate in Codemagic)

---

## 2. Risultati dell'audit sul codice attuale

Legenda gravità: 🔴 Alta · 🟠 Media · 🟡 Bassa · 🟢 OK/positivo.

### 🟢 Cose già fatte bene
- **Nessun segreto nel repository** (`git ls-files` non trova `.env`, `.p8`, `.p12`, chiavi). La
  chiave di firma Apple vive in Codemagic, non nel codice. ✅
- **HTTPS ovunque**, nessuna eccezione ATS su iOS (`NSAllowsArbitraryLoads` assente) → niente
  traffico in chiaro. ✅
- **Input di ricerca passato come parametro** via `Uri.https(...)`: Dart fa l'URL-encoding, quindi
  **niente URL/injection** verso Nominatim (`geocoding_service.dart:23`). ✅
- **Parsing di rete difensivo**: i valori numerici vengono convertiti con controlli, e c'è un
  fallback se mancano gli step (`routing_service.dart` `parseRoute`). ✅
- **GPS non blocca l'app**: `LocationService` non lancia mai eccezioni verso la UI. ✅

### 🟠 M-1 — Fuga della posizione verso terze parti (privacy)
- **Dove:** `geocoding_service.dart`, `routing_service.dart`.
- **Cosa:** la **posizione precisa** dell'utente e le sue destinazioni vengono inviate a
  server **pubblici di terzi** (Nominatim, OSRM demo). Questi possono, in teoria, registrare
  "chi va dove". Per un'app di navigazione è il dato più sensibile che esista.
- **Rischio:** information disclosure. Non è un bug di codice, è una scelta architetturale.
- **Fix:** (a) nella futura privacy policy dichiararlo; (b) con il backend (M2) fai passare le
  richieste **dal tuo server** (proxy), così i terzi vedono il tuo server e non i singoli utenti;
  (c) valuta di **arrotondare** le coordinate per il geocoding quando la precisione non serve.

### 🟠 M-2 — Dipendenza da endpoint pubblici "demo"
- **Dove:** `routing_service.dart:17` (`router.project-osrm.org`), tile OSM.
- **Cosa:** sono server **demo**, non per produzione: possono rallentare, bloccarti o sparire.
  Se un domani uno di questi host venisse compromesso, potrebbe restituire percorsi errati.
- **Rischio:** disponibilità (DoS di fatto) + integrità dei dati.
- **Fix:** in M2/M4 self-hostare OSRM e un tile server (è già previsto: cambia solo `_host`).
  Nel frattempo, tratta **sempre** le risposte come non fidate (già fatto, mantienilo).

### 🟡 B-1 — Nessun certificate pinning
- **Cosa:** l'app si fida di qualsiasi certificato valido secondo il sistema. Su un dispositivo
  con una **CA malevola installata** (es. telefono aziendale/compromesso) un attaccante potrebbe
  fare man-in-the-middle e leggere/alterare il traffico.
- **Rischio:** tampering/disclosure in scenari mirati.
- **Fix (dopo il backend):** aggiungi **certificate pinning** verso il **tuo** dominio (pin del
  certificato/chiave pubblica). Non ha senso fare pinning verso server pubblici che ruotano i cert.

### 🟡 B-2 — Cleartext non disabilitato in modo esplicito (Android)
- **Dove:** `AndroidManifest.xml`.
- **Cosa:** oggi non usi HTTP in chiaro, ma non è vietato esplicitamente.
- **Fix:** aggiungi `android:usesCleartextTraffic="false"` nel tag `<application>` per bloccare
  per sempre eventuali richieste in chiaro introdotte per errore in futuro.

### 🟡 B-3 — Testo di terzi letto/mostrato senza sanitizzazione forte
- **Dove:** i nomi di luogo da Nominatim finiscono nella UI e nel TTS.
- **Cosa:** oggi in Flutter il testo non è "eseguibile" (niente HTML/JS), quindi il rischio è
  minimo. Diventa rilevante **se** un domani mostrerai questi dati in una WebView o li userai in
  query verso il tuo DB.
- **Fix:** quando arriverà il backend, **non** costruire mai query concatenando stringhe.

### 🟡 B-4 — Assenza di logging/telemetria di sicurezza
- **Cosa:** non c'è modo di accorgersi di comportamenti anomali (Repudiation nello STRIDE).
- **Fix:** con il backend, logga gli eventi di sicurezza lato server (login, errori auth,
  rate-limit) — **mai** dati sensibili nei log (niente posizioni precise, niente token).

---

## 3. Come cercare le falle "che nessuno troverebbe" — metodo pratico

Questi passi valgono **sulla tua app**. Vanno dal più semplice al più avanzato.

### 3.1 Analisi statica (leggere il codice con occhi da attaccante)
- Cerca ogni punto in cui un dato **esterno** viene **usato**: `grep` di `http`, `Uri`, `jsonDecode`,
  `TextField`, `onChanged`, e in futuro `query`, `rawQuery`, `exec`, `File(`.
- Per ognuno chiediti le 3 domande del capitolo 0.
- Strumenti gratis: `flutter analyze`, `dart analyze`, e per le dipendenze `flutter pub outdated`.

### 3.2 Analisi delle dipendenze (supply chain)
- Le falle più "invisibili" spesso stanno nei **pacchetti** che usi, non nel tuo codice.
- Controlla regolarmente: `flutter pub outdated`, e le advisory su https://github.com/advisories.
- **Fissa le versioni** (già fatto in `pubspec.lock`) e aggiorna con criterio, leggendo i changelog.

### 3.3 Osservare il traffico di rete (il punto più rivelatore)
- Usa un proxy di intercettazione **sul tuo telefono/emulatore**: **mitmproxy** (gratis) o Burp Suite.
- Vedrai **esattamente** quali dati escono (incluse le tue coordinate!). È il modo migliore per
  scoprire fughe di dati inaspettate.
- Prova a **modificare** le risposte (es. un percorso assurdo, un JSON troncato, campi mancanti) e
  verifica che l'app **non crashi** e non si comporti in modo pericoloso. Questo è **fuzzing** manuale.

### 3.4 Fuzzing degli input
- Nella barra di ricerca prova: stringhe lunghissime, emoji, caratteri strani (`' " < > ; %00`),
  testo in altre lingue, solo spazi. L'app deve reggere senza crash e senza comportamenti strani.
- Automatizzabile con test: aggiungi casi limite ai test in `test/` (già presenti per i modelli).

### 3.5 Ispezione del pacchetto compilato (IPA/APK)
- Sul **tuo** build: apri l'IPA/APK (è uno zip) e cerca **segreti dimenticati** dentro il binario
  o negli asset (`grep -r "key\|token\|secret\|password"`).
- Su Android puoi decompilare con `apktool`/`jadx` (gratis) per vedere cosa è realmente incluso.
- Obiettivo: assicurarti che **nessuna chiave** finisca dentro l'app distribuita.

### 3.6 Test su dispositivo "ostile"
- Prova l'app su un dispositivo con **jailbreak/root** o con una **CA custom** installata: è lo
  scenario in cui manca il certificate pinning (B-1) diventa sfruttabile.

### 3.7 Deep link e superfici nascoste
- Quando aggiungerai deep link/URL scheme, ogni link diventa un input: testalo come tale.

---

## 4. I rischi VERI arriveranno con il backend (M2) — preparati ora

Oggi l'app è poco attaccabile perché **non c'è un server tuo né dati di utenti**. Il **90% delle
vulnerabilità gravi** nascerà quando costruirai il backend. Tienile a mente da subito
(riferimento: **OWASP Top 10** e **OWASP API Security Top 10**):

- **Autenticazione/Autorizzazione:** ogni richiesta deve verificare *chi sei* e *cosa puoi vedere*.
  La falla più comune (**IDOR/BOLA**): cambio un id nell'URL e vedo i dati di un altro utente.
- **Injection (SQL/NoSQL/comandi):** **mai** costruire query concatenando testo. Usa query
  parametrizzate/prepared statement.
- **Gestione segreti:** chiavi API e password del DB **fuori dal codice** (variabili d'ambiente sul
  server, secret manager). Mai committarle. Ruotale se trapelano.
- **Rate limiting & anti-abuso:** proteggi le API dalla forza bruta e dallo scraping.
- **Trasporto:** HTTPS obbligatorio anche server-side; **certificate pinning** dall'app verso il tuo dominio.
- **Dati sensibili a riposo:** cifra le posizioni/tracciati degli utenti nel DB; conserva il minimo
  indispensabile (data minimization) e definisci una retention.
- **Validazione lato server:** non fidarti **mai** di ciò che manda l'app (l'app può essere modificata).
- **Dipendenze del server:** stesso discorso della supply chain, aggiornamenti e scanner.
- **Logging & monitoraggio:** traccia gli eventi di sicurezza, senza salvare dati personali nei log.

---

## 5. Checklist rapida (da rifare a ogni milestone)

- [ ] `git ls-files` non contiene segreti (`.env`, `.p8`, `.p12`, chiavi, password)
- [ ] `flutter analyze` pulito · `flutter pub outdated` controllato
- [ ] Nessuna eccezione HTTPS (ATS iOS integro, cleartext Android disabilitato)
- [ ] Ogni input esterno validato; nessuna query costruita per concatenazione
- [ ] Traffico osservato con proxy: escono solo i dati previsti
- [ ] IPA/APK ispezionato: nessun segreto nel binario
- [ ] (con backend) Auth su ogni endpoint · test IDOR/BOLA · rate limiting · pinning · cifratura dati
- [ ] Privacy policy che dichiara l'uso della posizione e dei servizi di terzi

---

## 6. Correzioni consigliate subito (basso sforzo, buon guadagno)

1. **B-2:** aggiungere `android:usesCleartextTraffic="false"` nel manifest Android.
2. **M-1 (parziale):** preparare una privacy policy che dichiari l'uso di posizione e servizi terzi.
3. Impostare un promemoria mensile per `flutter pub outdated` + advisory GitHub.
4. Pianificare, con il backend (M2): proxy delle richieste, auth, rate limiting, certificate pinning.

> Nota finale: la sicurezza non è un traguardo ma un'abitudine. Rifai la **checklist del §5** a
> ogni milestone e avrai già più rigore del 90% delle app.
