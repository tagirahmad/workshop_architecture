#!/bin/bash
set -e

rm -rf /var/lib/postgresql/data/*
pg_basebackup --host=master --username=repluser --pgdata=/var/lib/postgresql/data --wal-method=stream --write-recovery-conf
