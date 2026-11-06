FROM debian:bookworm-slim AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ca-certificates libsqlite3-dev zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch 2.62.5 https://github.com/felt/tippecanoe.git /src \
 && make -C /src -j4 && make -C /src install PREFIX=/usr/local

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends libsqlite3-0 zlib1g \
 && rm -rf /var/lib/apt/lists/*
COPY --from=build /usr/local/bin/tippecanoe /usr/local/bin/tile-join /usr/local/bin/
WORKDIR /work
