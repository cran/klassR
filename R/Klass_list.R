#' Get base address for fetching classifications from 
#' @keywords internal
#' @return String with address
GetBaseUrl <- function(){
  "https://data.ssb.no/api/klass/v1/"
}

#' Get target ID numbers from Url
#'
#' @param x Url address
#' @keywords internal
#' @return Number
GetNums <- function(x){
  x <- as.character(x)
  gsub(".*/", "", x)
}

#' Get json file from Url
#'
#' @param url String url address
#' @keywords internal
#' @return text in json format
GetUrl <- function(url){
  hent_klass <- check_connect(url)
  if (is.null(hent_klass)){
    return(invisible(NULL))
  } else {
    klass_text <- httr::content(hent_klass, "text", encoding = "UTF-8") ## deserialisering med httr funksjonen content
    klass_data <- jsonlite::fromJSON(klass_text)
    return(klass_data)
  }
}


#' Classification list
#' Get a full list of all classifications and codelists
#'
#' @param codelists True/False for whether to include codelists. Default = FALSE
#' @param language Two letter string for the requested language output. Default is Bokmål ("nb"). Nynorsk ("nn") and English ("en").
#'
#' @return A data frame containing a full list of classifications. The data frame includes the classification name, number, family and type.
#' @export
#'
#' @examples
#' head(ListKlass(codelists = TRUE))
ListKlass <- function(codelists = FALSE, language = "nb"){
  fams <- ListFamily()$family_nr
  Klist <- data.frame(klass_name = NA, klass_nr = NA, klass_family = NA, klass_type = NA)

  # create code for including codelists and language
  code <- ifelse(codelists, "?includeCodelists=true", "")
  code <- ifelse(code == "", paste0(code, "?language=", language), 
                 paste0(code, "&language=", language))
  
  for (i in fams){
    url <- paste(GetBaseUrl(), 'classificationfamilies/', i, code, sep ="")
    dt <- data.frame(GetUrl(url)$classifications)
    nums <- as.vector(sapply(dt$X_links[, 1], GetNums))
    dt2 <- data.frame(klass_name = dt$name, klass_nr = nums, klass_family = i, klass_type = dt$classificationType)
    Klist <- rbind(Klist, dt2)
    }
  return(Klist[-1, ])
}




#' Classification family list
#' Print a list of all families and the number of classifications in each
#'
#' @param family Input family ID number to get a list of classifications in that family
#' @param codelists True/False for whether to include codelists. Default = FALSE
#' @param language Two letter string for the requested language output. Default is Bokmål ("nb"). Nynorsk ("nn") and English ("en").
#' @return dataset containing a list of families
#' @export
#'
#' @examples
#' ListFamily(family = 1)
ListFamily <- function(family=NULL, codelists = FALSE, language = "nb"){
  
  # create code for including codelists and language
  code <- ifelse(codelists, "?includeCodelists=true", "")
  code <- ifelse(code == "", paste0(code, "?language=", language), 
                 paste0(code, "&language=", language))
  
  # If no family specified then show all families
  if (is.null(family)){
    url <- paste(GetBaseUrl(), 'classificationfamilies/', code, sep="")
    dt <- data.frame(GetUrl(url)$'_embedded'$classificationFamilies)
    nums <- as.vector(sapply(dt$X_links$self$href, FUN = GetNums))
    dt2 <- data.frame(family_name = dt$name, family_nr = nums,
                      number_of_classifications = dt$numberOfClassifications)
  }
  
  # If a family is given the show classifications within that family
  if (!is.null(family)){
    family <- MakeChar(family)
    url <- paste(GetBaseUrl(), 'classificationfamilies/', family, code, sep ="")
    dt <- data.frame(GetUrl(url)$classifications)
    nums <- as.vector(sapply(dt$X_links[, 1], GetNums))
    dt2 <- data.frame(klass_name = dt$name, klass_nr = nums)
    row.names(dt2) <- NULL
  }
  return(dt2)
}



#' Search Klass
#'
#' @param query String with key word to search for
#' @param codelists True/False for whether to include codelists. Default = FALSE
#' @param size The number of results to show. Default = 20.
#'
#' @return Data frame of possible classifications that match the query
#' @export
#'
#' @examples
#' SearchKlass("occupation")
SearchKlass <- function(query, codelists = FALSE, size = 20){
  query <- as.character(query)
  code <- ifelse(codelists, "&includeCodelists=true", "")
  url <- paste(GetBaseUrl(), 'classifications/search?query=', query, code, "&size=", size, sep ="")
  dt <- data.frame(GetUrl(url)$'_embedded'$searchResults)
  nums <- as.vector(sapply(dt$X_links$self$href, GetNums))
  dt2 <- data.frame(klass_name = dt$name, klass_nr = nums)
  row.names(dt2) <- NULL
  return(dt2)
}


