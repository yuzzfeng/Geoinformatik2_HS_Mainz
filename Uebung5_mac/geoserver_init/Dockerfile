FROM curlimages/curl:8.10.1

COPY init_geoserver.sh /app/init_geoserver.sh
COPY verify_mainz.py /app/verify_mainz.py

USER root
RUN apk add --no-cache python3 postgresql-client
# Normalize Windows line endings for both host platforms.
RUN chmod +x /app/init_geoserver.sh && sed -i 's/\r$//' /app/init_geoserver.sh
USER curl_user

ENTRYPOINT ["/bin/sh", "/app/init_geoserver.sh"]
