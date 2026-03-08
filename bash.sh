#!/bin/bash
# OpenClaw Gateway - 일반 사용자로 bash 접속

cd "$(dirname "$0")" && docker compose exec openclaw-gateway bash
