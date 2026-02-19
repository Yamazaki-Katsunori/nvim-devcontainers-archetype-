# nvim-devcontainers-archetype

Neovim ユーザーと VS Code / Cursor / JetBrains 系ユーザーの **開発環境差異を最小化**することを目的にした、Dev Containers + Docker Compose ベースのテンプレートリポジトリです。

- **ランタイム / DB / ミドルウェア**はコンテナ側に寄せる（再現性・統一性）
- **GUI エディタ**（VS Code / Cursor / JetBrains 等）は Dev Containers で利用する
- **Neovim ユーザー**は DevPod で Dev Container に入り、`--dotfiles` で Neovim 設定やセットアップを揃える

> このテンプレートは「Dev Containers（開発環境の定義）」を共通基盤にし、  
> エディタ差（VS Code / Neovim）を **入口の違いだけ**に抑えることを狙っています。

---

## 1. 提供する構成（例）

本テンプレートは、用途に応じて以下のサービスを Docker Compose で構成できます。

### デフォルトで利用する想定

- workspace（開発用：Dev Container の本体）
- web（nginx）
- db（PostgreSQL）

### 任意で有効化できる例（.devcontainer/compose.yaml 内でコメントアウト）

- valkey（Redis 互換）
- mailpit（メール検証）
- minio（S3 互換ストレージ）
- MariaDB（DB 差し替え例）

> 任意サービスは **`.devcontainer/compose.yaml` の該当ブロックのコメントを外して有効化**してください。  
> テンプレートとしては導線を単純化するため、この README では「コメント解除で有効化する」運用を想定します。

---

## 2. 利用前の準備（ホスト側）

### 2.1 必須

- Docker Desktop（または Docker Engine + Docker Compose）
- 利用するエディタ（VS Code/Cursor/JetBrains または Neovim）

### 2.2 Neovim ユーザー（DevPod）

- DevPod をインストール
- dotfiles リポジトリを用意（例：`~/.config` を管理するなど）
- `devpod up --dotfiles ...` で Neovim のセットアップを行う（例：dotfiles 内 `setup.sh`）

> Neovim 本体の導入や設定の適用は、テンプレート側では行いません（dotfiles 側に寄せます）。

---

## 3. セットアップ（共通）

### 3.1 `.devcontainer/.env` を作成

`.devcontainer/.env.example` をコピーして `.devcontainer/.env` を作成します。

```
cp .devcontainer/.env.example .devcontainer/.env
```

`.devcontainer/.env` は **Compose（開発環境）の設定値を集約する唯一の場所**として扱います。  
アプリ側（例：Laravel の `backend/.env`）に転記しても構いませんが、テンプレとしては **重複管理を避ける**方針です（必要に応じて各プロジェクトで決めてください）。

---

## 4. 起動方法

### 4.1 VS Code / Cursor / JetBrains（Dev Containers）

各エディタの Dev Containers 機能を使って開きます。

- VS Code / Cursor：Dev Containers（Remote Containers）拡張で「コンテナで開く」
- JetBrains：Dev Containers 対応機能で「Dev Container として開く」

---

### 4.2 Neovim（DevPod）

#### 4.2.1 DevPod で起動（dotfiles 適用）

例（イメージ）：

```
devpod up --dotfiles <あなたのdotfilesリポジトリ> .
```

#### 4.2.2 DevPod でコンテナへ入る

例（イメージ）：

```
devpod exec . -- bash
```

（または `devpod ssh` など、利用している DevPod の接続方式に合わせてください）

#### 4.2.3 Neovim 起動

コンテナ内で `nvim` を起動します。

```
cd /workspaces/app
nvim .
```

> 以前の「SSH ポート公開（2222）」「公開鍵注入」「nvim ラッパー」等は採用しません。  
> 入口を DevPod に統一することで、構成を単純化しています。

---

## 5. 任意サービス（valkey / mailpit / minio など）の有効化

このテンプレートでは、任意サービスは **`.devcontainer/compose.yaml` でコメントアウト**しています。  
使いたい場合は、該当サービスのブロックをコメント解除して起動してください。

### 5.1 例：ローカルで Compose を直接起動する場合

```
docker compose -f .devcontainer/compose.yaml up -d
```

> Dev Containers / DevPod 経由で起動する場合も、内部では Compose を利用します。  
> 任意サービスを有効化したい場合は、先に `.devcontainer/compose.yaml` のコメント解除を行ってください。

---

## 6. `post_create_command.sh`（テンプレ用）

`scripts/devcontainers/post_create_command.sh` はテンプレの雛形です。

- テンプレ版では **実際のパッケージインストール等は行いません**
- ログ出力と冪等性（再実行しても同じ処理をしない）の仕組みのみを提供します
- 必要に応じて、各プロジェクトの初期化処理（例：`pnpm i` / `composer install` 等）を追記してください

---

## 7. git 操作

基本は、コンテナ内でもホスト側でもどちらでも行えます。

- ホストで `git add/commit/push` を行う運用でもOK
- コンテナ内で `git` を使う場合は、dotfiles 側（DevPod の `--dotfiles`）で認証方法を整えることを推奨します
  - 例：HTTPS + トークン / GitHub CLI / SSH（必要ならエージェント転送等）

> テンプレート側では「公開鍵注入」「SSH ポート公開」による git 運用は提供しません。

---

## 8. ディレクトリ構成

```
.
├── .devcontainer
│   ├── .env
│   ├── .env.example
│   ├── compose.yaml
│   └── devcontainer.json
├── docker
│   └── services
│       ├── web
│       └── workspace
├── docs
├── scripts
│   └── devcontainers
│       └── post_create_command.sh
└── README.md
```

---

## 9. サンプル（docs）

以下に利用例をまとめています。

- post_create_command.sh 利用例：`./docs/example-usage/post_create_command.md`
- devcontainer-features 利用例：`./docs/example-usage/devcontainer-features-example.md`

---

## License

ライセンス：未設定（現時点では明示的な許諾なし）  
テンプレートを業務利用する場合は、ライセンス追加をお待ちいただくか、Issue を作成してください。
