---
title: Rによるテキストマイニングのはじめ方
author: paithiov909
date: '2020-06-07'
lastmod: '2020-06-12'
slug: env
tags:
  - Settings
description: '環境構築の例'
---

## この記事について

すでにRなどのインストールをやったことがある人向けに環境構築の一例を示すものです。

ブログ記事をビルドするのに使っているのと同じ環境を準備するための例です。64bitのWindows10に以下をインストールします。

- R (64bit)
- Rstudio
- Rtools
- Miniconda (64bit)
- OpenJDK
- MeCab (64bit/32bit 両方)
- CaboCha

WSL、Docker、その他の仮想化技術などは使わずにインストーラをポチポチして入れます。

## 環境の準備

### Rのインストール

[公式サイト](https://cran.r-project.org/bin/windows/base/)からインストーラをダウンロードして入れます。

- 参考：[R初心者の館（RとRStudioのインストール、初期設定、基本的な記法など） - nora_goes_far](https://das-kino.hatenablog.com/entry/2019/11/07/125044)

### Rstudio/Rtoolsのインストール

素のRを立ち上げて以下を実行します。何か出てくるのでRstudioとRtoolsを選択して入れます。Rtoolsは必要に応じて配下の`bin`ディレクトリにパスを通しておきます。

```r
install.packages(c("remotes", "yesno", "installr"))
installr::installr()
```

### Minicondaのインストール

Pythonに依存するパッケージを実行できるように[Miniconda](https://docs.conda.io/en/latest/miniconda.html)を入れます。「すべてのユーザー向けにインストール」から`C:\Miniconda3`に入れています。

### OpenJDKのインストール

rJavaに依存するパッケージを動かすために[OpenJDK](https://openjdk.java.net/)を入れます。適当な場所に展開したディレクトリを環境変数`JAVA_HOME`に設定します。

### MeCab/CaboChaのインストール

MeCabとCaboChaを入れていきます。

64bit版のMeCabについては[野良ビルド](https://github.com/ikegami-yukino/mecab/releases)を利用します。文字コードはUTF-8を指定したほうがよいです。インストール先配下の`bin`にパスを通しますが、32bit版のMeCabよりも優先して読まれるようにそちらよりも上になるようにします。なお、このとき「全ユーザーに実行を許可しますか」という選択肢は「いいえ」を選びます。

32bit版については公式のインストーラを用いて入れることができます。文字コードはShift-JISを指定し、いずれについてもインストール先のディレクトリ配下の`bin`にパスを通しておきます。「全ユーザーに実行を許可しますか」という選択肢は「はい」を選びます。

{RMeCab}や{RcppMeCab}はダイナミックライブラリについては環境変数を見てパスが通っているものを読みに行きますが、辞書についてはレジストリを見て読みに行くため、この手順にしたがって環境を準備した場合、64bitのRからは64bitのMeCabが呼ばれ、辞書はShift-JISのものが参照されます。この場合、Windows環境の{RMeCab}はShift-JISの辞書を前提としているため正しく表示されますが、{RcppMeCab}はUTF-8で文字列を渡してUTF-8の辞書で解析することを前提としているために正しく表示されなくなります。このため、この状態で{RcppMeCab}の関数を呼ぶ場合には都度64bit版のほうのシステム辞書のパスを引数として与える必要があります。

## 自作パッケージ

ブログ記事中で使用している自作パッケージです。

### pipian

[![paithiov909/pipian - GitHub](https://gh-card.dev/repos/paithiov909/pipian.svg?fullname=)](https://github.com/paithiov909/pipian)

### rjavacmecab

[![paithiov909/rjavacmecab - GitHub](https://gh-card.dev/repos/paithiov909/rjavacmecab.svg?fullname=)](https://github.com/paithiov909/rjavacmecab)

### gibasa

[![paithiov909/gibasa - GitHub](https://gh-card.dev/repos/paithiov909/gibasa.svg?fullname=)](https://github.com/paithiov909/gibasa)

### tangela

[![paithiov909/tangela - GitHub](https://gh-card.dev/repos/paithiov909/tangela.svg?fullname=)](https://github.com/paithiov909/tangela)

