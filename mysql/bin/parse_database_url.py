#!/usr/bin/env python3
"""Dump out a DATABASE_URL provided in the environment as individual variables"""
import os
import sys
from urllib.parse import urlparse

parsed = urlparse(os.environ["DATABASE_URL"])
env = {
    'USER': parsed.username,
    'MYSQL_PWD': parsed.password,
    'HOST': parsed.hostname,
    'PORT': parsed.port,
    'NAME': parsed.path.strip('/')
}
for k, v in env.items():
    print(f"{k}={v}")
