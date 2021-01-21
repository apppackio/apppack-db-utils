FROM python:3.8-alpine3.11

ENV AWS_CONFIG_FILE=/.aws_config
RUN set -ex && \
    apk add --no-cache postgresql-client bash && \
    pip install --no-cache-dir awscli boto3 && \
    aws configure set default.s3.multipart_chunksize 200MB
COPY ./bin/ /bin/
ENTRYPOINT ["/bin/entrypoint.sh"]
