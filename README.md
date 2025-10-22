# Big Data Dev Workspace (Hadoop / Spark / Hive / Kafka)

A production-like, single-repo Big Data development workspace tuned for GitHub Codespaces or local Docker Compose. It wires together:

- HDFS (NameNode + DataNode) — NameNode UI: `9870`
- YARN ResourceManager — UI: `8088`
- Spark (Master + Worker) — Master UI: `8080`, Worker UI: `8081`
- Hive (Postgres metastore) — Metastore: `9083`, HiveServer2: `10000`
- Postgres — Hive metastore DB
- Kafka + Zookeeper — Kafka broker: `9092`, ZK: `2181`
- Kafdrop — Kafka UI: `9000`
- Optional ngrok support for public UIs via `NGROK_AUTH_TOKEN`

> **Important:** Never commit secrets (e.g. `POSTGRES_PASSWORD`, `NGROK_AUTH_TOKEN`). Use `.env` (local) or GitHub Codespaces Secrets.

---

## Quick setup (Codespaces)
1. Create the Codespaces secret:
   - Go to **Repository → Settings → Secrets → Codespaces → New repository secret**
   - Name: `NGROK_AUTH_TOKEN`
   - Value: your ngrok token (optional). Leave blank if you don't want public UIs.

2. Open the repository in GitHub Codespaces and start the Codespace.

3. The devcontainer `postCreateCommand` will run `start.sh` automatically. If you need to run manually inside the Codespace terminal:
```bash
cp .env.example .env            # edit .env and set POSTGRES_PASSWORD (and optionally NGROK_AUTH_TOKEN)
./start.sh
