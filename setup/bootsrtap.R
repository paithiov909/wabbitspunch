#### bootsrtap envrionment ####

cranResources <- read.delim("requirements.tsv", header = FALSE, stringsAsFactors = FALSE)
gitResources <- read.delim("remotes.tsv", header = FALSE, stringsAsFactors = FALSE)

sapply(1:nrow(cranResources), function(i) {
    cnd <- require(cranResources$V1[i], character.only = TRUE)
    if (!cnd) {
		install.packages(cranResources$V1[i])
    } else {
        detach(paste0("package:", cranResources$V1[i]), character.only = TRUE)
    }
    invisible(cnd)
})

stopifnot(require("remotes"))

if(!require("yesno")) {
	install.packages("yesno")
	library("yesno")
}

selection <- yesno("Install packages from GitHub?")
if (selection) {

    Sys.setenv(MECAB_LANG = "ja")

	sapply(1:nrow(gitResources), function(i) {
		try(remotes::install_github(gitResources$V1[i], force =TRUE))
		invisible(NULL)
	})

}

remove(cranResources)
remove(gitResources)
remove(selection)

message("DONE")

