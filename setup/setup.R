message("Let's set up R and other tools with installr...")

if (!require("installr")) {
	message("Downloading installr package...")
	install.packages("installr")
	library("installr")
}

installr()

