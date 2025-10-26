FROM curlimages/curl:8.10.1

# 将初始化脚本复制到镜像内，并在构建时设置可执行位（避免切换用户）
COPY --chmod=0755 init_geoserver.sh /app/init_geoserver.sh

# 规范化脚本行尾（CRLF->LF），避免 /bin/sh 解析错误（需要临时切到 root 写入）
USER 0
RUN sed -i 's/\r//g' /app/init_geoserver.sh || true
USER curl_user

# 切回 curl 用户（镜像原本使用的非特权用户）
USER curl_user

ENTRYPOINT ["/bin/sh", "/app/init_geoserver.sh"]
