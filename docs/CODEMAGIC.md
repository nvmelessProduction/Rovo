# Portare Rova sul telefono con Codemagic (senza computer)

Questa guida è pensata per essere seguita **dal telefono**, usando solo il browser.
Codemagic compila l'app nel cloud (anche la versione iPhone, senza bisogno di un Mac).

Nel progetto c'è già il file `codemagic.yaml` con **tre percorsi** pronti. Scegli in base a
cosa vuoi ottenere.

---

## ⚠️ La verità su iPhone (regola di Apple, non di Codemagic)

Per **installare un'app sul tuo iPhone** Apple richiede in ogni caso un
**account Apple Developer a pagamento: 99 $ / anno**. Non esiste un modo gratuito per mettere
un'app sul proprio iPhone senza un Mac. È un limite di Apple, valido per chiunque.

Quindi hai due strade:

| Voglio… | Percorso | Costo | Cosa ottieni |
|---|---|---|---|
| **Solo vedere/provare** l'app subito | `ios-anteprima` + Appetize.io | **Gratis** | L'app gira in un iPhone "virtuale" dentro il browser del telefono |
| **Installarla davvero** sul mio iPhone | `ios-testflight` | **99 $/anno** (Apple) | L'app sul telefono via TestFlight, come una vera app |

> Consiglio: dato che ora l'app usa dati finti (mock), per iniziare va benissimo l'**anteprima
> gratuita**. Prenderai l'account Apple da 99 $ quando vorrai l'app "vera" sul telefono o
> pubblicarla — serve comunque prima o poi.

---

## Passo 0 — Crea l'account Codemagic (una volta sola)

1. Dal telefono apri **https://codemagic.io** e premi **Sign up**.
2. Scegli **Sign up with GitHub** e accedi con il tuo account GitHub.
3. Autorizza Codemagic ad accedere al repository **rovo**.
4. In Codemagic premi **Add application** → scegli **GitHub** → seleziona il repo **rovo**
   → tipo progetto **Flutter App**.

Codemagic troverà da solo il file `codemagic.yaml`.

---

## Strada A — Anteprima GRATIS (consigliata per iniziare)

Fai girare l'app in un iPhone virtuale, direttamente nel browser del telefono. Nessun account Apple.

1. In Codemagic apri l'app **rova** → premi **Start new build**.
2. Nella tendina dei workflow scegli **“iOS Anteprima (gratis, senza account Apple)”**.
3. Premi **Start build** e aspetta qualche minuto.
4. A fine build, nella sezione **Artifacts**, scarica il file **`Rova-simulator.app.zip`**.
5. In un'altra scheda del browser apri **https://appetize.io** → **Upload** → carica lo zip
   (o l'app estratta). Scegli piattaforma **iOS**.
6. Appetize ti dà un **iPhone virtuale nel browser**: puoi toccare i pulsanti, aprire le tappe
   e vedere Rova funzionare. (Il piano gratuito ha minuti limitati: basta per provarla.)

> Nota: essendo un simulatore, l'audio della guida potrebbe non sentirsi. La cosa importante qui
> è vedere le schermate e i tocchi. L'audio si prova al 100% con l'app vera (Strada B).

---

## Strada B — Installare sul TUO iPhone via TestFlight (99 $/anno)

Questa è la strada per avere Rova **davvero** sul telefono.

### B1. Prendi l'account Apple Developer
1. Dal telefono vai su **https://developer.apple.com/programs** → **Enroll**.
2. Iscriviti con il tuo Apple ID e paga la quota annuale (99 $).
3. L'attivazione può richiedere da poche ore a un paio di giorni (la fa Apple).

### B2. Crea la chiave per Codemagic (App Store Connect API key)
1. Vai su **https://appstoreconnect.apple.com** → **Users and Access** → **Integrations** →
   **App Store Connect API** → **+** per generare una chiave con ruolo **App Manager**.
2. Scarica il file **.p8** e annota **Key ID** e **Issuer ID**.

### B3. Collega la chiave in Codemagic
1. In Codemagic: **Teams / Settings** → **Integrations** → **App Store Connect** → **Add key**.
2. Dai alla chiave il nome **`RovaAppStoreKey`** (è lo stesso nome scritto nel `codemagic.yaml`).
3. Carica il file **.p8** e inserisci **Key ID** e **Issuer ID**.

### B4. Registra l'app su App Store Connect
1. Su **App Store Connect** → **My Apps** → **+** → **New App**.
2. Bundle ID: **`com.rova.rova`** · Nome: **Rova** · Piattaforma: **iOS**.

### B5. Lancia la build
1. In Codemagic → app **rova** → **Start new build**.
2. Workflow: **“iOS TestFlight (richiede Apple Developer 99$/anno)”** → **Start build**.
3. A fine build, l'app viene caricata su **TestFlight**.

### B6. Installa sull'iPhone
1. Dall'App Store del tuo iPhone installa l'app **TestFlight** (di Apple).
2. Apri TestFlight: troverai **Rova** pronta da installare. 🎉
   (Le build TestFlight durano 90 giorni; ne rifai una quando scade o quando aggiorniamo l'app.)

---

## Riepilogo veloce

- **Vuoi solo vederla oggi, gratis** → Strada A (Anteprima + Appetize).
- **La vuoi sul telefono per davvero** → Strada B (Apple Developer 99 $ + TestFlight).

In entrambi i casi il file `codemagic.yaml` è già pronto: devi solo scegliere il workflow giusto
nella schermata di Codemagic.
