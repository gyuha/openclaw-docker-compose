#!/bin/bash
# OpenClaw Gateway - 관리자(root)로 bash 접속

cd "$(dirname "$0")" && docker compose exec -u root openclaw-gateway bash
