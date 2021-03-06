---
title: このサイトについて（ポエム）
author: paithiov909
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

自然言語処理をやる言語としてPythonのほうがメジャーなことにはほかにもいくつかの理由というか経緯があるのでしょうが、Pythonを採用したほうがよいひとつのモチベーションとしては、テキストマイニングして得た特徴量を投入してディープラーニングをしたい場合は事実上Pythonを選択するしかないというのもある気がします。一応、[{keras}](https://keras.rstudio.com/)や[{torch}](https://github.com/mlverse/torch)というのもありますが、このあたりのパッケージを使うのはかなり趣味の領域な気がします。

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

RからUDのモデルを利用する選択肢として、[{udpipe}](https://bnosac.github.io/udpipe/en/)や[{spacyr}](https://spacyr.quanteda.io/articles/using_spacyr.html)があります。ただ、どちらについても日本語で読める「日本語のモデルを試してみた」といった情報はおそらくまったくないため、すでにUDのモデルの扱いに慣れていないと使いづらいと思います（解析した結果を単純にtibbleで持ちたい場合には{udpipe}をバックエンドにした[{cleanNLP}](https://github.com/statsmaths/cleanNLP)というパッケージがあり、それなりに便利に使うことはできます）。また、{spacyr}についてはPythonの実行環境を用意する必要があります。

## 分析プロセスの設計

### テキストを分析して何がしたいのか

入門的な本だと「テキストマイニングとは何か」みたいな話から入るような気がします。ここではとくに入門的なあれをめざしてはいませんが、しかし、すこし考えてみましょう。テキストマイニングとはなんでしょうか。

自然言語処理というのは、まあいろいろと思想はあるでしょうが、総じて「テキストを機械的に処理してごにょごにょする」技術のことだと思います。自然言語処理界隈の論文などを眺めていると、その範囲はわりと広くて、音声処理だったり対話文生成だったりも含まれる印象です。そのなかでもテキストマイニングというと、「テキストから特徴量をつくって何かやる」みたいな部分にフォーカスしてくるのではないでしょうか。

素人考えですが、テキストマイニングとはしたがってデータ分析のことです。そのため、前提としてテキストを分析して何がしたいのか（＝何ができるのか）を見通しよくしておくと、嬉しいことが多い気がします。

### CRISP-DM

CRISP-DM ([Cross-Industry Standard Process for Data Mining](https://en.wikipedia.org/wiki/Cross-industry_standard_process_for_data_mining)) は、IBMを中心としたコンソーシアムが提案したデータマイニングのための標準プロセスです。これはデータ分析をビジネスに活かすことを念頭においてつくられた「課題ドリブン」なプロセスであるため、場合によってはそのまま採用できないかもしれませんが、こうした標準プロセスを押さえておくことは分析プロセスを設計するうえで有用だと思います。

CRISP-DMは以下の6つの段階（phases）を行ったり来たりすることで進められていきます。

- Business Understanding
- Data Understanding
- Data Preparation
- Modeling
- Evaluation
- Deployment

それぞれの段階は次に挙げるようなタスクに分解されます ([*The CRISP-DM User Guide*](http://lyle.smu.edu/~mhd/8331f03/crisp.pdf) より抜粋)。

#### Business Understanding

- Determine Business Objectives (ビジネスの課題を把握する)
- Situation Assessment (データ分析に利用できる資源を確認し、分析をおこなった場合に予想される効果を評価する)
- Determine Data Mining Goal (データマイニングによって達成したいことを決定する)
- Produce Project Plan (達成したいことをやるために採りうる手法を確認する)

#### Data Understanding

- Collect Initial Data
- Describe Data
- Explore Data
- Verify Data Quality

#### Data Preparation

- Select Data
- Clean Data
- Construct Data
- Integrate Data
- Format Data

#### Modeling

- Select Modeling Technique
- Generate Test Design
- Build Model
- Assess Model

#### Evaluation

- Evaluate Results
- Review Process
- Determine Next Steps

#### Deployment

- Plan Deployment
- Plan Monitoring and Maintenance
- Produce Final Report
- Review Project

### テキストマイニングでできること

CRISP-DMはデータ分析を通じて達成したいことから分析をスタートしていく、ある意味でトップダウン的なプロセスですが、そうはいってもデータからの知見の発掘はそんなにトップダウン一直線にはうまくいかないものです。いわばボトムアップ的に、段階を「行ったり来たり」しながら分析を進めるためには、データ分析でとれるカードをなんとなく把握しておく必要があります。

これも素人考えですが、私たちがデータ分析でとれるカードってだいたい次の４つくらいのものです（文書集合が時系列としてもてるようなデータだと異常検知などの応用もありそうですが）。

- モデルをつくって何かの回帰をする
- モデルをつくって何かの分類をする
- グループに分けて違いを評価する（教師なしの分類、検定など）
- ルールマイニング

逆に、これらの落としどころに持ち込むための特徴量をどうにかして作るというのがテキストマイニングの大部分をしめるように思います。そして、それらの特徴量は基本的に何かを数えた**頻度**または**比率**とそれらを変換したものだと思っておくとすっきりします。数を数える「何か」というのは、たとえば**語**だったり**品詞**だったり、それらの**Ngram**だったり、その他のタグ付けされた情報だったりします。

### テキストマイニングの流れ

イメージ的にはこんな感じです。

1. 分析したいテキストをいっぱい集める
  - 分析して何がしたいか考える
  - そのためにつくるべき特徴量を考える
2. 特徴量をつくる
  - テキストの前処理
  - トークナイズ
  - 集計
  - 特徴量の変換や補完
3. 分析する
  - 特徴量をつかってごにょごにょする
  - 得られた結果を評価する
4. （必要に応じて）得られた知見を活かす

## Have fun!!

うるせえ。いいから手を動かせ。できる仕事をしろ。

