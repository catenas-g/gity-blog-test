# GITY Blog

GITYのメンバーが各々の学んだことや得意分野の話を自由に発信するブログです。

## 開発環境の構築

Dockerによる開発環境は現在準備中です。

### 必要なソフトウェアのインストール

以下の開発用ツールをインストールしてください。

- [Git](https://git-scm.com/)
- [Node.js](https://nodejs.org/ja)
- [PNPm](https://pnpm.io/ja/)

### ソースコードと依存関係を取得

```bash
git clone https://github.com/sdmlaborg/gity-tech-blog.git
cd gity-tech-blog
pnpm install
```

### 新しい記事を作成

```bash
pnpm run new
```

### ローカルサーバーの実行

```bash
pnpm run dev
```
