FROM curlimages/curl:8.10.1

# Kopiere das Initialisierungs-Skript und setze ausführbare Rechte beim Build (vermeidet User-Wechsel)
COPY --chmod=0755 init_geoserver.sh /app/init_geoserver.sh

# Normalisiere Zeilenenden (CRLF->LF), um /bin/sh Parsing-Fehler zu vermeiden (benötigt temporär root)
USER 0
RUN sed -i 's/\r//g' /app/init_geoserver.sh || true
USER curl_user

# Wechsel zurück zum curl-Benutzer (ursprünglicher unprivilegierter User des Images)
USER curl_user

ENTRYPOINT ["/bin/sh", "/app/init_geoserver.sh"]
