###### Build script
library(devtools)
setwd("../")
# library(Rd2roxygen)
# Rd2roxygen::Rd2roxygen("piecewiseSEM")


piecewiseSEM <- as.package("./piecewiseSEM") 
devtools::use_build_ignore(c("build.R", ".git", ".gitignore", "R/anova.R"),
                           pkg = "./piecewiseSEM")

document(piecewiseSEM) # build documentation files
#clean_vignettes(piecewiseSEM)
#build_vignettes(piecewiseSEM)
load_all(piecewiseSEM, reset=T)


#check(piecewiseSEM, cran=TRUE)
#build(piecewiseSEM, path="./piecewiseSEM/builds")
#devtools::check_built("./piecewiseSEM_2.0.tar.gz")
install(piecewiseSEM) 
#run_examples(multifunc) 

library(piecewiseSEM)
data(keeley)

mod <- psem(
  lm(rich ~ cover, data=keeley),
  lm(cover ~ firesev, data=keeley),
  lm(firesev ~ age, data=keeley),
  data = keeley
  
)

res <- residuals(mod)
anova(mod)
fisherC(mod)

mod2 <- psem(
  lm(rich ~ cover, data=keeley),
  lm(cover ~ firesev + age, data=keeley),
  lm(firesev ~ age, data=keeley),
  rich %~~% firesev,
  data = keeley
  
)

anova(mod, mod2)