#' Get version number of a class given a date
#'
#' @param klass Classification number
#' @param date Date for version to be valid
#' @param family Family ID number if a list of version number for all classes is desired
#' @param klassNr True/False for whether to output classification numbers. Default = FALSE
#'
#' @return Number, vector or data frame with version numbers and calssification numbers if specified.
#' @export
#'
#' @examples
#' GetVersion(7)
GetVersion <- function(klass=NULL,  date=NULL, family = NULL, klassNr=FALSE){
  if(is.null(date)) date <- Sys.Date()
  if(is.null(family)){
    if (klassNr == TRUE) stop("To output Klass number from this function you need to input a family number")
    klass <- MakeChar(klass)
    url <- paste(GetBaseUrl(), "classifications/", klass, sep="")
    df <- as.data.frame(GetUrl(url)$versions)
    df$validTo[is.na(df$validTo)] <- as.character(Sys.Date() + 1)
    for (i in 1:nrow(df)){
      cond <- as.Date(date) >= as.Date(df$validFrom[i]) & as.Date(date) < as.Date(df$validTo[i])
      if (cond) {
        vers <- GetNums(df$`_links`$self$href[i])
      }
    }
  } else {
    family = MakeChar(family)
    fam <- ListFamily(family, codelists = TRUE)
    vers <- NULL
    klass_nr <- NULL
    for (i in fam$klass_nr){
      url <- paste(GetBaseUrl(), "classifications/", i, sep="")
      df <- as.data.frame(GetUrl(url)$versions)
      if (length(df) == 0) next() # Check if there is a valid version number
      if(is.null(df$validTo)) df$validTo <- as.character(Sys.Date() + 1)
      df$validTo[is.na(df$validTo)] <- as.character(Sys.Date() + 1)
      for (j in 1:nrow(df)){
        cond <- as.Date(date) >= as.Date(df$validFrom[j]) & as.Date(date) < as.Date(df$validTo[j])
        if (cond) {
          vers <- c(vers, GetNums(df$`_links`$self$href[j]))
          klass_nr <- c(klass_nr, i)
        }
      }
    }
    if(klassNr == TRUE){
      vers <- data.frame(vers, klass_nr)
    }
  }
return(vers)
}




#' Get the name of a classification version
#'
#' @param version Version number
#'
#' @return string or vector of strings with name of version
#' @export
#'
#' @examples
#' GetName("33")
GetName <- function(version){
  version <- MakeChar(version)
  vernames = NULL
  for (i in version){
    url <- paste(GetBaseUrl(), 'versions/', i, sep ="")
    vernames <- c(vernames, GetUrl(url)$name)
  }
  return(vernames)
}


#' Identify corresponding family from a classification number
#'
#' @param klass Classification number
#'
#' @return Family number
#' @export
#'
#' @examples
#' GetFamily(klass = 7)
GetFamily <- function(klass){
  klass <- MakeChar(klass)
  K <- ListKlass(codelists = TRUE)
  m <- match(klass, K$klass_nr)
  return(K$klass_family[m])
 }





#' Correspondence list
#' Print a list of correspondence tables for a given klass with source and target IDs
#'
#' @param klass Classification number
#' @param date Date for classification (format = "YYYY-mm-dd"). Default is current date
#'
#' @return Data frame with list of corrsepondence tables, source ID and target ID.
#' @export
#'
#' @examples
#' \donttest{
#' CorrespondList("7")
#' }
CorrespondList <- function(klass, date = NULL){
  cat("Finding correspondence tables ...")
  klass <- MakeChar(klass)
  if (is.null(date)) {
    date <- Sys.Date()
  }
  vers <- GetVersion(klass = klass, date = date)
  url <- paste(GetBaseUrl(), 'versions/', vers, sep ="")
  df <- GetUrl(url)
  versName <- df$name
  dt <- data.frame(df$correspondenceTables)
  fam <- GetFamily(klass = klass)
  versValid <- GetVersion(family=fam, date = date, klassNr = TRUE)
  vers_names <- GetName(versValid$vers)
  source_klass <- NULL
  target_klass <- NULL

  for (i in 1:nrow(dt)){
    m <- match(versName, c(dt$source[i], dt$target[i]))
    findName <- ifelse(m == 2, dt$source[i], dt$target[i])
    m2 <- match(findName, vers_names)
    newdate <- date
    counter = 0
    while(is.na(m2) & counter < 10){ # hvis versjonen ikke ble funnet på date søkes det tilbake i tid
      newdate <- as.character(as.Date(newdate) - 60)
      versValidold <- GetVersion(family=fam, date = newdate, klassNr = TRUE)
      vers_names <- GetName(versValidold$vers)
      m2 <- match(findName, vers_names)
      counter = counter + 1
      cat('.')
    }
    sourceTarget <- ifelse(is.na(m2), NA, as.character(versValid[m2, "klass_nr"]))
    source_klass[i] <- ifelse(m == 1, klass, sourceTarget)
    target_klass[i] <- ifelse(m == 1, sourceTarget, klass)
  }
  correspondence_table <- sapply(dt$X_links$self$href, GetNums)
  dt2 <- data.frame(correspondence_name=dt$name,
                    source_klass = source_klass,
                    target_klass = target_klass,
                    correspondence_table, stringsAsFactors=FALSE)
  row.names(dt2) <- NULL
  dt2$target_klass[dt2$source_klass == dt2$target_klass] <- NA #dropping target for tables within version

  if (any(is.na(dt2$target_klass))) message("\n\n There are correspondence tables within classification ", 
                                            klass,
                                            " (between different time points). Use the changes = TRUE option in the ApplyKlass and GetKlass functions to get these\n ")
  return(dt2)
}
