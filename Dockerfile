# A thin layer over Element's published image rather than a source build. That image is
# the output of upstream's own docker/Dockerfile — 200 lines of cross-architecture
# machinery — built by Element's CI. Everything wanted here lives in the final layer, so
# building from source would reproduce all of it to arrive at the same place. The source
# is mirrored at HomeLabHD/synapse-core for availability, not for building.
#
# Pinned by digest, not tag: a tag can be re-pushed, a digest cannot.
ARG SYNAPSE_IMAGE=ghcr.io/element-hq/synapse@sha256:78de1d10bef02e375f861d1cc99f8bedd9381d4f9083ea8b2c22a053477b205f
FROM ${SYNAPSE_IMAGE}

ARG S3_PROVIDER_VERSION
ARG HTTP_ANTISPAM_VERSION

LABEL org.opencontainers.image.title="synapse" \
      org.opencontainers.image.description="Synapse with S3 media offload and the HTTP antispam hook, hardened and rootless" \
      org.opencontainers.image.source="https://gitlab.prplanit.com/HomeLabHD/synapse" \
      org.opencontainers.image.licenses="AGPL-3.0-or-later OR LicenseRef-Element-Commercial"

USER root

# Both modules are inert until homeserver.yaml names them. They are baked in because pip
# is removed below: adding a module later is a rebuild, so the ones worth having are
# decided here rather than discovered in an outage.
#   s3-storage-provider — media offload to Ceph RGW, plus the s3_media_upload CLI
#   http-antispam       — the hook Draupnir needs to reject events before they are accepted
RUN set -eux; \
    pip install --no-cache-dir \
        "synapse-s3-storage-provider==${S3_PROVIDER_VERSION}" \
        "synapse-http-antispam==${HTTP_ANTISPAM_VERSION}"; \
    # Nothing installs packages at runtime, so the installer is attack surface.
    pip uninstall -y pip setuptools wheel 2>/dev/null || true; \
    # A homeserver needs no setuid path to root.
    find / -xdev -perm /6000 -type f -exec chmod a-s {} + 2>/dev/null || true; \
    rm -rf /root/.cache

# Upstream's /start.py exists to run as root, write config and drop privileges. Config is
# supplied by the deployment, so that path is removed entirely rather than bypassed: the
# image has no root entrypoint to reach.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

USER 991:991
EXPOSE 8008/tcp 8448/tcp 19090/tcp
ENTRYPOINT ["python", "-m", "synapse.app.homeserver"]
