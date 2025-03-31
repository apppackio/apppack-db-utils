# How To Update For New Postgresql Versions:

1. Install the new PostgreSQL client tools:
   Add the new version of `postgresql-client` to the Dockerfile, e.g., `postgresql-client-18`.
   Update the newer version in the for loop:
      `for version in 11 12 13 14 15 16 17; do \` to `for version in 11 12 13 14 15 16 17 18; do \`
2. Test the script:
   Verify that the new version works by setting `SERVER_VERSION` to the new version (e.g., `18`)
   and running the script against a PostgreSQL 18 server.
3. Ensure fallback compatibility:
   Test the script with no `SERVER_VERSION` set to confirm it falls back to the latest version.
4. Update `load-from-s3.sh` & `dump-to-s3.sh` script's `SERVER_VERSION` default value if the new version becomes the default:
   Change `SERVER_VERSION=${SERVER_VERSION:-17}` to `SERVER_VERSION=${SERVER_VERSION:-18}`.
