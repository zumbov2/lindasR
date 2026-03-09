#' lindasR: Interface to the Swiss Federal Linked Data Service
#'
#' Provides convenient access to the Swiss Federal Linked Data Service
#' (LINDAS) via its SPARQL endpoint.
#'
#' See the README on
#' \href{https://github.com/zumbov2/lindasR#readme}{GitHub}
#'
#' @keywords internal
#' @importFrom magrittr %>%
"_PACKAGE"

if (getRversion() >= "2.15.1") {
  utils::globalVariables(
    c(
      ".",
      "sub",
      "name", "name_lang",
      "description", "description_lang",
      "contactName", "contactName_lang",
      "endpoint", "landingPage",
      "dateCreated", "datePublished", "dateModified"
    )
  )
}