FROM curlimages/curl:8.10.1

# Kopiere das Initialisierungs-Skript in das Image
COPY init_geoserver.sh /app/init_geoserver.sh

# Setze ausführbare Rechte
USER root
RUN apk add --no-cache postgresql-client
RUN chmod +x /app/init_geoserver.sh

# Wechsel zurück zum curl-Benutzer
USER curl_user

ENTRYPOINT ["/bin/sh", "/app/init_geoserver.sh"]
