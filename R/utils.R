# Select preferred value by language order
#'
#' @param value Character vector of values.
#' @param lang Character vector of language codes corresponding to `value`.
#' @param lang_pref Preferred language order.
#' @return A single character value.
#' @noRd
pick_pref <- function(value, lang, lang_pref) {

  ord <- match(lang, lang_pref)
  ord[is.na(ord)] <- Inf

  ok <- !is.na(value)
  if (!any(ok)) return(NA_character_)

  value <- value[ok]
  ord <- ord[ok]

  value[order(ord)][1]

  }

# Escape special characters for SPARQL string literals
#'
#' @param x Character string.
#' @return Escaped character string.
#' @noRd
escape_sparql_string <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x, perl = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x
  }

# Build Stardog full-text search clause
#'
#' @param search Search string.
#' @param literal_var SPARQL variable containing the literal to search.
#' @param score_var SPARQL variable receiving the match score.
#' @return A SPARQL text search clause.
#' @noRd
build_text_search_clause <- function(search, literal_var = "?l", score_var = "?score") {

  if (!nzchar(search)) stop("`search` must not be empty.")

  sprintf(
    "(%s %s) <tag:stardog:api:property:textMatch> \"%s\" .",
    literal_var,
    score_var,
    escape_sparql_string(search)
    )

}
