# 3.14-alpine
FROM python:3.14-alpine@sha256:faee120f7885a06fcc9677922331391fa690d911c020abb9e8025ff3d908e510
WORKDIR /app

# Install uv
# 0.11.2
COPY --from=ghcr.io/astral-sh/uv@sha256:5164bf84e7b4e2e08ce0b4c66b4a8c996a286e6959f72ac5c6e0a3c80e8cb04a /uv /uvx /bin/

# Use the project's lock file for paho-mqtt version consistency
COPY pyproject.toml uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install --system --no-cache paho-mqtt

# Install docker-cli to control sibling containers
RUN apk add --no-cache docker-cli

COPY tests/standalone/verifier/verifier.py .
CMD ["python", "-u", "verifier.py"]
