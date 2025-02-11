---
title: プロジェクトダッシュボードSeedsnを支える技術
description:
slug: seedsn-tech
date: 2025-01-16T22:40:28+09:00
draft: false
hidden: false
image: seedsn.png
categories:
  - IT技術
tags:
  - Seedsn
  - フロントエンド
  - バックエンド
  - Golang
  - React
  - Next.js
authors: 
  - 山田ハヤオ
---

こんにちは、GITYでSeedsnを開発している山田ハヤオです。SeedsnはGITYで進行しているプロジェクトや、
これから立ち上げたいプロジェクトを掲示しておき、人と人を繋げていくというプラットフォームです。

当初このアプリは群馬大学の4年生の先輩たちによって開発されており、現在ではそれを私と私の友人が引き継いで開発を続けています。

今回はSeedsnの開発に利用されている技術と、現在の問題点についてお話します。

## フロントエンド

### 採用している主な技術

フロントエンドではReactのフレームワークであるNext.jsを用いています。キャッシュによる最適化やファイルベースなルーティング等、非常に重厚なフレームワークです。
SeedsnではPagesルーティングを採用し、殆どのコンポーネントがCSRで動作しています。

UIライブラリにはMUIを用いています。MUIは旧来はMaterial UIと呼ばれており、React上で動作するUIライブラリとして古くから利用されています。
styled-componentの上に構築されており、Googleの提唱するMaterial  DesignをReact上で簡単に実装することができます。

### フォーマッタとリンタについて

