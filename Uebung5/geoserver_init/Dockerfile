FROM curlimages/curl:8.10.1

# 将初始化脚本复制到镜像内
COPY init_geoserver.sh /app/init_geoserver.sh

# 设置可执行权限
USER root
RUN chmod +x /app/init_geoserver.sh

# 切回 curl 用户
USER curl_user

ENTRYPOINT ["/bin/sh", "/app/init_geoserver.sh"]
