#' Retrieve objects for a given predicate of a LINDAS resource
#'
#' \code{get_objects} retrieves all objects for a given predicate of a subject
#' URI in LINDAS.
#'
#' If the objects are multilingual literals, they can be reduced according to
#' the preferred language order given in \code{lang_pref}.
#'
#' @importFrom dplyr summarise first
#' @importFrom magrittr %>%
#' @importFrom stats na.omit
#'
#' @param uri Resource URI.
#' @param predicate Predicate URI.
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
#'   object datatype.
#' @export
#'
#' @examples
#' \dontrun{
#' get_objects(
#'   "https://communication.ld.admin.ch/ofcom/srg_revenue_structure/10",
#'   "http://schema.org/name"
#' )
#' }
get_objects <- function(uri, predicate, lang_pref = c("en", "de", "fr", "it", "rm")) {

  if (!nzchar(uri)) stop("`uri` must not be empty.")
  if (!nzchar(predicate)) stop("`predicate` must not be empty.")

  query <- paste(
    "SELECT ?s ?p ?o (LANG(?o) AS ?o_lang) (DATATYPE(?o) AS ?o_datatype)",
    "WHERE {",
    sprintf("  VALUES ?s { <%s> }", uri),
    sprintf("  VALUES ?p { <%s> }", predicate),
    "  ?s ?p ?o .",
    "}",
    "ORDER BY ?o",
    sep = "\n"
  )

  res <- query_lindas(query)

  if (!is.null(lang_pref)) {
    res <-
      res %>%
      dplyr::summarise(
        s = dplyr::first(stats::na.omit(.data$s)),
        p = dplyr::first(stats::na.omit(.data$p)),
        o = pick_pref(.data$o, .data$o_lang, lang_pref),
        o_lang = pick_pref(.data$o_lang, .data$o_lang, lang_pref),
        o_datatype = dplyr::first(stats::na.omit(.data$o_datatype))
      )
  }

  res
}
