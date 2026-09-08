# synapse

A **rootless, hardened** container image for [Synapse](https://element-hq.github.io/synapse/) — the reference [Matrix](https://matrix.org/) homeserver — carrying media offload to S3-compatible object storage and the antispam hook moderation tooling needs. A thin, digest-pinned layer over Element's published image: it adds what a self-hosted deployment actually needs, drops the package installer and every setuid binary, and runs as a non-root user with no root code path at all.

<!-- sf:project:start -->
[![GitHub](https://img.shields.io/badge/GitHub-mirror-181717?logo=github)](https://github.com/HomeLabHD/synapse) [![GitLab](https://img.shields.io/badge/GitLab-source-FC6D26?logo=gitlab)](https://gitlab.prplanit.com/HomeLabHD/synapse) [![license](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/license.svg)](https://github.com/HomeLabHD/synapse/blob/main/LICENSE) [![Open Issues](https://img.shields.io/github/issues/HomeLabHD/synapse)](https://github.com/HomeLabHD/synapse/issues) [![Open PRs](https://img.shields.io/github/issues-pr/HomeLabHD/synapse)](https://github.com/HomeLabHD/synapse/pulls) [![Contributors](https://img.shields.io/github/contributors/HomeLabHD/synapse)](https://github.com/HomeLabHD/synapse/graphs/contributors) [![donate](https://img.shields.io/badge/donate-FF5E5B?logo=ko-fi&logoColor=white)](https://ko-fi.com/T6T41IT163) [![sponsor](https://img.shields.io/badge/sponsor-EA4AAA?logo=githubsponsors&logoColor=white)](https://github.com/sponsors/HomeLabHD)
<!-- sf:project:end -->
<!-- sf:badges:start -->
[![release](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/release.svg)](https://github.com/HomeLabHD/synapse/releases) [![build](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/build.svg)](https://gitlab.prplanit.com/HomeLabHD/synapse/-/pipelines) [![Last Commit](https://img.shields.io/github/last-commit/HomeLabHD/synapse)](https://github.com/HomeLabHD/synapse/commits) [![StageFreight](https://img.shields.io/badge/StageFreight-0.11.0--dev+f09482f-310937?logo=readthedocs&logoColor=white)](https://stagefreight.prplanit.com)
<!-- sf:badges:end -->
<!-- sf:image:start -->
[![GHCR](https://img.shields.io/badge/GHCR-homelabhd%2Fsynapse-181717?logo=github&logoColor=white)](https://github.com/HomeLabHD/synapse/pkgs/container/synapse) [![Docker](https://img.shields.io/badge/Docker-hlhd%2Fsynapse-2496ED?logo=docker&logoColor=white)](https://hub.docker.com/r/hlhd/synapse) [![pulls](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/pulls.svg)](https://hub.docker.com/r/hlhd/synapse) [![Harbor](https://img.shields.io/badge/Harbor-hlhd%2Fsynapse-60b932)](https://cr.pcfae.com/harbor/projects)

[![latest](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/release-latest.svg)](https://github.com/HomeLabHD/synapse/pkgs/container/synapse) ![updated](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/release-updated.svg) [![size](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/release-size.svg)](https://github.com/HomeLabHD/synapse/pkgs/container/synapse) [![latest-dev](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/dev-latest.svg)](https://github.com/HomeLabHD/synapse/pkgs/container/synapse) ![updated](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/dev-updated.svg) [![size](https://raw.githubusercontent.com/HomeLabHD/synapse/main/.stagefreight/scribe/dev-size.svg)](https://github.com/HomeLabHD/synapse/pkgs/container/synapse)
<!-- sf:image:end -->

### Documentation

| Topic | |
|-------|-|
| [Configuration](docs/Configuration.md) | Database requirements, delegation, media storage, the bundled modules and what they need |

### What Matrix is

|                            |                                                                                                     |
| -------------------------- | ----------------------------------------------------------------------------------------------------- |
| **Federated, not hosted**  | Servers exchange messages directly, so a conversation spans hubs the way email spans providers — no single operator sits in the middle of it |
| **Your name, your server** | Identities are `@you:example.com`. The domain is the identity, which is why it is delegated from the apex and never changes afterwards |
| **Encrypted by default**   | End-to-end encryption with cross-signed device verification, so a compromised server still cannot read rooms |
| **Bridges to everything else** | Application services relay WhatsApp, Signal, Discord, IRC and Slack into ordinary rooms — the one path that replaces a proprietary chat network without asking anyone to switch apps |
| **Rooms, spaces, threads** | Spaces group rooms, threads keep replies out of the main timeline, and both federate |
| **Calls**                  | Voice and video via MatrixRTC, which runs beside the homeserver rather than through it |

### What this image adds

|                          |                                                                                                    |
| ------------------------ | ---------------------------------------------------------------------------------------------------- |
| **S3 media offload**     | `synapse-s3-storage-provider` — keep the media repository in object storage instead of growing a volume without bound. Brings the `s3_media_upload` CLI for migrating media already on disk |
| **Moderation hook**      | `synapse-http-antispam` — inert until configured, it is what [Draupnir](https://the-draupnir-project.github.io/draupnir-documentation/) uses to reject events *before* the server accepts them, rather than cleaning up afterwards |
| **No root code path**    | Upstream's image has no `USER` and its entrypoint runs as root to write config and drop privileges. Config comes from the deployment here, so that entrypoint is replaced outright rather than bypassed |
| **No installer**         | `pip`, `setuptools` and `wheel` are removed after the modules are in. Nothing installs packages at runtime, so the installer is only attack surface |
| **No setuid binaries**   | Every setuid and setgid bit in the image is stripped. A homeserver needs no path to root |
| **Read-only-rootfs ready** | Bytecode writing is off and everything Synapse writes is a mount, so `readOnlyRootFilesystem: true` holds |
| **Pinned by digest**     | The base is addressed by digest, not tag — a tag can be re-pushed, a digest cannot |

## Image contents

<details>
<summary>Base image &amp; modules (click to expand)</summary>

Base Image:
<!-- sf:contents-base:start -->
[![synapse@sha256 78de1d10bef02e375f861d1cc99f8bedd9381d4f9083ea8b2c22a053477b205f](https://img.shields.io/badge/synapse@sha256-78de1d10bef02e375f861d1cc99f8bedd9381d4f9083ea8b2c22a053477b205f-0078D4?style=flat)](https://github.com/element-hq/synapse/pkgs/container/synapse)
<!-- sf:contents-base:end -->

Pinned components — see [`components.json`](components.json):

| Component | Source | Version |
|-----------|--------|---------|
| base | [element-hq/synapse](https://github.com/element-hq/synapse) (digest-pinned) | `v1.160.0` |
| media provider | [synapse-s3-storage-provider](https://github.com/matrix-org/synapse-s3-storage-provider) | `1.7.0` |
| antispam hook | [synapse-http-antispam](https://github.com/maunium/synapse-http-antispam) | `0.5.1` |

</details>

---

## Installation

```bash
docker pull ghcr.io/homelabhd/synapse:latest
# or
docker pull docker.io/hlhd/synapse:latest
```

Synapse needs a PostgreSQL database **created with `UTF8` encoding and `C` collation** — it verifies this at startup, and the only remedy afterwards is a dump and restore. It serves the client and federation APIs on **8008**; put TLS in front of it and set `x_forwarded: true` so the client address survives the hop.

The container runs as uid **991** with no writable root filesystem, so mount the paths Synapse writes: its data directory (which holds the **signing key** — this server's federation identity, and unrecoverable if lost), the media store unless it is in object storage, and `/tmp`.

Both bundled modules are inert until `homeserver.yaml` names them; see the [module documentation](https://element-hq.github.io/synapse/latest/modules/index.html).

## Contributing

- Fork the repository
- Submit Pull Requests / Merge Requests
- [File issues](../../issues/new) with image tag, run/compose command, and environment details

## Credits

* Powered by [Synapse](https://github.com/element-hq/synapse), maintained by Element
* Upstream source is mirrored at [HomeLabHD/synapse-core](https://gitlab.prplanit.com/HomeLabHD/synapse-core) — kept for source availability, not built from

## Disclaimer

> The Software provided hereunder ("Software") is licensed "as-is," without warranties of any kind — express, implied, or federated to you by a homeserver you have never heard of. The developer makes no promises about functionality, performance, compatibility, security, or availability. Not liable if your state groups grow larger than your storage budget, if a room join drags in a decade of someone else's history, or if removing `pip` gives you such a smug sense of minimalism that you forget where the signing key is backed up.

> Any positive experiences are owed entirely to the folks at Element and the unstoppable force that is the Open Source community. The developer claims no credit for anything that actually goes right.

## License

Synapse is distributed under [AGPL-3.0-or-later, or a commercial licence from Element](https://github.com/element-hq/synapse/blob/develop/LICENSE-AGPL-3.0). This packaging is maintained by HomeLabHD; the unmodified upstream source is mirrored at [synapse-core](https://gitlab.prplanit.com/HomeLabHD/synapse-core).
