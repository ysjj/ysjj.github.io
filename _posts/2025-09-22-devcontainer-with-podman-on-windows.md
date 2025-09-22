---
layout: post
title: Dev Container を Windows 上の Podman で使う
date: 2025-09-22
categories: tech
tags: devcontainer podman
---

# Quick Start

1. VS Code: 設定 > Dev Containers で項目を絞り込む。
2. Docker Path を `podman` に変更する。
3. Exceute In WSL Distro を `podman-machine-default` に変更する。

# 経緯

Docker Path を `docker` から `podman` に変更するのは設定項目を眺めていれば気付くところ。

ただ、
vscode が既定ではデフォルト ディストリビューションをホスト環境とみなすのか、
WSL に Ubuntu なども入れている場合はこれだけでは上手くいかない。

デフォルト ディストリビューションを `podman-machine-default` へ変更するように促す記事を
ちらほらみかけた[^wsl-set-default-podman-machine-default]。

この対処方法が気に入らずに設定項目を眺め直したところ Execute In WSL Distro を発見し、
これを `podman-machine-default` に変更することで無事 podman コンテナを Dev Containers で開くことが出来た。

この設定項目: `dev.containers.executeInWSLDistro` が最近追加されたものなのかと思えば、
[2023-01-02の記事](https://www.tecracer.com/blog/2023/01/devcontainers-on-windows-without-docker-for-desktop.html)で
言及されているので、そこまで新しいものではなさそうである。

日本語の記事で言及されたものはググッっても見当たらない。
日本で Windows 上の podman 利用者が少ないのか、
Windows 上の podman と vscode で Dev Containers を利用しようとする人が少ないのか、
はたまた大半の人はデフォルト ディストリビューションを変更しているのか。。。

# 脚注
[^wsl-set-default-podman-machine-default]: Windows コンテナ開発：Podman × WSL × VSCode DevContainers セットアップガイド > [2.4.4 WSL2 のデフォルトディストリビューションの確認と設定](https://zenn.dev/naoyoshinori/articles/53b93bb289554f#2.4.4-wsl2-%E3%81%AE%E3%83%87%E3%83%95%E3%82%A9%E3%83%AB%E3%83%88%E3%83%87%E3%82%A3%E3%82%B9%E3%83%88%E3%83%AA%E3%83%93%E3%83%A5%E3%83%BC%E3%82%B7%E3%83%A7%E3%83%B3%E3%81%AE%E7%A2%BA%E8%AA%8D%E3%81%A8%E8%A8%AD%E5%AE%9A) など
