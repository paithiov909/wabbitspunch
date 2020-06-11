---
title: 'このサイトについて（ポエム）'
author: 'paithiov909'
date: '2020-04-21'
lastmod: '2020-4-21'
tags:
  - Concepts
description: 'RでRMeCabに依存しないテキストマイニング'
---

## このサイトでやりたいこと

> 石田基広『Rによるテキストマイニング入門』（森北出版）でやっているようなことをRMeCabなしでやってみたりします

以下、とくに読む必要はない文章です。

## Rでテキストマイニングするということ

### でもみんなPythonでやってる気がする

実際のところ、自分でコードを書きながら自然言語処理の真似事をするならPythonのほうが便利なような気もします。テキストを形態素解析する場面だけ見ても、Pythonには[SudachiPy](https://github.com/WorksApplications/SudachiPy)や[janome](https://mocobeta.github.io/janome/)といった選択肢がある一方で、RにはRコンソールからのみで導入が完了する形態素解析の手段が（少なくともCRANには）ありません。

自然言語処理をやる言語としてPythonのほうがメジャーなことにはほかにもいくつかの理由というか経緯があるのでしょうが、Pythonを採用したほうがよいひとつのモチベーションとしては、テキストマイニングして得た特徴量を投入してディープラーニングをしたい場合は事実上Pythonを選択するしかないというのもある気がします。一応、[{keras}](https://keras.rstudio.com/)や[{rTorch}](https://github.com/f0nzie/rTorch)というのもありますが、このあたりのパッケージを使うのはかなり趣味の領域な気がします。

### RにはRMeCabがあった、が……

そうはいっても、[{RMeCab}](https://sites.google.com/site/rmecab/)は強力なツールです。なぜかRからテキストマイニングに入ってしまった人間にとって、比較的簡単に導入できてほとんど環境を問わずすぐ使えるRMeCabは欠かせないツールだったことでしょう。

#### RMeCabのここがすごい！

- トークナイズから集計までこれひとつでこなせる関数群
- C++による実装で速度に配慮
- OS環境を問わずだいたい動く

こんな便利なRMeCabですが、Rでのテキストマイニングに慣れてきていろいろなことをやってみたくなると、個人的な感想としては「なんか使いにくいな」みたいになりがちです。というのも、RMeCabの単語などを集計する関数群は大規模なテキストを食わせると素直にクラッシュしやすい（C++とのインターフェイスで行列オブジェクトをSparseMatrixでなく通常の行列として保持しようとするためメモリを消費しやすい）こともあり、[{quanteda}](https://quanteda.io/index.html)をはじめとした便利なRパッケージ群とあわせて使うことを考えはじめると、RMeCabの役割はほとんどテキストの分かち書きだけに限定されます。

#### RMeCabのここがざんねん？

- MeCabに依存
- Not on CRAN
- メンテナビリティに不安
- `RMeCab::RMeCabC()`が正直使いにくい（返ってくるのが名前付きベクトルのリストだったり、そもそも品詞分類しかわからないところだったり）
- NEologd辞書と一部で相性が悪い（半角スペースを含む語を上手く処理できない）

とりわけメンテナビリティに不安がある点は、なんというか、本当に不安なところです。RMeCabは（MeCabともども）ほぼ「枯れた」プロダクトなのでそもそもあれですが、それでも石田基広のほかにメンテナーがいないらしいのはどうなのというのはあります。[IshidaMotohiro/RMeCab](https://github.com/IshidaMotohiro/RMeCab)は実はGitHubにパブリックリポジトリとして存在しているのですが、以下のようなコメントがソースに残されていて、大変なんだなーという印象です。

```
/*
  ver 0.99995 2016 12 27 
    全ての関数を使われる前に消し去りたい
　 　 　 　 |＼　　 　 　 　 　 ／|
　 　 　 　 |＼＼　　 　 　 ／／|
　　　　 　 : 　,>　｀´￣｀´　<　 ′
.　　　　 　 Ｖ　 　 　 　 　 　 Ｖ
.　　　　 　 i{　●　 　 　 ●　}i
　　　　 　 八　 　 ､_,_, 　 　 八 　　　わけがわからないよ 
. 　 　 　 /　个 . ＿　 ＿ . 个 ',
　　　＿/ 　 il 　 ,'　　　 '.　 li　 ',＿_
    docDF関数で全てをまかなえるから
  
*/
```

## なぜMeCabに頼り続けるか

### RでRMeCabを卒業する方法

RMeCabに依存しない自然言語処理の手段をもっておこう（ただしRでやる）と思い立ったとき、考えるべきは次の２つです。

1. Rからテキストを分かち書きする方法
2. RMeCabの集計機能を代替する方法

1については、[{RcppMeCab}](https://github.com/junhewk/RcppMeCab)や、[{reticulate}](https://rstudio.github.io/reticulate/)経由でPythonのライブラリを利用する方法などが考えられます。また、比較的フォーマルな文章を分析する場合で、形態素解析が必ずしも必要でない場合には、{quanteda}単体でもルールベースでのトークナイズがおこなえます。2については、まあ、諸々のパッケージを利用しつつ自分でコードを書くほかないでしょう。

### MeCabを利用し続けるモチベーション

形態素解析にはよくMeCabを利用しますが、{reticulate}経由でPythonのライブラリを利用するならSudachiPyなどを利用すればいいわけで、必ずしもMeCabにこだわる必要はないように思えます。それでもやはりMeCabを使いたい理由付けとして、たとえば次のような事情があるかもしれません。

- 解析速度が速い
- NEologd辞書を利用したい
- CaboCha (Not Universal Dependencies) とあわせて使いたい

個人的には、このなかでもNEologd辞書の利用はそこそこ大きなモチベーションです。Sudachiなどのアクティブなプロダクトでも辞書はよくメンテナンスされているようですが、やっぱりNEologd辞書がいいなーみたいな。

## RMeCabに依存しないテキストマイニング

### Rにちょっと慣れてきた人向け

すでに述べたように、[{quanteda}](http://quanteda.io/index.html)はMeCabなどの依存なしでトークナイズから集計まで一通りこなせます。メンテナーにKohei WatanabeとAkitaka Matsuoという日本人研究者らしい方もいて、日本語の[クイック・スタートガイド](https://quanteda.io/articles/pkgdown/quickstart_ja.html)も用意されているため、比較的とっつきやすいです。

### Rがわりとできる人向け

手前味噌ですが、いくつかそういうRパッケージを書いています。MeCabやCaboChaを自力でインストールしてパスを通せるなら、[paithiov909/pipian](https://github.com/paithiov909/pipian)がおすすめです。現在使えるものではおそらく唯一のCaboChaを扱えるRパッケージで、CaboChaをRcppバインディングではなく外部コマンドとして実行する仕様のため、あまり環境によらず簡単に導入できます。

[paithiov909/tangela](https://github.com/paithiov909/tangela)は[atilika/kuromoji](https://github.com/atilika/kuromoji)をrJava経由で扱えるようにしたパッケージです。rJava依存であるため、導入するにはJDKを自力でインストールして環境変数`JAVA_HOME`を適切に設定できる必要があります。JDKの設定ができるならMeCabなどのR外部の依存関係なしにワンライナーで導入できる点で有用です。

また、[paithiov909/conifer](https://github.com/paithiov909/conifer)では、[COTOHA API (for Developer)](https://api.ce-cotoha.com/contents/index.html) を利用することができます。サイトで登録してアクセストークンを取得したりがやや面倒ですが、企業が開発している外部のAPIを利用する点では信頼感があります。

このほかにrJava経由でMeCabを実行する[paithiov909/rjavacmecab](https://github.com/paithiov909/rjavacmecab)というのもつくっていますが、CRANにある[{RcppMeCab}](https://github.com/junhewk/RcppMeCab)に比べて導入の容易さでも速度の面でもとくにメリットはないので、これはそれほどおすすめしません。ただ、2020年6月現在にCRANからインストールできる{RcppMeCab}は同梱しているMeCabのWindows向けのダイナミックライブラリが壊れているらしく、Windows環境ではビルドに失敗します。Windows環境でこれと似たものを探すなら使ってみてもよいかもしれません。

### 自然言語処理が得意な人向け

RからUDのモデルを利用する選択肢として、[{udpipe}](https://bnosac.github.io/udpipe/en/)や[{spacyr}](https://spacyr.quanteda.io/articles/using_spacyr.html)があります。ただ、どちらについても日本語で読める「日本語のモデルを試してみた」といった情報はおそらくまったくないため、すでにUDのモデルの扱いに慣れていないと使いづらいと思います（解析した結果を単純にtibbleで持ちたい場合にはこれらをバックエンドにした[{cleanNLP}](https://github.com/statsmaths/cleanNLP)というパッケージがあり、それなりに便利に使うことはできます）。また、{spacyr}についてはPythonの実行環境を用意する必要があります。

## Have fun!!

うるせえ。いいから手を動かせ。できる仕事をしろ。
