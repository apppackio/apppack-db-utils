FROM debian:bookworm-slim

ENV AWS_CONFIG_FILE=/.aws_config
ENV PATH="/opt/postgresql/bin:/opt/awscli/bin:$PATH"

# Add the PostgreSQL Apt repository
RUN apt-get update && apt-get install -y wget gnupg && \
    echo "deb http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Install PostgreSQL client tools for versions 11–17 and other dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        postgresql-client-11 \
        postgresql-client-12 \
        postgresql-client-13 \
        postgresql-client-14 \
        postgresql-client-15 \
        postgresql-client-16 \
        postgresql-client-17 \
        python3-pip && \
    mkdir -p /opt/postgresql && \
    for version in 11 12 13 14 15 16 17; do \
        ln -s /usr/lib/postgresql/$version/bin/pg_dump /usr/bin/pg_dump-$version && \
        ln -s /usr/lib/postgresql/$version/bin/pg_restore /usr/bin/pg_restore-$version; \
    done && \
    # Install AWS CLI globally
    rm -f /usr/lib/python3.11/EXTERNALLY-MANAGED && \
    pip3 install --no-cache-dir awscli && \
    ln -s /usr/local/bin/aws /usr/bin/aws && \
    aws configure set default.s3.multipart_chunksize 200MB && \
    # Cleanup cache
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY ./bin/ /bin/
ENTRYPOINT ["/bin/entrypoint.sh"]
