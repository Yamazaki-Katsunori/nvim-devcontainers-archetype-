# Dev Container Features 利用例

本ドキュメントでは `devcontainer.json` の `features` を利用して  
ツールをコンテナへインストールする方法を説明します。

---

## Features とは

Dev Container Features は、Dockerfile を直接編集せずに  
ツールを追加できる仕組みです。

- 再利用可能
- 宣言的
- バージョン固定可能

---

## 設定例

```json
{
  "name": "nvim-archetype",
  "dockerComposeFile": [
    "compose.yaml"
  ],
  "service": "workspace",
  "workspaceFolder": "/workspaces/app",
  "runArgs": [
    "--env-file",
    ".devcontainer/.env"
  ],
  "shutdownAction": "stopCompose",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.14",
      "installTools": true
    },
    "ghcr.io/devcontainers-extra/features/uv:1": {},
    "ghcr.io/devcontainers/features/node:1": {}
  },
  "initializeCommand": "chmod +x scripts/devcontainers/*",
  "postCreateCommand": "scripts/devcontainers/post_create_command.sh"
}
```

---

## 各 Feature の説明

### Python

```
ghcr.io/devcontainers/features/python:1
```

- Python 3.14 をインストール
- pip / venv なども利用可能
- `installTools: true` により追加ツールを有効化

---

### uv

```
ghcr.io/devcontainers-extra/features/uv:1
```

- Rust製 Python package manager
- `uv init`
- `uv add`
- `uv sync`

が利用可能

---

### Node

```
ghcr.io/devcontainers/features/node:1
```

- Node.js
- npm
- pnpm（Corepack経由）

---

## Feature を使うメリット

| 方法 | 特徴 |
|------|------|
| Dockerfile | 自由度高いが保守コスト増 |
| Features | 宣言的・簡潔・再利用可能 |

テンプレート用途では **Features 推奨**。

---

## バージョン固定について

メジャーバージョンは必ず指定推奨：

```
python:1
node:1
```

これにより破壊的変更の影響を回避できます。

---

## rebuild が必要なケース

以下を変更した場合は必ず実行：

```
./scripts/devcontainers/cli/cli_rebuild.sh
```

- features
- Dockerfile
- compose.yaml
- base image

---

## 設計思想

- ランタイムはコンテナへ寄せる
- エディタ体験はホストに残す
- 言語ツールは Features で管理する

これにより：

- 再現性
- チーム統一
- 最小摩擦

を両立できます。
