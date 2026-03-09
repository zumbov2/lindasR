#' Retrieve triples for a given LINDAS resource
#'
#' \code{get_resource} retrieves all triples for a given subject URI from LINDAS.
#' If the object is a literal, its language tag is returned in an additional
#' column. By default, multilingual literals are reduced according to the
#' preferred language order given in \code{lang_pref}.
#'
#' @importFrom dplyr group_by summarise first
#' @importFrom magrittr %>%
#' @importFrom stats na.omit
#'
#' @param uri Resource URI.
#' @param lang_pref Preferred order of language codes used to resolve
#'   multilingual literals. Supported language codes typically include
#'   \code{"de"} (German), \code{"fr"} (French), \code{"it"} (Italian),
#'   \code{"rm"} (Romansh), and \code{"en"} (English).
#'
#'   If a character vector is supplied, literals sharing the same predicate
#'   are reduced to a single value according to the order specified in
#'   \code{lang_pref}. The first available value in the preferred language
#'   order is selected. If none of the preferred languages are available,
#'   the first non-missing value is returned.
#'
#'   If \code{NULL} is supplied, all language-tagged values returned by the
#'   SPARQL endpoint are kept.
#'
#' @return A tibble with subject, predicate, object, object language, and
#'   object datatype. If \code{lang_pref} is not \code{NULL}, one preferred
#'   literal value per predicate is returned where applicable. Otherwise, all
#'   language versions are retained.
#' @export
get_resource <- function(uri, lang_pref = c("en", "de", "fr", "it", "rm")) {

  if (!nzchar(uri)) stop("`uri` must not be empty.")

  query <- paste(
    "SELECT ?s ?p ?o (LANG(?o) AS ?o_lang) (DATATYPE(?o) AS ?o_datatype)",
    "WHERE {",
    sprintf("  VALUES ?s { <%s> }", uri),
    "  ?s ?p ?o .",
    "}",
    "ORDER BY ?p ?o",
    sep = "\n"
  )

  res <- query_lindas(query)

  if (!is.null(lang_pref)) {
    res <-
      res %>%
      dplyr::group_by(.data$s, .data$p) %>%
      dplyr::summarise(
        o = pick_pref(.data$o, .data$o_lang, lang_pref),
        o_lang = pick_pref(.data$o_lang, .data$o_lang, lang_pref),
        o_datatype = dplyr::first(stats::na.omit(.data$o_datatype)),
        .groups = "drop"
      )
  }

  res
}
