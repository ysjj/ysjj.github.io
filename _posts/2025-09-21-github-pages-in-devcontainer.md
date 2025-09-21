---
layout: post
title: GitHub Pages を Dev Container で使う
date: 2025-09-21 23:58:33 +0900
categories: tech
tags: devcontainer github jekyll
---

# Quick Start

1. GitHub にアカウントを作る
2. GitHub に [`<ユーザ名>.github.io` リポジトリを作成する](https://docs.github.com/ja/pages/getting-started-with-github-pages/creating-a-github-pages-site)
3. 2 で作成したリポジトリをローカルに clone にする。clone 結果を作業ツリーと呼ぶ。
4. Podman または Docker を入れる
5. VS Code を入れる
6. VS Code に Dev Containers 拡張を入れる
7. [このページの GitHub リポジトリ]({{site.github.repository_url}})にある
     .devcontainer と _config.yml を作業ツリーにコピーする。
8. 作業ツリーを VS Code で Dev Container として開く。
9. 作業ツリー直下に index.md を作成する。
10. ブラウザで http://localhost:4000 にアクセスすると 9. で追加した index.md が html 変換されて表示される。

以下、動機やら試行錯誤やらをつらつらと記す。

# 経緯

Dev Container を Windows 上の Podman で利用する Tips を残す[^devcontainer-with-podman-on-windows]のに GitHub Pages を使ってみようと考えた。
なお Qiita や Zenn にはアカウントを持っていない。

## First Step

[GitHub Pages のドキュメント]に一通り目を通して
[とりあえず専用リポジトリを作ってみた](https://github.com/ysjj/ysjj.github.io/commit/c3e34d5a568a3b5b79d5bbcbcfd163d8c3144fc7)
が、ローカルで変更のプレビューとテストを行いたくなった。

GitHub Pages は静的サイトジェネレータ Jekyll を組み込んでいるということで Docker イメージがないか探してみたところ
[公式 Jekyll Docker イメージ](https://hub.docker.com/r/jekyll/jekyll) があったので `podman run --rm -it jekyll/jekyll bash` で動かしてみた。

無事動いたのでさらに Dev Container で接続しようとしたところ、、、次のエラーが発生した:

![コンテナーは、VS Code サーバーのすべての要件を満たしているわけではありません](/assets/images/2025/09/08/the-container-does-not-meet-all-the-requirements-of-the-vscode-server.png)

## Troubleshooting

最終更新が3年前ということもあるのか、jekyll/jekyllの
[ベースイメージが Alpine 3.15](https://github.com/envygeeks/jekyll-docker/blob/fb892998d444b7b2e4074adeb032197f67853c0a/opts.yml#L1)
であり、今となっては古すぎて Dev Container で利用できなくなっているということらしい。

実は前述のエラーダイアログにもリンクが記載されているが、
[Can I skip GLIBCXX check when using an unsupported Alpine distro?の回答](https://stackoverflow.com/a/78641858)
を読んで辿った(https://aka.ms/vscode-remote/linux)の変更履歴を Wayback Machine で探ってみたところ
[2024-01-04](https://web.archive.org/web/20240104230242/https://code.visualstudio.com/docs/remote/linux)
までは Alpine 3.9+ だったところ
[2024-02-11時点](https://web.archive.org/web/20240211205540/https://code.visualstudio.com/docs/remote/linux)
からは Alpine 3.16+ に上がっていることが確認できた。

[vscode 1.86](https://code.visualstudio.com/updates/v1_86)のリリースが2024年1月なので、
このあたりから Dev Container では使えなくなっていたということだろう。

別件でベースイメージを Alpine 3.18 に上げる
[issue](https://github.com/envygeeks/jekyll-docker/issues/363)
が立っていたり
[PR](https://github.com/envygeeks/jekyll-docker/pull/369)
が出されていたりするが、いずれも2年ほど棚晒し状態で解消する見込みはなさそうである。

## Second Step

既存のものが使えないなら作ればいい。

# 過程

## First Step

当初は
[jekyll/jekyll の Dockerfile](https://github.com/envygeeks/jekyll-docker/blob/fb892998d444b7b2e4074adeb032197f67853c0a/repos/jekyll/Dockerfile)
を参考にしていたが、erbらしきタグが多用されており変数値を確認するが面倒になった。
また、そもそもベースイメージにはダウンロード済みだった ruby:3.4.5-slim を使おうとしていたので導入に必要なパッケージ名が異なり
その調整も面倒だった。

しかし、どうして openjdk8-jre を導入しているのだろうか。。。

## Second Step

ふと
[github/pages-gem のリポジトリに Dockerfile](https://github.com/github/pages-gem/blob/cd7369a21e3ec3f20753012da8e312859dca41a4/Dockerfile)
が含まれていることに気付き、こちらを参考にすることにした。

### Containerfile

podman を使うこともあり、Dockerfile より技術的にニュートラルな名前で悪くない。

```dockerfile
# customization of https://github.com/github/pages-gem/blob/master/Dockerfile
ARG RUBY_VERSION=3.4.5
FROM ruby:${RUBY_VERSION}

RUN apt-get update -qq && \
    apt-get install -y git locales make nodejs

RUN echo "en_US UTF-8" > /etc/locale.gen && \
    locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN groupadd -g 1000 gh-pages && \
    useradd -u 1000 -g 1000 -m -s /bin/bash gh-pages

USER gh-pages:gh-pages

COPY --chown=gh-pages:gh-pages --chmod=0644 ".devcontainer/Gemfile" /home/gh-pages
ENV BUNDLE_GEMFILE=/home/gh-pages/Gemfile
RUN NOKOGIRI_USE_SYSTEM_LIBRARIES=true bundle install

RUN mkdir /home/gh-pages/bin
ENV PATH="/home/gh-pages/bin:$PATH"
COPY --chown=gh-pages:gh-pages --chmod=0755 ".devcontainer/*.sh" /home/gh-pages/bin

ARG PUBLISHING_SOURCE=/home/gh-pages/docs
ENV PUBLISHING_SOURCE=${PUBLISHING_SOURCE}

CMD ["restart_onhup.sh", "jekyll.sh", "serve", "--host", "0.0.0.0", "--watch", "--force-polling", "--livereload"]
```

#### ベースイメージ

前述のベースイメージには ruby:3.4.5-slim を使うという方針を早々に翻し ruby:3.4.5 を採用した。
github/pages-gem に倣ったこともあるが、ローカルの動作確認用なのでサイズに拘る必要もないという割り切りもあった。

#### locales

ベースイメージに含まれていないが不思議だが、ruby の実行には必須でない・不要なのだろう。

jekyll に必要なのか理解していないが、jekyll/jekyll と github/pages-gem のいずれの Dockerfile にも
locales の導入と LANG=en_US.UTF-8 の設定が含まれていたので、それに倣った。

#### ユーザ / グループ

気分的にやはり root で動かすのは気持ち悪いので gh-pages:gh-pages とする。

しかし USER 命令を仕込むタイミングが難しい。
後続の COPY 命令には基本的に --chown=gh-pages:gh-pages を付けることになる。

#### Gemfile

GitHub Docs:
[Jekyll を使用して GitHub Pages サイトを作成する > サイトを作成する](https://docs.github.com/ja/pages/setting-up-a-github-pages-site-with-jekyll/creating-a-github-pages-site-with-jekyll#creating-your-site)
の記載されている手順に準じて、
`podman run --rm -v .:/srv/jekyll jekyll/jekyll jekyll new --skip-bundle scrap` で作成した Gemfile を編集して利用している。

#### bundle install

`NOKOGIRI_USE_SYSTEM_LIBRARIES=true` は locales と同じく jekyll/jekyll と github/pages-gem に準じた。

良く知らなかったけど nokogiri gem はビルド・エラーで苦しむことが多いらしい。
これもビルド・エラーを回避するための小技なのだろうか。

#### jekyll.sh

「Gemfile を ~/ (ホーム・ディレクトリ)、文書源を ~/docs または /workspace に置く」の様に、
Gemfile と文書源と分離しようとしてハマった。

```sh
#!/bin/bash

GITHUB_REPO_NWO=$(git -C "$PUBLISHING_SOURCE" remote -v | sed -ne 's,^origin\s*https://github\.com/\(.*\)\.git\s*(fetch)$,\1,p')

cd
exec env PAGES_REPO_NWO=$GITHUB_REPO_NWO \
  bundle exec jekyll "$@" \
                      --source      "$PUBLISHING_SOURCE" \
                      --destination "$PUBLISHING_SOURCE/_site"
```

1. Gemfile がなくとも `jekyll serve` は動く。
   ただし、プラグインは `--plugins` オプションで各 gem のフルパスを指定しないと認識されない。
   このことに中々気付けずにずいぶん時間を溶かしてしまった。
2. 文書源を作業ディレクトリ以外に置く場合は `--source` (+ `--destination`) オプションで指定できるが、
   GitHub レポジトリ情報を見失うため別途 `GITHUB_REPO_NWO` 環境変数にユーザ名/リポジトリ名を設定する必要がある。

GitHub 界隈では(?) NWO は Name With Onwer を意味するらしい。
[jekyll 独自用語](https://jekyll.github.io/github-metadata/configuration/)かもしれないが、
GitHub Enterprise のコマンドライン ユーティリティに [ghe-nwo](https://docs.github.com/ja/enterprise-server@3.14/admin/administering-your-instance/administering-your-instance-from-the-command-line/command-line-utilities#ghe-nwo) というものがあるようなので、全く jekyll 独自というわけでもなそうである。

#### restart_onhup.sh

[jekyll/jeyll#2302](https://github.com/jekyll/jekyll/issues/2302) から
意図的に _config.yml の変更は自動反映されないので、
コンテナ内の `kill -HUP 1` で jekyll を再起動させるラッパースクリプトを導入した。

```sh
#!/bin/bash

program=("$@")
start_program() {
    "${program[@]}" &
    pid=$!
}
restart_program() {
    if kill -0 $pid; then
        kill $pid
        wait $pid
    fi
    start_program
}

trap 'restart_program' HUP
trap 'kill $pid; exit 0' TERM INT

start_program
while true; do
    wait $pid
    kill -0 $pid || start_program
done
```

実のところ大本は google 検索時の AI 回答に拠っている。
ぼんやり考えていたものと大きな違いがなく理解に苦労することはなかったが、
AI コーディングを垣間見た気がした。

しかし
「`while true; do ..; done` 内の `wait` と `kill -0` の `$pid` 引数の値が同じである場合と異なる場合がある」
ということはあまり自明ではなかろう。
このスクリプトの役割: `kill -HUP` を受けた状況では `wait` と `kill -0` で `$pid` の内容が変わるのだが、
これがパッと見で理解できるものではなかろう。分かりにくい。

`kill -HUP` を受けると `restart_program` は現在の jekyll を殺して `start_program` で jekyll を再開させる。
`while` ループ内の `$pid` は `wait` の時点では殺されたもの、`kill -0` の時点では `start_program` で再開されたものになる。
この関係が `trap` のハンドラに隠されているため見通しが非常に悪く分かりにくくなる要因である。

`kill -HUP` と関係なく jekyll プロセスが異常終了した場合、
`wait` 後の `kill -0` が失敗するので `||` の右辺 `start_program` が評価され、
jekyll が再開する。

fswatch を導入することも考えたが、_config.yml を修正するのは初期の試行錯誤だけだろうから、手動の `kill -HUP` で十分だと判断しあ。

#### PUBLISHING_SOURCE

公開元ディレクトリをビルド引数または環境変数で調整できるようにしておく。

Dev Container では /workspace で構成している。

### .devcontainer

転送ポートの 35729 は jekyll がブラウザを操作: ページ更新時に自動リロードするためのものらしい。

ホスト側のワークスペースフォルダが Dev Container 上の jekyll 文書源として認識されるように
`build.args.PUBLISHING_SOURCE` と `workspaceFolder`、`workspaceMount` の `target` を揃える: `/workspace`。

作成されるイメージ名がランダムだと分かりにくいので `build.options` に `--tags localhost/github-pages:latest` を加える。
それでも Dev Cantainer は独自のイメージ名を生成するのだが、イメージIDが一致するので素性の把握が容易になるだろう。
compose.yml を使用すればもう少しマシになることは分かっているが、このためだけに compose 構成を取るのは本末転倒のように思えて避けた。

作成されるコンテナ名がランダムだと分かりにくいので `runArgs` に `--name github-pages` を加える。

# 脚注

[^devcontainer-with-podman-on-windows]: 後日公開予定
