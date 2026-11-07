# home-db

自宅サーバー（Linux ミニPC）上で動かす、自作アプリ共用の PostgreSQL。
Docker Compose で管理し、LAN 内からのみ接続可能。

## セキュリティ対策

| 対策               | 内容                                                                                      |
| ------------------ | ----------------------------------------------------------------------------------------- |
| LAN 限定バインド   | `BIND_IP`（LAN 側 IP）のみで待ち受け。未設定時は `127.0.0.1` に倒れる                     |
| 外部非公開         | ルーターでポート開放しない=インターネットからの経路なし                                   |
| パスワード         | 32 バイト乱数を自動生成。ファイル権限 `600`、Git 管理外                                   |
| secrets 渡し       | 環境変数ではなくファイル経由で渡し、`docker inspect` やログに出さない                     |
| 認証方式           | `scram-sha-256`                                                                           |
| 権限昇格防止       | `no-new-privileges` でコンテナ内の setuid による昇格を禁止                                |
| 公開リポジトリ対策 | `.env` / `secrets/` を `.gitignore`。GitHub の Secret scanning + Push protection を有効化 |

## 構成

```
home-db/
├── compose.yaml   # Postgres 定義
├── .env.example   # BIND_IP のテンプレ
├── .gitignore
└── setup.sh       # 初期セットアップ兼起動
```

## 実行手順

### 初回

1. サーバーPCにリポジトリを clone
2. 実行:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```
3. `.env` の `BIND_IP` がサーバーの IP と一致するか確認（違えば修正して再度 `./setup.sh`）
4. `secrets/pg_password.txt` の中身をパスワードマネージャーに保存
5. `docker compose ps` で `healthy` になっていることを確認

### アプリ用 DB の追加例

```bash
docker exec -it home-postgres psql -U pgadmin -c "CREATE DATABASE <DB名>;"
```

アプリ側の接続文字列:

```
DATABASE_URL=postgresql://pgadmin:<パスワード>@192.168.0.36:5432/<DB名>
```

### 再起動後の確認

バインド先 IP が起動時に未割り当てだと起動失敗することがある。その場合は `./setup.sh` を再実行。

## 注意

- パスワードは初回初期化時のみ使用される。後からファイルを書き換えても DB 側は変わらない（変更は `ALTER ROLE pgadmin PASSWORD '...'`）
- volume（`pgdata`）を消すとデータも消える。`docker compose down -v` は実行しない
