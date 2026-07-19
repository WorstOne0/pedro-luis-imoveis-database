// Runs once, on the very first start of an empty data volume.
//
// The root user created by MONGO_INITDB_ROOT_* can do anything on every
// database. The application should not use it, so this creates a second user
// scoped to the application database only. If the app credentials ever leak,
// the blast radius is one database rather than the whole server.

const database = process.env.MONGO_INITDB_DATABASE;
const user = process.env.MONGO_APP_USER;
const password = process.env.MONGO_APP_PASSWORD;

if (!user || !password) {
  print("MONGO_APP_USER / MONGO_APP_PASSWORD not set - skipping application user creation");
} else {
  db = db.getSiblingDB(database);

  db.createUser({
    user: user,
    pwd: password,
    roles: [{ role: "readWrite", db: database }],
  });

  print(`Created application user "${user}" with readWrite on "${database}"`);
}
