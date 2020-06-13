---
title: 文体的特徴にもとづく青空文庫の作品の著者分類
tags: R 自然言語処理 NLP
author: paithiov909
slide: false
---

## この記事でやること

ちょっとテキストマイニングを試してみたいというときに、青空文庫は便利な資源です。自然言語処理のための大規模なコーパスは他にも公開されていますが、こうしたコーパスは、ちょっとテキストマイニングを試してみたいだけのときに利用するには巨大すぎて扱いにくいでしょう。その点、青空文庫のテキストは個別にダウンロードできるので、目的にあわせてスケーラブルに使うことができます。

[{tangela}](https://qiita.com/paithiov909/items/27fe2def6e8d15261519)では青空文庫のテキストファイルを手軽に利用するための機能を提供しています。この記事では青空文庫から5人の作家の作品の一部をダウンロードし、それらの作品の文体的特徴量を求めたうえで、{caret}パッケージを使って著者分類をおこなってみます。

## 使用するパッケージ

使用する主なパッケージを読み込んでおきます。

```R
library(ggbiplot)
library(tidyverse)
library(feather)
library(tangela)
library(furrr)
library(doParallel)
library(caret)
```

このうち{ggbiplot}はCRANにはないパッケージであるため、使用する場合は`devtools::install_github("vqv/ggbiplot")`で入れておく必要があります。また、この{ggbiplot}パッケージは{plyr}を読み込むため、一部の関数のコンフリクトを避けるために必ず{dplyr} (tidyverse) よりも先に読み込みます。

## 設定

{tangela}のサーバーを立ち上げます。また、{furrr}の並列処理に必要な設定をします。

```R
tangela::start_tangela(dotenv = file.path("./dotenv.env"))
plan(multiprocess)
```

なお、この記事では以下のようなdotenv.envファイルを渡しています。

```{dotenv.env}
HOST=127.0.0.8
PORT=3033
LIMIT=40
CLUSTER=1
```

次に、青空文庫からテキストファイルをダウンロードした際にファイルを保存するディレクトリを作成しておきます。また、後で使うcharacter vectorsの2-gramを返す関数をここでつくっておきます。

```R
dir.create("cache")
bigram <- tangela::ngram_tokenizer(2, locale = "UTF-8")
```

`tangela::ngram_tokenizer()`は、character vectorsを引数として与えるとcharacterのn-gramを返す関数を返します。たとえば、ここで宣言した`bigram()`関数に`c("a", "b", "c", "d", "e")`を与えると以下のように値を返します。

```R
> bigram(c("a", "b", "c", "d", "e"))
[1] "a b" "b c" "c d" "d e"
```

## テキストデータの準備

{tangela}は青空文庫で公開されているテキストのメタデータ（[詳細はこちらを読んでください](https://qiita.com/ksato9700/items/48fd0eba67316d58b9d6#%E5%85%83%E3%81%AB%E3%81%AA%E3%82%8B%E3%83%87%E3%83%BC%E3%82%BF)）を組み込みデータセット`AozoraBunkoSnapshot`として提供しています。また、青空文庫のzipファイルのURLを指定してテキストファイルを保存する関数`tangela::aozora()`を提供しているため、これらを組み合わせることでRらしいスタイルで必要なテキストファイルをダウンロードすることができます。

この記事では芥川龍之介・夏目漱石・宮沢賢治・森鴎外・夢野久作の5人の作品の一部をダウンロードしてみることにしましょう。まず、`tangela::aozora()`に渡すための保存すべきzipファイルのURLリストをつくります。注意すべき点として、`AozoraBunkoSnapshot`では作家名は「姓」と「名」というカラムに分かれているので、そのままではフルネームでfilterすることはできません。ここではとりあえず「姓」だけでfilterしておきます。この時点で579件の作品のリストができるはずですが、これらの作品をすべてダウンロードして{tangela}で形態素解析しようとすると相応の時間がかかってしまうため、ここでは`dplyr::sample_frac(0.3)`してすべての作品のうち3割だけを使うことにします。

```R
data(AozoraBunkoSnapshot)

tbl <- list("芥川", "夏目", "宮沢", "森", "夢野") %>%
    lapply(function(x){
        AozoraBunkoSnapshot %>%
            filter(str_detect(姓, x)) %>%
            filter(str_detect(文字遣い種別, "新字新仮名")) %>%
            select(作品名, テキストファイルURL, 姓, 名) %>%
            return()
    }) %>%
    map_dfr(~ .x) %>%
    mutate(name = paste0(姓, 名)) %>%
    rename(title = 作品名, url = テキストファイルURL) %>%
    select(title, name, url) %>%
    sample_frac(0.3)
```

このリストは作家の「姓」だけでfilterしてつくったため、森鴎外以外の「森」姓の作家や、芥川龍之介が「芥川竜之介」名義で出した作品などが混じっています。これらを取り除くために、その名義で10件以上の作品が公開されている作家だけに絞り込みます。`dplyr::sample_frac()`でサンプリングしているので必ずしも再現性はありませんが、これでおそらくは意図した5人の作家だけが残ると思われます。さらに、それらの作品のうちでも青空文庫でzipファイルを提供していない (ダウンロードURLがNAである) 場合があるため、`dplyr::drop_na()`してこれらのケースを取り除きます。

```R
authors <- tbl %>%
    group_by(name) %>%
    count() %>%
    filter(n > 10)

tbl <- tbl %>%
    right_join(authors, by = c("name")) %>%
    drop_na()
```

筆者が実行した環境ではこの時点で169件の作品が抽出され、その内訳は夏目漱石が17件、森鴎外が24件、宮沢賢治が34件、夢野久作が37件、芥川竜之介が57件でした。この作品リストは実際には新字新仮名であっても文語調の文章が混じっていたり、一部に小説ではない文章が含まれていたり、文字数ベースにしてもかなりの偏りがあったりと、まだ著者分類をおこなううえで考慮すべき点が複数あります。しかし、話を簡単にするためにここではこのまま扱うことにして、テキストをダウンロードして保存していきます。

```R
tbl$path <- furrr::future_map(tbl$url, ~ tangela::aozora(.)) %>% unlist()
tbl$content <- map(tbl$path, ~ read_lines(.)) %>%
    map(~ purrr::discard(., . == "")) %>%
    map(~ paste(., collapse = " ")) %>%
    unlist()
tbl$n <- as.factor(tbl$n)

write_feather(tbl, "aozora.feather")
```

ここまででテキストをダウンロードして保存することができたので、いよいよ{tangela}で形態素解析をします。以下では、文字列を正規化したあと、`purrr::imap_dfr()`を通して`tangela::tokenize()`に文章を渡しています。次のような構造のtibbleができるはずです。

| did  | surface_form | pos  |
| ---- | ------------ | ---- |
| 1    | 文壇         | 名詞 |
| 1    | の           | 助詞 |



```R
contents <- tbl$content %>%
    map(function(x){
        x %>%
            str_replace_all(regex("[’]"), "\'") %>%
            str_replace_all(regex("[”]"), "\"") %>%
            str_replace_all(regex("[˗֊‐‑‒–⁃⁻₋−]+"), "-") %>%
            str_replace_all(regex("[﹣－ｰ—―─━ー]+"), "ー") %>%
            str_remove_all(regex("[~∼∾〜〰～]")) %>%
            str_remove_all("[:punct:]") %>%
            str_remove_all("[:blank:]") %>%
            str_remove_all("[:cntrl:]") %>%
            Nippon::zen2han() %>%
            return()
    }) %>%
    imap_dfr(function(str, itr){
        tangela::tokenize(list(str), host = "127.0.0.8", port = 3033) %>%
            purrr::flatten() %>%
            map_dfr(function(x){
                tibble(
                    did = itr,
                    surface_form = x$surface_form, 
                    pos = x$pos
                )
            }) %>%
            return()
    })
    
write_feather(contents, "contents.feather")

```

### {tangela}での並列処理について

実のところ、{tangela}はまとまった分量の文章を処理するのには不向きです。kuromoji.jsでの処理がボトルネックになって、ある程度以上のまとまった分量を処理しようとすると{RMeCab}などに比べて相当の時間を要します。たとえば、上記の条件で169件のテキストファイル (およそ6.7MBほどになる) を形態素解析した場合でさえも、{RMeCab}と比べるとちょっと信じられないくらいの時間がかかってしまいます。

バックエンドはdotenvを通じて渡したCLUSTERの数だけ`cluster.fork()`するようになっているので、子プロセスを増やしつつ`furrr::future_map()`などで並列化すればある程度は解析速度が向上することが期待されます。しかし、そうする場合でもすこし注意が必要です。まず、kuromoji.jsのトークナイザは辞書をメモリ上に保持するため、とくにNEologd辞書のような大きな辞書ファイルを使う場合にはかなりのリソースを消費します。また、当然ですが、子プロセスを増やしても個々の文書の解析速度は上がりません。kuromoji.jsの特性としてNEologd辞書のような大きな辞書ファイルを使った場合はそのぶんだけ解析に時間を要するようになるため、並列化していても使用する辞書によっては相変わらず解析に時間がかかることがあります。

また、`tangela::start_tangela()`はデフォルトでnodeコマンドに`"--optimize_for_size --max_old_space_size=460 --gc_interval=100"`というオプションを渡すため、より効果のある並列化をおこなうには自分の環境にあわせてnodeコマンドに渡すオプションを書き換えることが推奨されます (使えるリソースが少ないと解析する文書のサイズが大きいとき子プロセスが死んでしまいます) 。

## 特徴量エンジニアリング

分類に用いるための特徴量をつくっていきます。

```R
aozora <- read_feather("aozora.feather")
contents <- read_feather("contents.feather")

`%without%` <- purrr::negate(`%in%`)

```

ここでは文体的特徴をもとに著者分類をおこなってみたいので、作品の文体を反映していると考えられる特徴量として以下の5種類を使うことにします。

- 機能語の比率
- 名詞率
- MVR
- VNR
- 品詞のNgramの比率

### 機能語の比率

内容語ではない語を機能語といいます。[内容語](https://kotobank.jp/word/%E5%86%85%E5%AE%B9%E8%AA%9E-345484)とは「名詞・動詞・形容詞など、文法的な機能はほとんどもたず、主として語彙的意味を表す語」とされていますが、たぶんですがこれは国語学の術語であり、その品詞レベルでの範囲は必ずしも明確ではありません (たとえば連体詞を考えた場合、「大きな」や「小さな」などは語彙的意味を表しているため内容語だと考えられますが、「こういう」や「あんな」など意味の解釈のために飽和 (saturation) が必要な連体詞では機能語とされてしまうように思われます) 。

そこで、ここでは便宜的に内容語を「名詞・動詞・形容詞・副詞の集合」としておき、IPA辞書の品詞分類においてそれ以外にあたる品詞はすべて機能語ということにしておきます。なお、IPA辞書では形容動詞は品詞分類として存在しておらず、たとえば「きれいだ」などは「きれい (名詞)」+「だ (助動詞)」として解析されます。このため、形容動詞はあえて内容語に含んでいません。

各作品における機能語の比率は以下のようにして計算します。

```R
not_content_ratio <- sapply(1:nrow(aozora), function(id){
    not_content_words <- contents %>%
        filter(did == id) %>%
        filter(pos %without% c("名詞", "形容詞", "動詞", "副詞")) %>%
        group_by(pos) %>%
        count()
    whole_words <- contents %>%
        filter(did == id) %>%
        group_by(pos) %>%
        count()

    not_content <- sum(not_content_words$n)
    whole <- sum(whole_words$n)

    return(not_content / whole)
})

```

### 名詞率

名詞率は文書内の名詞の比率です。分母は文書内のすべての語である場合と文書内の語のうち自立語だけを用いる場合とが散見されるようですが、ここでは自立語だけを用いることにします。自立語というのは[橋本進吉](https://kotobank.jp/word/%E6%A9%8B%E6%9C%AC%E9%80%B2%E5%90%89-114238#E3.83.96.E3.83.AA.E3.82.BF.E3.83.8B.E3.82.AB.E5.9B.BD.E9.9A.9B.E5.A4.A7.E7.99.BE.E7.A7.91.E4.BA.8B.E5.85.B8.20.E5.B0.8F.E9.A0.85.E7.9B.AE.E4.BA.8B.E5.85.B8)または[服部四郎](https://kotobank.jp/word/%E6%9C%8D%E9%83%A8%E5%9B%9B%E9%83%8E-115204#E3.83.96.E3.83.AA.E3.82.BF.E3.83.8B.E3.82.AB.E5.9B.BD.E9.9A.9B.E5.A4.A7.E7.99.BE.E7.A7.91.E4.BA.8B.E5.85.B8.20.E5.B0.8F.E9.A0.85.E7.9B.AE.E4.BA.8B.E5.85.B8)が導入した術語で、簡単にいうと助詞と助動詞を除くすべての品詞の集合です。

各作品における名詞率は以下のようにして計算します。

```R
noun_ratio <- sapply(1:nrow(aozora), function(id){
    content_words <- contents %>%
        filter(did == id) %>%
        filter(pos %without% c("助詞", "助動詞")) %>%
        group_by(pos) %>%
        count()
    whole <- sum(content_words$n)
    noun <- content_words %>%
        filter(pos == "名詞") %>%
        pull(n)
    
    return(noun / whole)
})

```

### MVR

[MVR](http://langstat.hatenablog.com/entry/20140913/1410534000#f-4f4ac813)は[樺島・寿岳 (1965)](http://www.amazon.co.jp/%E6%96%87%E4%BD%93%E3%81%AE%E7%A7%91%E5%AD%A6-1965%E5%B9%B4-%E6%A8%BA%E5%B3%B6-%E5%BF%A0%E5%A4%AB/dp/B000JABROY) が提案した文体的な指標で、相類 (形容詞・形容動詞・副詞・連体詞) の比率を用類 (動詞) の比率で割ったもの (正確にはこれに100を乗じたもの) です。稀によく出てきます。

```R
mvr <- sapply(1:nrow(aozora), function(id){
    d <- contents %>%
        filter(did == id)
    verb_count <- d %>%
        filter(pos == c("動詞")) %>%
        nrow()
    adj_count <- d %>%
        filter(pos %in% c("形容詞", "副詞", "連体詞")) %>%
        nrow()        

    return(adj_count / verb_count)
})

```

### VNR

VNRは動詞の数を名詞の数で割ったものです。[一般に](http://www2.hak.hokkyodai.ac.jp/fukuda/lecture/SocialLinguistics/html/01introduction.html)「動詞率が高いとダイナミックな、事件展開型の文章となる」とされています。

```R
vnr <- sapply(1:nrow(aozora), function(id){
    d <- contents %>%
        filter(did == id)
    noun_count <-  d %>%
        filter(pos == c("名詞")) %>%
        nrow()
    verb_count <- d %>%
        filter(pos == c("動詞")) %>%
        nrow()
    
    return(verb_count / noun_count)
})

```

### 品詞のNgramの比率

Ngramを品詞分類でグルーピングして集計したものです。ここでは2-gramをもとに品詞分類のペアをつくり、それらを集計して、品詞分類ペアの各文書内での比率を求めています。ただし、品詞分類ペアはすべての文書であらゆる組み合わせが出現するわけではなく、相対的に出現頻度が少なくなりがちな品詞分類ペアは文書が短いほどに出現しにくい傾向があります。今回用いている文書集合は個々の作品の長さを統制していないため、確認できた品詞分類ペアの組み合わせをすべて特徴量として採用すると、充分に長い作品以外では欠損値が発生してしまいます。この事態を避けるため、すべての文書で出現している品詞分類ペアのみを特徴量として採用し、それ以外はあらかじめ取り除いています。

```R
pos_ngram <- map(1:nrow(aozora), function(id){
    d <- contents %>%
        filter(did == id)
    stats <- tibble(
        bigram = bigram(d$pos)
    ) %>%
        group_by(bigram) %>%
        count()
    colsum <- stats %>%
        pull(n) %>%
        sum()
    stats %>%
        mutate(ratio = n / colsum) %>%
        select(-n) %>%
        return()
}) %>%
    reduce(~ full_join(.x, .y, by = "bigram"))

pos_ngram <- pos_ngram %>%
    drop_na() %>%
    column_to_rownames("bigram") %>%
    t() %>%
    as_tibble()

```

## 著者分類

### データの結合

筆者が実行した環境では14個の文体的特徴量が用意できました。これらをあわせて著者分類に使うデータにします。

```R
data <- aozora %>%
    select(n) %>%
    bind_cols(pos_ngram) %>%
    bind_cols(
        tibble(
            noun_ratio = noun_ratio,
            mvr = mvr,
            vnr = vnr,
            not_content_ratio = not_content_ratio
        )
    )

```

### 図示

なお、この段階でPCAとMDSで2次元に図示すると以下のようになります。

#### PCA

![biplot](https://t29.pixhost.to/thumbs/425/101923097_biplot.png)

#### MDS

![mds](https://t29.pixhost.to/thumbs/425/101923098_mds.png)

### データの分割

データを訓練用データとテスト用データに分割します。筆者が実行した環境では夏目漱石の作品がぜんぶで17件と他の作家の作品よりも少なかったため、`caret::trainControl()`でアンダーサンプリングをおこなう設定をしています。

```R
set.seed(114514)
index <- createDataPartition(data$n, p = 0.5, list = FALSE)
train <- data[index, ]
test <- data[-index, ]

fitControl <- trainControl(method = "cv", number = 5, preProcOptions = list("center", "scale"), sampling = "down")

```

### モデルの訓練と分類

モデルを訓練して、実際に分類してみます。

```R
cl <- makePSOCKcluster(parallel::detectCores(logical = FALSE))
registerDoParallel(cl)

fit <- train(
    n ~ (.)^2,
    data = train,
    method = "xgbTree",
    trControl = fitControl,
    tuneLength = 3
)

stopCluster(cl)

pred <- predict(fit, test)
confusionMatrix(pred, test$n)

```

参考として、筆者の実行した環境で"pcaNNet", "ranger", "xgbTree", "xgbDART"の4種類のmethodを試した結果を以下に貼っておきます。文書集合内での作品数を`as.factor()`したので、夏目漱石がClass: 17、森鴎外がClass: 24、宮沢賢治がClass: 34、夢野久作がClass: 37、芥川竜之介がClass: 57です。

ちなみに"pcaNNet"はPCAでfeature extractionしつつやるニューラルネット、"ranger"はランダムフォレストです。"xgbTree"と"xgbDART"は{xgboost}による勾配ブースティング木で、"xgbDART"のほうはboosterに[DART (Dropouts meet Multiple Additive Regression Trees)](https://www.jmlr.org/proceedings/papers/v38/korlakaivinayak15.pdf) を使ったものであり、"xgbTree"よりもオーバーフィッティングしにくくなっています。

#### pcaNNet

```R
> confusionMatrix(pred, test$n)
Confusion Matrix and Statistics

          Reference
Prediction 17 24 34 37 57
        17  2  3  0  7  1
        24  3  9  1  0  2
        34  0  0 11  2  4
        37  0  0  0  7  0
        57  3  0  5  2 21

Overall Statistics
                                         
               Accuracy : 0.6024         
                 95% CI : (0.489, 0.7083)
    No Information Rate : 0.3373         
    P-Value [Acc > NIR] : 7.072e-07      
                                         
                  Kappa : 0.4853         
 Mcnemar's Test P-Value : NA             

Statistics by Class:

                     Class: 17 Class: 24 Class: 34 Class: 37
Sensitivity            0.25000    0.7500    0.6471   0.38889
Specificity            0.85333    0.9155    0.9091   1.00000
Pos Pred Value         0.15385    0.6000    0.6471   1.00000
Neg Pred Value         0.91429    0.9559    0.9091   0.85526
Prevalence             0.09639    0.1446    0.2048   0.21687
Detection Rate         0.02410    0.1084    0.1325   0.08434
Detection Prevalence   0.15663    0.1807    0.2048   0.08434
Balanced Accuracy      0.55167    0.8327    0.7781   0.69444
                     Class: 57
Sensitivity             0.7500
Specificity             0.8182
Pos Pred Value          0.6774
Neg Pred Value          0.8654
Prevalence              0.3373
Detection Rate          0.2530
Detection Prevalence    0.3735
Balanced Accuracy       0.7841

```

#### ranger

```R
> confusionMatrix(pred, test$n)
Confusion Matrix and Statistics

          Reference
Prediction 17 24 34 37 57
        17  2  3  0  2  1
        24  1  9  1  0  1
        34  0  0 13  3  6
        37  2  0  1 10  0
        57  3  0  2  3 20

Overall Statistics
                                         
               Accuracy : 0.6506         
                 95% CI : (0.5381, 0.752)
    No Information Rate : 0.3373         
    P-Value [Acc > NIR] : 5.659e-09      
                                         
                  Kappa : 0.5449         
 Mcnemar's Test P-Value : NA             

Statistics by Class:

                     Class: 17 Class: 24 Class: 34 Class: 37
Sensitivity            0.25000    0.7500    0.7647    0.5556
Specificity            0.92000    0.9577    0.8636    0.9538
Pos Pred Value         0.25000    0.7500    0.5909    0.7692
Neg Pred Value         0.92000    0.9577    0.9344    0.8857
Prevalence             0.09639    0.1446    0.2048    0.2169
Detection Rate         0.02410    0.1084    0.1566    0.1205
Detection Prevalence   0.09639    0.1446    0.2651    0.1566
Balanced Accuracy      0.58500    0.8539    0.8142    0.7547
                     Class: 57
Sensitivity             0.7143
Specificity             0.8545
Pos Pred Value          0.7143
Neg Pred Value          0.8545
Prevalence              0.3373
Detection Rate          0.2410
Detection Prevalence    0.3373
Balanced Accuracy       0.7844

```

#### xgbTree

```R
> confusionMatrix(pred, test$n)
Confusion Matrix and Statistics

          Reference
Prediction 17 24 34 37 57
        17  3  2  0  4  3
        24  0 10  0  1  2
        34  2  0 13  0  5
        37  0  0  2 11  1
        57  3  0  2  2 17

Overall Statistics
                                         
               Accuracy : 0.6506         
                 95% CI : (0.5381, 0.752)
    No Information Rate : 0.3373         
    P-Value [Acc > NIR] : 5.659e-09      
                                         
                  Kappa : 0.552          
 Mcnemar's Test P-Value : NA             

Statistics by Class:

                     Class: 17 Class: 24 Class: 34 Class: 37
Sensitivity            0.37500    0.8333    0.7647    0.6111
Specificity            0.88000    0.9577    0.8939    0.9538
Pos Pred Value         0.25000    0.7692    0.6500    0.7857
Neg Pred Value         0.92958    0.9714    0.9365    0.8986
Prevalence             0.09639    0.1446    0.2048    0.2169
Detection Rate         0.03614    0.1205    0.1566    0.1325
Detection Prevalence   0.14458    0.1566    0.2410    0.1687
Balanced Accuracy      0.62750    0.8955    0.8293    0.7825
                     Class: 57
Sensitivity             0.6071
Specificity             0.8727
Pos Pred Value          0.7083
Neg Pred Value          0.8136
Prevalence              0.3373
Detection Rate          0.2048
Detection Prevalence    0.2892
Balanced Accuracy       0.7399

```

#### xgbDART

```R
> confusionMatrix(pred, test$n)
Confusion Matrix and Statistics

          Reference
Prediction 17 24 34 37 57
        17  3  1  0  4  3
        24  0 10  2  2  3
        34  0  0 12  3  6
        37  1  0  3  8  2
        57  4  1  0  1 14

Overall Statistics
                                          
               Accuracy : 0.5663          
                 95% CI : (0.4529, 0.6747)
    No Information Rate : 0.3373          
    P-Value [Acc > NIR] : 1.588e-05       
                                          
                  Kappa : 0.4495          
 Mcnemar's Test P-Value : NA              

Statistics by Class:

                     Class: 17 Class: 24 Class: 34 Class: 37
Sensitivity            0.37500    0.8333    0.7059   0.44444
Specificity            0.89333    0.9014    0.8636   0.90769
Pos Pred Value         0.27273    0.5882    0.5714   0.57143
Neg Pred Value         0.93056    0.9697    0.9194   0.85507
Prevalence             0.09639    0.1446    0.2048   0.21687
Detection Rate         0.03614    0.1205    0.1446   0.09639
Detection Prevalence   0.13253    0.2048    0.2530   0.16867
Balanced Accuracy      0.63417    0.8674    0.7848   0.67607
                     Class: 57
Sensitivity             0.5000
Specificity             0.8909
Pos Pred Value          0.7000
Neg Pred Value          0.7778
Prevalence              0.3373
Detection Rate          0.1687
Detection Prevalence    0.2410
Balanced Accuracy       0.6955

```

## まとめ

この記事では青空文庫から5人の作家の作品の一部をダウンロードし、それらの作品の文体的特徴量を求めたうえで、{caret}パッケージを使って著者分類をおこないました。筆者が実行した環境では、夏目漱石作品の誤分類が目立った以外はそれなりの精度で分類できているように見えます。夏目漱石の作品はもともとサンプル数が少なかったことを考えると妥当な結果でしょう。

