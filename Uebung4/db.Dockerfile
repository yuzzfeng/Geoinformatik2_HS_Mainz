# Uebung4/db.Dockerfile
FROM postgis/postgis:16-3.4

# 以 root 准备目录与权限
USER root
RUN mkdir -p /docker-entrypoint-initdb.d \
 && chown -R postgres:postgres /docker-entrypoint-initdb.d \
 && chmod 755 /docker-entrypoint-initdb.d

# 把脚本拷进去，并把归属直接设为 postgres
COPY --chown=postgres:postgres initdb/*.sql /docker-entrypoint-initdb.d/
COPY --chown=postgres:postgres initdb/*.sh  /docker-entrypoint-initdb.d/

# 设定合理的权限（.sh 可执行，.sql 可读）
RUN set -eux; \
    chmod 755 /docker-entrypoint-initdb.d/*.sh 2>/dev/null || true; \
    chmod 644 /docker-entrypoint-initdb.d/*.sql 2>/dev/null || true

# 切回 postgres（官方 entrypoint 期望的运行用户）
USER postgres
