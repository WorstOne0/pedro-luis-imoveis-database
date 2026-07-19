# Pedro Luis Imóveis — Database

> MongoDB container plus backup, restore and migration scripts.

One of five repositories that make up the product:

| Repository | Role |
|---|---|
| frontend | Public site — map + listings |
| dashboard | Admin panel — listing CRUD, uploads, auth |
| backend | REST API |
| images | Upload, resize and serve photos/video |
| **database** (this one) | MongoDB container + backup scripts |

---

## Getting started

```bash
cp .env.example .env     # then fill it in
docker compose up -d
```

The backend connects over the shared `pedro-net` Docker network.

---

## Structure

```
docker-compose.yml
init/01_create_app_user.js     runs once, on an empty volume
scripts/backup.sh              mongodump into a timestamped archive
scripts/restore.sh             mongorestore from an archive
scripts/migrate_from.sh        one-shot import from an existing database
```

---

## Design decisions

**No published port.** There is deliberately no `ports:` entry on the mongodb
service. Publishing 27017 would expose the database to the whole internet on a
VPS, which is the most common way self-hosted MongoDB gets ransomwared. Only
containers on `pedro-net` can reach it. For local access use
`docker compose exec mongodb mongosh`, or add a temporary `127.0.0.1:27017:27017`
binding.

**Named volumes, not bind mounts.** `mongo_data` and `mongo_config` survive
`docker compose down`, image upgrades and container rebuilds.

**Two users.** The root user exists only to create the second. The init script
creates a least-privilege user scoped to the app database, and that is the one in
the backend's connection string.

**The init script runs only on an empty volume** — i.e. the very first start.
Editing it later has no effect unless you drop the volume. The same applies to
the credentials: if you lose `.env` after initialisation, the credentials baked
into the volume still apply.

**Healthcheck with a 30s start period**, so dependent services can wait on it
rather than racing the first connection.

---

## Sizing

- Listing documents are tiny — roughly **2.6KB each**. Even 100,000 listings is
  a few hundred megabytes. The database is not what fills a disk.
- **Images dominate.** At roughly 536KB per processed photo × 20 photos ≈ **11MB
  per listing**, a 157GB disk holds on the order of **10,000 listings**.
- Revisit only when storing video at scale — the images service accepts up to
  300MB per video file, which changes the maths quickly.

---

## Backups

`scripts/backup.sh` produces a timestamped archive and prunes old ones. Nothing
here schedules it — put it on a cron on the host, because scheduling belongs to
the host rather than the container.

---

## Known limitations

- Backups are local. Copying them off-box is not automated.
- No replica set; this is a single-node deployment.

---

## Project status and contributions

This is a commissioned project built for a specific business. It is **not** an
open source project and is not accepting contributions, feature requests or
pull requests.

## Copyright and licence

**Copyright © 2026 Lucca Gabriel. All rights reserved.**

This repository is published so the source can be **read**, as a portfolio piece
and for reference. It is deliberately published **without a licence**, which
under default copyright law means all rights are reserved.

Viewing and forking within GitHub are permitted by GitHub's Terms of Service.
That does **not** grant permission to use, copy, modify, deploy or redistribute
this code. Third-party dependencies keep their own licences, and Pedro Luis
Imóveis brand assets are the property of their owner.

See [`COPYRIGHT.md`](COPYRIGHT.md) for the full terms.
