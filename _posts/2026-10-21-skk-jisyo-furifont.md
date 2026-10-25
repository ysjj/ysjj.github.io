---
layout: post
title: SKK-JISYO.furifont v0.6.2
date: 2026-10-21 10:28 +0900
category: tech
tags: skk skk-jisyo
---

# SKK辞書 for Furifont v0.6.2

[antfu/furifont](https://github.com/antfu/furifont)をフォークして
[feat/generate-skk-jisyo](https://github.com/ysjj/furifont/tree/feat/generate-skk-jisyo) ブランチを作って
GitHub Copilot に解析とコーディングを任せて 1時間ほどプロンプト出しとレビューを繰り返し、
それっぽいものが出来た。
GitHub Copilot Free プランでクレジットを 4~5% ぐらい消費した。
コードベースの大きさに比べて思ったより少なく済んだような気がする。

出力されたSKK辞書ファイルは、フォント設定をFurifontにしたメモ帳で開いて
目視確認はしているものの自分ではまだ使っていないので「作ってみた」レベル。
常用できるものなのかは何とも言えない。

<style>
    @font-face {
        font-family: "Furifont Sans";
        font-display: swap;
        font-weight: 250 900;
        ascent-override: 88%;
        descent-override: 12%;
        line-gap-override: 0%;
        src: url("https://furifont.antfu.me/fonts/FurifontSansVF.woff2?v=0.6.2") format("woff2");
    }
    .furifont .gist .blob-code {
        font-family: "Furifont Sans";
    }
</style>
<details style="margin-block-start:1em; margin-block-end:1em;" class="furifont">
<summary>SKK-JISYO.furifont v0.6.2</summary>
{% gist 10b89737085bf41c044f4f71fca6fdcb SKK-JISYO.furifont %}
</details>

どの読み(ルビ)を基本とするのか、他のどの読みに異字体セレクタ:VS242~を割り振るのかは
元にしている辞書データによって変化するっぽいので、Furifont のバージョン毎にSKK辞書も作り直す必要がありそう。

個人辞書 ~/.skk-jisyo に記録されると、記録された異字体セレクタに対応付く振り仮名が変わった際に混乱しそうな気がしている。
