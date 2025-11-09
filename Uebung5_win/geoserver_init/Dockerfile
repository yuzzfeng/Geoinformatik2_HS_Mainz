FROM curlimages/curl:8.10.1

# Kopiere das Initialisierungs-Skript in das Image
COPY init_geoserver.sh /app/init_geoserver.sh

# Setze ausführbare Rechte und normalisiere CRLF für Windows-Kompatibilität
USER root
RUN chmod +x /app/init_geoserver.sh && sed -i 's/\r$//' /app/init_geoserver.sh

# Wechsel zurück zum curl-Benutzer
USER curl_user

ENTRYPOINT ["/bin/sh", "/app/init_geoserver.sh"]
