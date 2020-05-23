#### Read sources ####
cran <- read.csv("https://bit.ly/3cGgmIk", fileEncoding = "UTF-8", stringsAsFactors = FALSE)
github <- read.csv("https://bit.ly/2ZeGENQ", fileEncoding = "UTF-8", stringsAsFactors = FALSE)

#### Install packages on CRAN ####
selection <- yesno::yesno("Install packages from CRAN?")

if (selection) {
    sapply(1:nrow(cran), function(i) {
        cnd <- require(cran$package[i], character.only = TRUE)
        if (!cnd) {
            install.packages(cran$package[i])
        } else {
            detach(paste0("package:", cran$package[i]), character.only = TRUE)
        }
        invisible(cnd)
    })
}

#### Install packages on GitHub ####
selection <- yesno::yesno("Install packages from GitHub?")

if (selection) {

    Sys.setenv(MECAB_LANG = "ja") # for RcppMeCab

    sapply(1:nrow(github), function(i) {
        try(remotes::install_github(github$repository[i], force =TRUE))
        invisible(NULL)
    })
}

#### Cleaning ####
remove(cran)
remove(github)
remove(selection)

message("DONE")

