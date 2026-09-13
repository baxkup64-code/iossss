# SpotifyClone (SwiftUI)

Eine eigenständige iOS-Musik-App im Spotify-Stil: eigenes Branding, eigener Code,
keine Spotify-Logos/Original-Assets, aber sehr ähnliches Layout, Player-Konzept
und Bediengefühl. Nutzt offizielle Web-APIs (Spotify Web API, SoundCloud API)
nur für Metadaten/Suche/erlaubte Vorschau-Wiedergabe – kein Scraping, keine
private API, kein DRM-Umgehen.

## Projekt-Setup

Das Repo enthält **kein** eingechecktes `.xcodeproj` — stattdessen eine
`project.yml` für [XcodeGen](https://github.com/yonaskolb/XcodeGen), aus der
sowohl lokal als auch in GitHub Actions bei Bedarf ein frisches, sauberes
Xcode-Projekt erzeugt wird. Das ist der Standardweg, um Xcode-Projekte
reproduzierbar und git-freundlich zu halten.

### Lokal in Xcode öffnen

1. XcodeGen installieren: `brew install xcodegen`
2. Im Repo-Root: `xcodegen generate` → erzeugt `SpotifyClone.xcodeproj`
3. `open SpotifyClone.xcodeproj`
4. **Signing & Capabilities** → dein eigenes Apple-ID-Team auswählen (Xcode
   fügt "Background Modes → Audio" nicht automatisch hinzu — das ist aber
   bereits über die `Info.plist` als `UIBackgroundModes: audio` gesetzt, das
   reicht für Hintergrund-Wiedergabe aus).
5. **Optional** — nur falls du zusätzlich zu iTunes auch Spotify/SoundCloud
   nutzen willst, eigene API-Keys eintragen in `Services/APIConfig.swift`
   (siehe Abschnitt "Musik-Quellen" unten). Ohne diesen Schritt läuft die App
   trotzdem voll funktionsfähig über die eingebaute, keyless iTunes-API.
## Musik-Quellen: iTunes läuft sofort, Spotify/SoundCloud sind optional

Standardmäßig aktiv, **ohne dass du etwas tun musst**: die öffentliche
**iTunes Search API** von Apple. Keine Registrierung, kein Key, kein Account
— liefert Suche, Cover und abspielbare 30s-Previews out of the box.

Spotify und SoundCloud lassen sich zusätzlich aktivieren, verlangen dafür
aber zwingend eine eigene (kostenlose) Entwickler-Registrierung — das ist
keine technische Einschränkung dieser App, sondern Teil der Nutzungsbedingungen
beider Anbieter. Es existiert kein gemeinsamer öffentlicher Schlüssel, den
alle Apps mitbenutzen dürften.

   - Spotify: Client ID/Secret aus dem [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
     (Client Credentials Flow reicht für Suche/Metadaten; für echte Wiedergabe
     ganzer Tracks über Spotify ist der iOS SDK + Premium-User-Login von Spotify
     nötig – siehe Hinweis in `SpotifyAPIClient.swift`).
   - SoundCloud: Client ID aus der [SoundCloud API](https://developers.soundcloud.com/).

## IPA über GitHub Actions bauen (ohne eigenen Mac)

Im Ordner `.github/workflows/build-ipa.yml` liegt ein fertiger Workflow, der
auf einem von GitHub bereitgestellten **macOS-Runner** läuft und dir am Ende
eine `.ipa`-Datei zum Download anbietet — du brauchst dafür **keinen eigenen
Mac**, nur einen GitHub-Account.

### Einrichtung (einmalig)

1. Erstelle ein neues **privates** GitHub-Repository (privat empfohlen, da
   API-Keys sonst öffentlich sichtbar wären).
2. Lade den kompletten Inhalt dieses Ordners hoch, z. B.:
   ```bash
   cd SpotifyClone
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/DEIN-NAME/DEIN-REPO.git
   git push -u origin main
   ```
   (Alternativ: im GitHub-Web-UI "Add file → Upload files" nutzen.)
3. Gehe im Repo auf den Tab **Actions**. GitHub erkennt die Workflow-Datei
   automatisch und bietet an, sie zu aktivieren.

### Build starten

- Jeder Push auf `main` startet automatisch einen Build.
- Manuell geht's auch: **Actions → "Build IPA" → Run workflow**.
- Nach ca. 5–10 Minuten erscheint unten im abgeschlossenen Workflow-Lauf unter
  **Artifacts** die Datei `SpotifyClone-unsigned-ipa` — herunterladen, entpacken,
  fertig ist die `.ipa`.

### Wichtig: die IPA ist unsigniert

Der Workflow baut bewusst **ohne Code-Signatur** (`CODE_SIGNING_ALLOWED=NO`),
weil ein normaler GitHub-Runner kein Zertifikat/Provisioning-Profil deines
Apple-Accounts besitzt. Eine unsignierte IPA kann nicht direkt per Kabel oder
TestFlight installiert werden. Um sie auf ein echtes iPhone zu bekommen, hast
du zwei gängige Wege:

**Option A — Kostenlos, mit AltStore/SideStore (empfohlen für Privatnutzung)**
1. [AltStore](https://altstore.io) oder [SideStore](https://sidestore.io) auf
   dem iPhone installieren (Anleitung auf den jeweiligen Seiten).
2. Die heruntergeladene `SpotifyClone-unsigned.ipa` über AltStore/SideStore
   mit deiner normalen Apple-ID installieren — die App signiert die IPA dabei
   automatisch mit deinem kostenlosen Entwicklerzertifikat.
3. Einschränkung: mit einer kostenlosen Apple-ID muss die App alle 7 Tage neu
   signiert werden (AltStore/SideStore machen das automatisiert im Hintergrund,
   solange dein iPhone gelegentlich im gleichen WLAN wie ein "AltServer"-Rechner ist).

**Option B — Mit bezahltem Apple Developer Program (99 $/Jahr)**
Wenn du ein Entwicklerkonto hast, kannst du dem Workflow dein Zertifikat +
Provisioning-Profil als **GitHub Secrets** mitgeben und ihn so erweitern, dass
er eine fertig signierte Ad-hoc-IPA baut, die sich direkt über Xcode, Diawi
oder TestFlight installieren lässt. Sag Bescheid, wenn du das willst — dafür
müsste ich den Workflow um einen Signing-Schritt (Base64-codiertes `.p12` +
`.mobileprovision` als Secrets, `security import` + `xcodebuild -exportArchive`)
erweitern.

## Was tatsächlich funktioniert

- Vollständige Navigation (Home, Search, Library, Playlists, Fullscreen Player, Settings)
- Eigener Audio-Player auf Basis von `AVPlayer`/`AVAudioSession`:
  - Background Audio (läuft weiter bei Sperrbildschirm / App-Wechsel)
  - Lockscreen- & Control-Center-Steuerung via `MPNowPlayingInfoCenter` +
    `MPRemoteCommandCenter`
  - Play/Pause, Next/Previous, Shuffle, Repeat, Seekbar, Queue, Like
  - Mini-Player ↔ Fullscreen-Player mit `matchedGeometryEffect`-Übergang
- Lokale Playlists mit SwiftData (erstellen, umbenennen, Songs hinzufügen/
  entfernen/umsortieren, löschen) – komplett offline, kein Login nötig
- Suche gegen Spotify Web API & SoundCloud API (Songs/Künstler/Alben/Playlists)
- Einfacher lokaler „Offline"-Bereich für Tracks mit erlaubter Preview-URL
  (30-Sekunden-Previews werden lokal gecached; das ist der einzige Umfang,
  den beide APIs offiziell für Offline-Nutzung ohne Premium-SDK erlauben)

## Wichtiger rechtlicher Hinweis

Volle Songs von Spotify lassen sich in einer Dritt-App **nur** über das
offizielle Spotify iOS SDK mit eingeloggtem Premium-Account abspielen (kein
direkter Stream-URL-Zugriff über die Web API). Der Code hier ist so gebaut,
dass er sich 1:1 auf das Spotify iOS SDK umstecken lässt (`PlaybackSource`
Protokoll in `AudioPlayerService.swift`), aber ohne offizielle SDK-Einbindung
(CocoaPods/SPM von Spotify + App-Review durch Spotify) nutzt die Demo hier die
öffentlich abspielbaren 30s-Previews (`preview_url`) aus der Spotify Web API
und die offiziell freigegebenen Stream-URLs der SoundCloud API.
