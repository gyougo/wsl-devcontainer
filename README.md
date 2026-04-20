# WSL 開発コンテナ

このプロジェクトは、Windows Subsystem for Linux (WSL2) 開発環境用に構成された軽量な Alpine Linux ベースの Docker イメージを提供します。

## 概要

WSL2 に最適化された事前設定済み Docker コンテナイメージ：
- Alpine Linux ベースイメージ
- Docker-in-Docker サポート
- Bash シェルと補完機能
- wheel グループの sudo 設定
- タイムゾーン事前設定（Asia/Tokyo）
- 月次の自動ビルドとエクスポート

## 機能

- **軽量**: Alpine Linux ベースで最小限のリソース使用量
- **WSL2 互換**: Windows Subsystem for Linux 向けに特別に構成
- **Docker 対応**: Docker デーモン統合済みで使用可能
- **ユーザー管理**: `wsluser` が事前設定され sudo アクセス可能
- **SystemD の代替**: プロセス初期化に OpenRC を使用
- **自動エクスポート**: 月次の CI/CD パイプラインでコンテナをタール形式でエクスポート

## 必要な環境

- Docker がインストール済み
- WSL2 (WSL デプロイ用)
- イメージ用に約 300MB のディスク空き容量

## ビルド

```bash
docker build -t wslimg:latest .
```

## 実行

```bash
docker run -it wslimg:latest bash
```

## 自動ビルド

GitHub Actions ワークフロー (`.github/workflows/export.yml`) は自動的に：
1. 月次でコンテナイメージをビルド（毎月 1 日 UTC 00:00）
2. 実行中のコンテナをタール形式でエクスポート
3. タール形式をリリースアセットとしてアップロード
4. 一時的なコンテナとイメージをクリーンアップ

## 設定

### ユーザー設定
- デフォルトユーザー: `wsluser`
- ロケーション: `/home/wsluser`
- シェル: `/bin/bash`
- パスワード: なし (wheel グループは パスワードなし sudo アクセス)

### タイムゾーン
- デフォルト: `Asia/Tokyo`
- 必要に応じて Dockerfile で設定可能

### WSL 設定
- Windows パス統合: 無効
- ユーザー: `wsluser`
- ブートコマンドを正しい init システム起動用に設定

## ファイル構成

```
.
├── Dockerfile           # コンテナイメージ定義
├── .github/
│   └── workflows/
│       └── export.yml   # 自動ビルドとエクスポートワークフロー
└── README.md           # このファイル
```

## このプロジェクトの使用例

### 対話的シェル
```bash
docker run -it wslimg:latest bash
```

### コマンド実行
```bash
docker run wslimg:latest echo "Hello from container"
```

### タール形式でのエクスポート（手動）
```bash
docker build -t wslimg:latest .
docker run --name wslimg wslimg:latest
docker export wslimg -o wslimg.tar
docker rm wslimg
docker rmi wslimg:latest
```

## Assets (wslimg.tar) の使用例
```cmd
mkdir c:\wsl
pushd c:\wsl
REM Assets の wslimg-xxxxxxxx.tar を c:\wsl にダウンロード 
wsl.exe --import docker c:\wsl\docker c:\wsl\wslim-xxxxxxxx.tar
wsl.exe -d docker
```

## ライセンス

[Alpine Linux](https://alpinelinux.org/) に基づき、[WSL2 Alpine Docker セットアップガイド](https://zenn.dev/ignorant/articles/wsl2_alpine_docker) および [GitHub Actions から Releasesを作る](https://zenn.dev/techmadot/articles/github-actions-to-release) から着想を得ています。

## トラブルシューティング

### Docker デーモンが起動しない
コンテナを適切な特権で実行していることを確認してください：
```bash
docker run --privileged -it wslimg:latest bash
```

### パーミッション拒否
パーミッションの問題が発生した場合は、ユーザーが wheel グループに属していることを確認してください（Dockerfile で事前設定済み）。

## 開発への参加

Dockerfile を開発ニーズに合わせて自由に変更できます。一般的なカスタマイズ：
- `apk add` で追加パッケージを追加
- `RUN install -Dm 644` の行でタイムゾーンを変更
- ユーザー作成ステップでユーザー設定を調整
