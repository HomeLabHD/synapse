# Configuration

Synapse is configured entirely by YAML — there are no environment variables for its
settings. It reads every file it is given with `--config-path`, and a path may be a
directory, which is how credentials stay out of a ConfigMap while the rest of the
configuration stays readable.

## Database

PostgreSQL, and it must be created with **`UTF8` encoding and `C` collation**:

```sql
CREATE DATABASE synapse
  ENCODING 'UTF8'
  LC_COLLATE 'C'
  LC_CTYPE 'C'
  TEMPLATE template0;
```

Synapse verifies this at startup and refuses to run otherwise. Getting it wrong is not
something you fix in place — the remedy is a dump and restore into a correctly-created
database, so it is worth checking before there is data to move.

## Identity and delegation

`server_name` is the identity half of every user ID and is written into every room and
event the server takes part in. It is **permanent** once the server has federated: remote
servers key identities to it, and changing it strands every existing connection.

It does not have to be where the software answers. Publish `/.well-known/matrix/server` on
the domain you want in your user IDs, pointing at the host actually running Synapse:

```json
{ "m.server": "matrix.example.com:443" }
```

Clients discover the rest from `/.well-known/matrix/client`, which also carries the
authentication issuer and any RTC endpoints. Serve **CORS headers** on both — without
them browser clients silently fail discovery.

## Authentication

Delegated authentication (MSC3861) hands login, sessions and account management to a
[Matrix Authentication Service](https://element-hq.github.io/matrix-authentication-service/)
instance. Element X requires it; the legacy password and SSO paths will not do.

With delegation on, disable everything that would be a second way in:

```yaml
enable_registration: false
password_config:
  enabled: false
```

## Media storage

The bundled `synapse-s3-storage-provider` keeps the media repository in S3-compatible
object storage instead of growing a volume without limit:

```yaml
media_storage_providers:
  - module: s3_storage_provider.S3StorageProviderBackend
    store_local: true
    store_remote: true
    store_synchronous: true
    config:
      bucket: your-bucket
      endpoint_url: http://your-object-store
      access_key_id: ...
      secret_access_key: ...
```

Synapse performs **no environment substitution** on its YAML, so credentials have to be
written into a config file — render it from a secret store rather than committing it.

Media already on disk is migrated with the `s3_media_upload` CLI the module provides;
adding the provider does not move anything by itself.

## Moderation

`synapse-http-antispam` is bundled and inert until configured. It forwards spam checks to
an HTTP service — [Draupnir](https://the-draupnir-project.github.io/draupnir-documentation/bot/synapse-http-antispam)
uses it to reject events *before* the server accepts them, rather than redacting after the
fact. It needs Draupnir v2.3.0 or later.

## Writable paths

The image runs as uid **991** with no writable root filesystem. Mount:

| Path | |
|------|-|
| data directory | Holds the **signing key** — this server's identity to the federation. A replacement is rejected by every remote server that knew the old one, so this is the volume to back up |
| media store | Unless media is in object storage |
| `/tmp` | Scratch |

## Behind a proxy

Synapse serves the client and federation APIs on **8008**. Terminate TLS in front and set
`x_forwarded: true` on the listener, or every client will appear to come from the proxy —
which breaks rate limiting and makes abuse reports useless.

Federation traffic is not browser traffic. A CDN that caps request bodies or challenges
non-browser clients will break media uploads and server-to-server delivery in ways that
look like intermittent federation failures.
