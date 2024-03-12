FROM --platform=linux/amd64 python:3.12-alpine3.19

ENV AWS_CONFIG_FILE=/.aws_config
RUN set -ex && \
    apk add --no-cache \
        postgresql16-client \
        postgresql15-client \
        postgresql14-client \
        postgresql13-client \
        bash && \
    pg_versions set-default 16 && \
    pip install --no-cache-dir awscli && \
    aws configure set default.s3.multipart_chunksize 200MB
COPY ./bin/ /bin/
ENTRYPOINT ["/bin/entrypoint.sh"]