フォーマッタにはESLint v8系とPrettierを用い、[`eslint-plugin-prettier`](https://github.com/prettier/eslint-plugin-prettier)でESLint経由でPrettierを実行しています。このプラグインは現在は既に非推奨になっているようですが、フォーマットが行われていない部分が一目瞭然になり便利なため未だに利用しています。

`eslint-plugin-prettier`と`eslint-config-prettier`の役割の違いや現在のベストプラクティスは以下に記載されています。

[Prettier と ESLint の組み合わせの公式推奨が変わり plugin が不要になった \| blog\.ojisan\.io](https://blog.ojisan.io/prettier-eslint-cli/)

注意するべきは、上記のサイトで記載されているベストプラクティスについてはあくまでも「ESLintとPrettierを組み合わせる際の方法」の話に限定されるものであり、実際の設定ファイルの書き方は推奨されるものではありません。

現行のESLint v9以降ではFlat Configと呼ばれる新しい設定ファイルの記述方法がデフォルトとなり、従来の`json`ファイルを利用した記述方法は廃止されました。
Flat ConfigはECMA Script Modulesを活用した新たな書き方であり、従来の設定でわかりにくかった`extends`や`plugins`が利用できなくなりました。

従来までの`extends`は記述された文字列を元にESLint側が独自で設定ファイルの依存関係を解決するという形でした。
これはESLint側の実装量が多くなる上、コード上では単なる文字列でしかないため関係の記述の複雑さと柔軟性を低下させるものでした。

新しいFlat ConfigではES Modulesによる`import`文を用いてパッケージから設定ファイルを直にインポートします。これが意味するところは、旧来まではESLintによって独自に行っていた依存関係の解決とインポートをJavaScriptエンジンに委任するということです。

設定の記述が大きく変わり破壊的変更も多く加えられた結果、Next.jsがFlat Configをサポートするようになったのは最新のNext.js 14になってからでした。
SeedsnではNext.js 13を利用しているため、これらの最新の設定方式を記述することができません。

リンタのためだけにアプリケーションフレームワークのメジャーバージョンを更新するべきかというと、私は決してその必要はないのではないかと思います。
開発メンバーの多くはNext.js 14で導入された新機能をふんだんに活用するほど精通していませんし、現在のSeedsnに導入するにはそれなりの規模の改修が必要になります。

現在は[Biome](https://biomejs.dev/)や[XO](https://github.com/xojs/xo)といった選択肢も登場しており、今後の動向次第ではこちらに乗り換えることになるかもしれません。

### 状態管理

Seedsnはその性質上、アプリケーションが多くの状態を保持する必要があります。

初期の頃のSeedsnではContextを用いていたものの、これらの更新による不必要な再レンダリングやコード量の増加等を考慮した結果
[Jotai](https://jotai.org/)を導入することになりました。
JotaiはRecoilの意思を継いだ状態管理ライブラリであり、ReduxやZustandとは異なり`atom`という小さな状態を複数個保持しています。

SeedsnではJotaiを採用していますが、状態管理ライブラリに大きく依存することを避けるためにAtomをexportせずにカスタムフック内で隠蔽しています。
隠蔽は以下のように行います。例えば、なにかの金額をグローバルに管理するという場合には以下のようになります。

```tsx
import { useAtom, atom } from "jotai"
const moneyAtom = atom<number | null>(null)

export const useMoney = ():number | null => useAtom(moneyAtom)
```

各コンポーネントは`useMoney`を使い、Jotaiの存在を認知することはありません。

将来的に状態管理ライブラリに大きな変革が起きた場合やJotaiが利用できなくなった場合等にも容易に対処できるよう、できる限りライブラリへの依存は薄めていく方針です。

### データ取得

データ取得も同様にJotaiを用いています。Jotaiを採用した大きな理由の一つに[Async atom](https://jotai.org/docs/guides/async)の存在があります。

使い方はReact 19における[`use`フック](https://ja.react.dev/reference/react/use)に近く、フック内でデータ取得を行います。

```tsx
import { atom, useAtom } from "jotai"
import { APIClient } from "@/utils"

const projectsAtom = atom(async (get) => {
    const api = new APIClient()
    const res = await api.getProjects()
    if (!res.ok) {
        return null
    }
    return await res.json()
})

export const useProjects = () => useAtomValue(projectsAtom)
```

実際にはもう少し要件が複雑になるため同様のコードというわけではないのですが……

やはり先程も言った通り、ライブラリへの依存を抑えて書き換えやすくするということに焦点を当てています。
フロントエンドの業界は流行の変化が激しいので、それに追従できる形のコーディングを心がけています。

また、APIClientも注目してほしい部分です。後述するバックエンドサーバーと通信を行うために記述したクライアントラッパーであり、シンプルな実装ながら非常に実用的です。

```ts
interface TypedResponse<T> extends Response {
  json(): Promise<T>;
}

type PromiseRes<T> = Promise<TypedResponse<T>>;

export class BaseClient {
  /**
   * @param baseUrl APIのベースURL
   */
  private readonly baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  fetch = <T>(endpoint: string, method: string, cookie?: string, body?: unknown): PromiseRes<T> =>
    fetch(`${this.baseUrl}/api/${endpoint}`, {
      headers: new Headers({
        "Content-Type": "application/json",
        Cookie: cookie ?? ""
      }),
      method,
      body: JSON.stringify(body),
      credentials: "include"
    });

  get<T>(endpoint: string, cookie?: string): PromiseRes<T> {
    return this.fetch(endpoint, "GET", cookie);
  }
}

export class APIClient {
  private readonly backend: BaseClient;

  private readonly cookie: string = "";

  /**
   * @param cookie ユーザーのCookie
   */
  constructor(cookie = "") {
    this.backend = new BaseClient("https://example.com");
    this.cookie = cookie;
  }

  getProjects = (): PromiseRes<{ projects: Project[] }> => this.backend.get("projects", this.cookie);
}
```

`fetch`APIを型定義と共にラップしたBaseClientと、実際のエンドポイントが記述されたAPIClientで構成されています。
これにより各コンポーネントでAPIのURLを直に記述することなくサーバーのエンドポイントを叩くことができます。

この実装の現在の課題は型定義です。fetchのデコード結果の`any`型を強引に書き換える形で型定義を実現しているのですが、実際にサーバーから受け取った値をチェックしているわけではないので型安全とは言えません。

Tanstack Queryの`queryFn`としてAPIClientを指定し、Zodでバリデーションを行うというのが理想でしょう。
運の良いことにJotaiとTanstack Queryを統合するライブラリが公式によって紹介されています。

[Query — Jotai, primitive and flexible state management for React](https://jotai.org/docs/extensions/query)

今後、データフェッチでの型安全性が重要視される場合には導入することになるかもしれません。
Jotaiは比較的薄いライブラリであるため、こういった複数のライブラリ同士での組み合わせが行いやすいのも特徴です。

### 今後の展望

フロントエンド業界は今後ますますRSCの世界が中心になっていくでしょう。そうなった際にstyled-componentは足枷になる可能性があります。

パフォーマンスにどの程度重点を置いて開発するかというのは規模感や技術力に依存するのでしょうが、果たしてSeedsnの規模はRSCを念頭に置く必要があるのかどうか。
残念ながら実践経験の少ない私にはそれらを見極める方法がありません。GITYにいるエンジニアさんにはよく「そこまで気にしなくてもいいんじゃない?」と言われますが、
効率やパフォーマンスを強く意識してしまうが故に開発速度やプライオリティを軽視しがちなのは私の課題なのではないかと思います。

## バックエンド

### 利用している技術やサービス

バックエンドにはGolangとバックエンドフレームワークであるGinを用いています。

データベースにはSupabaseを用いており、[supabase-go](https://github.com/supabase-community/supabase-go)というコミュニティによって開発された
ライブラリを用いて通信を行っています。このライブラリはORMのような重厚なものを利用しておらず、PostgRESTというPostgreSQLのREST APi Wrapperを用いています。

認証バックエンドにはKeycloakやGoogleを用い、OpenID Connectと呼ばれるOAuth 2を利用したプロトコルを用いて認証・認可を行っています。
[go-oidc](https://github.com/coreos/go-oidc)はOpenID ConnectをGolangで実装するためのライブラリであり、Fedora CoreOSのチームが開発してます。
Golang準公式の[oauth2](https://github.com/golang/oauth2)を拡張する形で利用することができます。

### データベースとの通信について

[supabase-go](https://github.com/supabase-community/supabase-go)ではSQL文のような感覚でメソッドチェーンを記述しSupabaseからデータを取得できます。
准公式という扱いらしく、コミュニティ主導によって開発されているライブラリのようです。
その実装は[postgrest-go](https://github.com/supabase-community/postgrest-go)を薄くラップしたもので、クエリで実際に記述しているもののほとんどの実装はこちらのライブラリに書かれています。

```go
func GetProjects() ([]Project, error) {
	var projects []Project
	var resp interface{}
	_, err := client.From(projectListTable).Select("*", "", false).ExecuteTo(&resp)
	if err != nil {
		return projects, err
	}

	// convert to JSON byte array
	jsonData, err := json.Marshal(resp)
	if err != nil {
		return err
	}

	// unmarshal
	err = json.Unmarshal(jsonData, &projects)
	if err != nil {
		return err
	}

	return projects, nil
}
```

上記のプロジェクト一覧を取得する際のコードの一部分です。
`json`ライブラリで構造体にマッピングしてあげるだけなので、取得されたデータの扱いはhttpリクエストの結果を処理するのと全く同様になります。

軽量でSQLに近い書き方ができるので学習コストが低い一方で、ORMやスキーマ定義を行っていないので構造変更が起きた際のマイグレーションに非常に苦労します。
こちらも規模の小さいアプリケーションには非常に向いていますが、今後規模が拡大していくとなった際に課題になりそうな部分です。

またこちらもフロントエンドと同じくGolangの型定義以上のバリデーションを行っていないため、安全なコードであると言い切ることはできません。
これらは早急に何かしらのバリデーションライブラリを用いてチェックを実装したいところです。

## 終わり

Seedsnは群馬大学の情報学部の学生が勉強しながら開発をしているアプリケーションです。
Next.js等のモダンなフレームワークを採用し、高速かつ少ないランニングコストで実行できます。

一方で、比較的新しい技術を積極的に用いているとはいえ最新とは言い難い状況です。
更に、バリデーションや型チェック等の細かな部分の粗が目立ってしまっているのも現実です。

開発当初はページ全体のレンダリングが停止してしまうようなバグが頻発し不安定だった時期もありました。
今後はモダンな技術を採用しつつも安定性や安全性に重点を置いたアップデートを行っていきたいです。

またSeedsnで大きな採用技術の変更や、開発で大きな壁に遭遇した際にはブログに書こうと思います。
最後まで読んでいただきありがとうございました。
