Geoinformatik 2 · Web-GIS 
# Übung 2 · Modernes Frontend - Stil & Interaktivität mit Copilot
Prof. Dr. Yu Feng

## Ziel dieser Übung
Nach dieser Übung können Sie:
- Umgang mit CSS/JavaScript zur Gestaltung und Erweiterung von Webseiten
- Umsetzung von Themes, Layouts und Interaktivität
- Nutzung von Copilot zur Effizienzsteigerung und Ideengenerierung

## Was soll die Seite noch können?

### Aufgabe 1 - Thematische Anpassungen
In dieser Aufgabe soll die Webseite optisch modernisiert werden. 

- Dazu gehören ein **Light/Night Mode**, der durch einen einfachen Klick auf einen Button gewechselt werden kann, sowie animierte Tabs und ein responsives Layout mit moderner Karten- und Tab-Gestaltung.

- **CSS verstehen**: Identifizieren Sie selbstständig die geänderten CSS-Regeln und versuchen Sie zu verstehen, wie diese die Gestaltung umsetzen.

---

### Aufgabe 2 – Seitenstruktur mit Tabs  

Alle Informationen sind derzeit noch vermischt dargestellt. Um die Inhalte klarer zu strukturieren, soll die Seite in drei Bereiche gegliedert werden:  

- **About**: Persönliche Vorstellung sowie ein Foto.  
- **News**: Informationen über aktuelle Ereignisse.  
- **Projects**: Präsentation eigener Web-Maps oder Webseiten.  

Die Tabs können entweder zu den jeweiligen Abschnitten einer langen Seite führen oder nur den ausgewählten Bereich anzeigen.

---

### Aufgabe 3 – Dynamische News  

Wir möchten die neuesten Nachrichten mit den Leserinnen und Lesern teilen, doch die ständige manuelle Anpassung des HTML ist zu aufwendig. Stattdessen sollen die Inhalte dynamisch aus der Datei `assets/news.json` geladen werden:  

- **Automatisches Einlesen**: Die Daten werden mit JavaScript aus der JSON-Datei übernommen.  
- **Strukturierte Darstellung**: Jede News erscheint mit Bild, Titel, Datum und Kurztext.  
- **Einfache Erweiterung**: Neue Meldungen können direkt in der JSON-Datei ergänzt werden.  
- Ersetzen Sie die News aus der Vorlage durch zwei bis drei eigene neue Meldungen in `assets/news.json`.

So bleibt die Webseite aktuell, ohne dass das HTML bei jeder Änderung bearbeitet werden muss.  

---

### Aufgabe 4 – Kontakt und externe Links

Um die Seite professioneller und benutzerfreundlicher zu gestalten, soll ein kleiner Kontaktbereich integriert werden. Platziere dazu zwei bis drei Logos (z. B. LinkedIn, GitHub oder E-Mail), die auf externe Webseiten verlinken.

- Die Logos müssen mit `position: fixed` unten rechts im Browserfenster fixiert sein und auch beim Scrollen dort bleiben.

---

### Aufgabe 5 – Veröffentlichung (Zugriff für die/den Dozent*in sicherstellen)

Passen Sie vor der Veröffentlichung Layout und Farben nach Ihrem Geschmack an.

Stelle sicher, dass deine Seite **öffentlich erreichbar** ist, damit die/der Dozent*in sie prüfen kann. Empfohlene Wege:  
- **GitHub Pages** aktivieren (Settings → Pages) und die bereitgestellte URL in das README eintragen.  
- Oder **Netlify** benutzen (Repo verbinden oder per Drag & Drop deployen) und die Live-URL im README dokumentieren.  
- Teste den Link in einem privaten/Inkognito-Fenster, um sicherzugehen, dass alles öffentlich zugänglich ist.

---

### Aufgabe 6 – Reflexion <span style="color:red">(**Sehr wichtig – bitte beantworten!**)</span>

Zum Abschluss reflektieren Sie den Aufbau deines Codes anhand einiger Fragen.  

- **Light/Night Mode**: In welchem Teil des Codes wird der Theme-Wechsel umgesetzt?  
- **Klick-Ereignisse**: Wie wird das Klick-Ereignis mit JavaScript verarbeitet?  
- **Tabs**: Durch welches Element werden die Inhalte der Tabs dargestellt?  
- **News**: Wie wird das Einlesen der externen News-Datei realisiert?  

---

## Live-URL
Bitte hier die öffentlich erreichbare URL eintragen (GitHub Pages oder Netlify):  
OLAT -> Geoinformatik 2 -> Übungsabgabe -> Uebung 1-3 - Link

---

## Beispiel-Output

- https://yuzzfeng.github.io/Geoinformatik2_HS_Mainz/Uebung2/ 

<p align="center">
  <img src="assets/Uebung2_output.png" alt="Übung 1 Output" width="100%">
</p>
