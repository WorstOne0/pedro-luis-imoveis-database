# pedro_luis_imoveis_database

MongoDB for Pedro Luis Imóveis, as a container. No application code — compose
file, first-run init script, and backup/restore scripts.

## Working agreements

**Do not commit unless I ask.** Leave changes in the working tree for review.

- Never print or commit `.env`. Update `.env.example` when adding a variable.
- Treat anything touching `mongo_data` as destructive and confirm first.

## How it fits together

- Data lives in the named volume `mongo_data`, not a bind mount, so it survives
  `docker compose down` and image upgrades. Removing that volume destroys the
  database.
- **Port 27017 is deliberately not published.** Only containers on the
  `pedro-net` network can reach it; the backend connects to the host `mongodb`.
  Adding `ports:` would expose the database to the internet.
- Two accounts: a root user for administration and backups, and a least
  privilege app user with `readWrite` on the application database only. The
  backend uses the app user.
- `init/01_create_app_user.js` runs **only against an empty volume**, i.e. the
  very first start. Editing it later has no effect — create users by hand, or
  wipe the volume if there is nothing to lose.

## Scripts

```
./scripts/backup.sh                 # -> backups/<timestamp>.archive.gz, prunes >14d
./scripts/restore.sh <archive.gz>   # destructive, prompts first
./scripts/migrate_from.sh <uri>     # copy in from local Mongo or Atlas
```

## Sizing

Roughly 2.6 KB per listing, so the database stays in the megabytes even at tens
of thousands of listings. Disk usage is dominated entirely by uploaded photos in
the `_images` volume, not by Mongo.

## Environment

`MONGO_ROOT_USER` `MONGO_ROOT_PASSWORD` `MONGO_DATABASE` `MONGO_APP_USER`
`MONGO_APP_PASSWORD` and the optional `MONGO_EXPRESS_*` set.
