# syntax=docker/dockerfile:1.5
# 使用小型 GDAL Alpine 基础镜像，并安装 GDAL 和依赖
FROM ghcr.io/osgeo/gdal:alpine-small-latest

# 将导入脚本复制到镜像内，并设置可执行权限
# 复制脚本并设为可执行；顺便将可能的 CRLF 转为 LF，避免 /bin/sh 解析错误
COPY --chmod=0755 import_geojson.sh /app/import_geojson.sh
RUN sed -i 's/\r$//' /app/import_geojson.sh || true

ENTRYPOINT ["/bin/sh", "/app/import_geojson.sh"]
