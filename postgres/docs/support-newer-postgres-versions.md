# How to Update for New PostgreSQL Versions

Follow these steps to add support for a new PostgreSQL version (e.g., version 18):

## 1. Install the New Client Tools

In the `Dockerfile`:

- Add the new version of `postgresql-client`, e.g., `postgresql-client-18`
- Update the `for` loop that creates version-specific symlinks:

```dockerfile
for version in 11 12 13 14 15 16 17 18; do \
  ln -s /usr/lib/postgresql/$version/bin/pg_dump /usr/bin/pg_dump-$version && \
  ln -s /usr/lib/postgresql/$version/bin/pg_restore /usr/bin/pg_restore-$version; \
done
```

These changes ensure the tooling for the new version is available.

## 2. Update the Default Version (If Applicable)

If the new version should become the default:

- Update both `dump-to-s3.sh` and `load-from-s3.sh`

This ensures the scripts default to the latest version when `SERVER_VERSION` is not set or detection fails.

---

✅ Fallback behavior and override logic are already tested automatically in `tests.sh`, including:

- Ensuring correct `pg_dump-*` is used when `SERVER_VERSION` is set
- Falling back to the detected or default version when unset

Re-run `tests.sh` after changes to confirm compatibility across versions.
