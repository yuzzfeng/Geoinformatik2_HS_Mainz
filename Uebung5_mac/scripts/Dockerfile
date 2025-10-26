FROM ghcr.io/osgeo/gdal:ubuntu-small-latest

# 将导入脚本复制到镜像内
COPY import_geojson.sh /app/import_geojson.sh

# 设置可执行权限
RUN chmod +x /app/import_geojson.sh

ENTRYPOINT ["/bin/sh", "/app/import_geojson.sh"]
