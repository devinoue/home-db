#!/usr/bin/env bash
# 初期セットアップ兼起動スクリプト（何度実行しても安全）
set -euo pipefail
cd "$(dirname "$0")"

command -v docker >/dev/null || { echo "Docker が未インストールです"; exit 1; }

# OS 起動時に Docker を自動起動（コンテナは restart: unless-stopped で復帰）
sudo systemctl enable --now docker

if [ ! -f .env ]; then
  cp .env.example .env
  echo ".env を作成しました（BIND_IP を確認してください）"
fi

mkdir -p secrets
if [ ! -f secrets/pg_password.txt ]; then
  # サブシェル内 umask で、作成時点から 600 権限にする
  # hex にするのは DATABASE_URL に URL エンコードなしで書けるようにするため
  (umask 077; openssl rand -hex 32 | tr -d '\n' > secrets/pg_password.txt)
  echo "パスワード生成: secrets/pg_password.txt → パスワードマネージャーに保存してください"
fi

docker compose up -d
docker compose ps
