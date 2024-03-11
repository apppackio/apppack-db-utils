FROM --platform=linux/amd64 python:3.12-alpine3.19

ENV AWS_CONFIG_FILE=/.aws_config
RUN set -ex && \
    apk add --no-cache mysql-client bash && \
    pip install --no-cache-dir awscli && \
    aws configure set default.s3.multipart_chunksize 200MB
COPY ./bin/ /bin/
ENTRYPOINT ["/bin/entrypoint.sh"]
