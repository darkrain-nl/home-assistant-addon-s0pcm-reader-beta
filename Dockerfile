# Default to scratch to suppress 'InvalidDefaultArgInFrom' warnings.
# The true base image is always injected by builder using build.yaml.
ARG BUILD_FROM="scratch"
FROM ${BUILD_FROM}

WORKDIR /
COPY pyproject.toml uv.lock /tmp/uv/
COPY rootfs /

# 0.11.2
COPY --from=ghcr.io/astral-sh/uv@sha256:90bbb3c16635e9627f49eec6539f956d70746c409209041800a0280b93152823 /uv /uvx /bin/

RUN --mount=type=cache,target=/root/.cache/uv \
    cd /tmp/uv && uv export --frozen --no-dev --no-emit-project --no-hashes | \
    uv pip install --link-mode=copy --system -r - && \
    cd / && rm -rf /tmp/uv && \
    chmod a+x /etc/services.d/s0pcm-reader/*

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python3 /usr/src/healthcheck.py || exit 1
