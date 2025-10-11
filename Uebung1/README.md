Geoinformatik 2 – Web-GIS
# Übung 1 · HTML Webseite mit Copilot
Prof. Dr. Yu Feng

## Lernziele
Nach dieser Übung können Sie:
- mit Copilot ein statisches HTML-Dokument erzeugen und anpassen;
- Grundbausteine einer Webseite einsetzen: Text, Überschriften, Tabelle, Bild, Links;
- eine 1×3-Galerie bauen, deren Kacheln auf externe Links führen;
- eine Seite responsiv, zugänglich (alt-Texte) und leichtgewichtig gestalten;
- die Seite ohne Kommandozeile auf Netlify deployen.

## I. Vorbereitungen der Umgebung

### 1) VS Code installieren (auf deinem eigenen Rechner)
- Besuche die offizielle Website und lade den Installer herunter (für Windows/macOS/Linux https://code.visualstudio.com/download#).

### 2) Live Server Erweiterung installieren (für lokale Vorschau)
- In VS Code links auf **Erweiterungen (Extensions)** klicken → nach **„Live Server“** suchen → **Installieren**.
- Oder finden Sie hier dirket unter https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer
- Unten rechts erscheint ein Button **Go Live**; alternativ kannst du in `index.html` mit Rechtsklick **Open with Live Server** wählen.  
- Dadurch startet ein lokaler Server (meist unter `http://127.0.0.1:5500`), und die Seite wird bei jedem Speichern automatisch aktualisiert.  

### 3) GitHub Copilot aktivieren (stark empfohlen)
- Copilot ist nicht zwingend erforderlich, aber sehr hilfreich für automatische Code-Vervollständigungen.  
- Öffne den Erweiterungsmarkt in VS Code → suche nach **„GitHub Copilot“** → **Installieren**.  
- Unten rechts erscheint ein Hinweis zum GitHub-Login → klicke auf **Anmelden** und erteile die Berechtigung (erfordert ein aktives Copilot-Abo oder eine konstenlose Edu-Lizenz, aktiviere hier unter https://github.com/education).  
- In der Statusleiste erscheint ein Copilot-Symbol, das den aktiven Status anzeigt.  
- Beim Schreiben in `index.html` oder `styles.css` schlägt Copilot in grauer Schrift Code vor → mit **Tab** bestätigen, um ihn zu übernehmen.  

## II. Projektstruktur & Start

Erstelle eine persönliche Startseite `index.html` (ohne Frameworks, kein JS nötig), die **mindestens** Folgendes enthält:

1. **Intro**: `<h1>` + 1–2 Absätze über dich.  
2. **Kurz-CV als Tabelle**: 2–4 Spalten, 4–8 Zeilen (Jahr · Station · Ort · Stichwort).  
3. **Ein Foto**: z. B. `assets/me.jpg`, mit sinnvollem `alt` und kurzer Bildunterschrift.  
4. **Galerie 1×3**: drei Karten/Teaser (Bild + Titel + Kurztext), **Klick → externer Link** (z. B. GitHub, Portfolio, Fotoblog).  
5. **Grund-CSS**: gut lesbar, mobilfreundlich (≤ 720 px → 1-spaltig).  
6. **Zugänglichkeit**: alt-Texte, klare Linktexte/`aria-label`, ausreichender Farbkontrast.  

### Mögliche Copilot-Prompts

**Prompt 1 – Grundgerüst + Inhalte**  
> *„Erzeuge eine minimalistische persönliche Startseite als **einzelne `index.html`** (ohne Frameworks). Inhalte: (1) Titel + 1–2 Absätze; (2) **Tabelle** mit 6 Stationen (Jahr, Station, Ort, Stichwort); (3) **Bild** `assets/me.jpg`; (4) **Galerie 1×3** mit drei Karten (Bild, Titel, Kurztext), die **auf externe Links** führen. Anforderungen: semantisches HTML5 (`header`, `main`, `section`, `figure`, `table`), responsives **CSS** (max-width, Grid/Flex), guter Farbkontrast, System-Schriftarten. Alles in **einer Datei** liefern (inkl. `<style>`).“*

**Prompt 2 – Look & Feel verfeinern**  
> *„Passe Farben an (Akzent #20b581ff), erhöhe Zeilenhöhe/Abstände, füge Karten-Schatten & abgerundete Ecken hinzu, mache die Tabelle mit Hover-Zeilen, und stelle sicher: ≤ 720 px → Galerie 1-spaltig.“*

**Prompt 3 – Galerie-Links ersetzen**  
> *„Ersetze die drei Galerie-Karten durch: GitHub (Link …), Portfolio (Link …), Fotoblog (Link …). Verwende Platzhalterbilder `https://picsum.photos/600/400?random=1..3`, ergänze `aria-label` je Link.“*



## III. Deployment: Veröffentlichen der Seite

Für das Deployment stehen zwei mögliche Varianten zur Auswahl – du kannst selbst entscheiden:

### Option A: GitHub Pages
1. Lade dein Projekt in ein GitHub-Repository hoch.  
2. Gehe in deinem Repository auf **Settings → Pages**.  
3. Wähle den Branch `main` (oder `gh-pages`) und speichere die Einstellungen.  
4. Nach wenigen Minuten ist deine Seite wie https://yuzzfeng.github.io/Geoinformatik2_HS_Mainz/Uebung1/ erreichbar.  

### Option B: GitHub-Repository mit Netlify verbinden
1. Erstelle ein Konto bei [Netlify](https://www.netlify.com) (Login mit GitHub möglich).  
2. Klicke auf **Add new site → Import an existing project**.  
3. Wähle dein GitHub-Repository aus und bestätige.  
4. Netlify baut deine Seite automatisch und stellt sie unter einer Adresse wie https://subtle-tulumba-d7b8e7.netlify.app/

---

### Erwartete Webseite

<p align="center">
  <img src="assets/Uebung1_output.png" alt="Übung 1 Output" width="100%">
</p>