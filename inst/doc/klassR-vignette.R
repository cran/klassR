## ---- include = FALSE---------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  echo = T, 
  message = F
)
library(knitr)
library(kableExtra)
library(magrittr)
library(httptest)

root <- klassR:::GetBaseUrl()
set_redactor(function (response) {
    response %>%
        gsub_response(root, "", fixed=TRUE)
})

set_requester(function (request) {
    request %>%
        gsub_request(root, "", fixed=TRUE)
})

start_vignette("klassR-vignette")

## ---- eval=F------------------------------------------------------------------
#  install.packages("klassR")

## -----------------------------------------------------------------------------
library(klassR)

## ---- eval = F----------------------------------------------------------------
#  ListKlass()

## ---- echo = F----------------------------------------------------------------
all <- ListKlass()
row.names(all) <- NULL
kable(head(all))

## ---- eval = F----------------------------------------------------------------
#  ListKlass(codelists = TRUE)

## ---- echo = F----------------------------------------------------------------
ck <- ListKlass(codelists = TRUE)
row.names(ck) <- NULL
kable(head(ck), align = "l")%>%
  kable_styling(full_width = T)

## ---- eval = F----------------------------------------------------------------
#  SearchKlass(query = "ARENA")

## ---- echo = F----------------------------------------------------------------
kable(SearchKlass(query = "ARENA"))

## ---- eval=F------------------------------------------------------------------
#  SearchKlass(query = "ARENA", codelists = TRUE)

## ---- echo = F----------------------------------------------------------------
kable(SearchKlass(query = "ARENA", codelists = TRUE))

## ---- eval=F------------------------------------------------------------------
#  GetKlass(6)

## ---- echo=F------------------------------------------------------------------
kable(head(GetKlass(6)))

## ---- eval =F-----------------------------------------------------------------
#  GetKlass(6, output_level = 1)

## ----echo=F-------------------------------------------------------------------
kable(head(GetKlass(6, output_level = 1)))

## ---- eval = F----------------------------------------------------------------
#  GetKlass(6, output_level = 1, language = "en")

## ---- echo=F------------------------------------------------------------------
kable(head(GetKlass(6, output_level = 1, language = "en")))

## ---- eval=F------------------------------------------------------------------
#  data(klassdata)
#  head(klassdata)

## ---- echo=F------------------------------------------------------------------
data(klassdata)
kable(head(klassdata))

## ---- eval=F------------------------------------------------------------------
#  klassdata$kommune_names <- ApplyKlass(klassdata$kommune,
#                                        klass = 131)
#  head(klassdata)

## ---- echo=F, warning=F-------------------------------------------------------
klassdata$kommune_names <- ApplyKlass(klassdata$kommune, 
                                      klass = 131,
                                      date="2016-01-01")
kable(head(klassdata))

## ---- eval=F------------------------------------------------------------------
#  GetKlass(106, date = "2019-01-01")

## ---- echo=F------------------------------------------------------------------
kable(GetKlass(106, date = "2019-01-01"))

## ---- eval=F------------------------------------------------------------------
#  GetKlass(106, date = "2020-01-01")

## ---- echo=F------------------------------------------------------------------
kable(GetKlass(106, date = "2020-01-01"))

## ----eval=F-------------------------------------------------------------------
#  GetKlass(106, date = c("2019-01-01", "2020-01-01"))
#  

## ---- echo=F------------------------------------------------------------------
kable(GetKlass(106, date = c("2018-01-01", "2020-01-01")))


## ---- eval =F-----------------------------------------------------------------
#  GetKlass(106,
#           date = c("2020-01-01", "2019-01-01"),
#           correspond = TRUE)

## ---- echo=F------------------------------------------------------------------
kable(GetKlass(106, date = c("2020-01-01", "2019-01-01"), 
                    correspond = TRUE))

## ---- eval=F------------------------------------------------------------------
#  GetKlass(131, correspond = 106)

## ---- echo=F------------------------------------------------------------------
tt <- GetKlass(106, correspond = 131)
navn <- names(tt)
tt <- tt[, c(3,4,1,2)]
names(tt) <- navn
kable(head(tt))

## ---- eval =F-----------------------------------------------------------------
#  klassdata$region <- ApplyKlass(klassdata$kommune,
#                                 klass = 131,
#                                 correspond = 106,
#                                 date = "2016-01-01")
#  klassdata

## ---- echo=F------------------------------------------------------------------
tt <- GetKlass(106, correspond = 131, date = "2016-01-01")
navn <- names(tt)
tt <- tt[, c(3,4,1,2)]
names(tt) <- navn

m <- match(klassdata$kommune, tt$sourceCode)

klassdata$region <- tt$targetName[m] 
kable(head(klassdata))

## ---- include=FALSE-----------------------------------------------------------
end_vignette()

