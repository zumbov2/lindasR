#' Search dataset metadata in LINDAS
#'
#' \code{search_datasets} performs a full-text search over dataset metadata in
#' LINDAS. The search is limited to dataset names and descriptions.
#'
#' Multilingual metadata can be reduced according to the preferred language
#' order given in \code{lang_pref}.
#'
#' @importFrom dplyr group_by summarise arrange first
#' @importFrom magrittr %>%
#' @importFrom stats na.omit
#'
#' @param search Search term.
#' @param lang_pref Preferred order of language codes used to resolve
#'   multilingual literals. Supported language codes typically include
#'   \code{"de"} (German), \code{"fr"} (French), \code{"it"} (Italian),
#'   \code{"rm"} (Romansh), and \code{"en"} (English).
#'
#'   If a character vector is supplied, literals belonging to the same dataset
#'   are reduced to a single value according to the order specified in
#'   \code{lang_pref}. The first available value in the preferred language
#'   order is selected. If none of the preferred languages are available, the
#'   first non-missing value is returned.
#'
#'   If \code{NULL} is supplied, all language-tagged values returned by the
#'   SPARQL endpoint are kept.
#'
#' @return A tibble containing matching dataset metadata from LINDAS.
#' @export
#'
#' @examples
#' \dontrun{
#' search_datasets("revenue")
#' search_datasets("revenue", lang_pref = NULL)
#' }
search_datasets <- function(search, lang_pref = c("en", "de", "fr", "it", "rm")) {

  search <- trimws(search)
  if (!nzchar(search)) stop("`search` must not be empty.")

  text_search_name <-
    build_text_search_clause(
      search = search,
      literal_var = "?name",
      score_var = "?score"
      )

  text_search_description <-
    build_text_search_clause(
      search = search,
      literal_var = "?description",
      score_var = "?score"
      )

  query <- paste(
    "PREFIX schema: <http://schema.org/>",
    "PREFIX rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#>",
    "PREFIX void:   <http://rdfs.org/ns/void#>",
    "PREFIX dcat:   <http://www.w3.org/ns/dcat#>",
    "",
    "SELECT DISTINCT",
    "  ?sub",
    "  ?name",
    "  (LANG(?name) AS ?name_lang)",
    "  ?description",
    "  (LANG(?description) AS ?description_lang)",
    "  ?endpoint",
    "  ?landingPage",
    "  ?contactName",
    "  (LANG(?contactName) AS ?contactName_lang)",
    "  ?dateCreated",
    "  ?datePublished",
    "  ?dateModified",
    "  ?score",
    "WHERE {",
    "  ?sub schema:name ?name .",
    "  ?sub rdf:type ?resultType .",
    "",
    "  OPTIONAL { ?sub schema:description ?description . }",
    "  OPTIONAL { ?sub void:sparqlEndpoint ?endpoint . }",
    "  OPTIONAL { ?sub dcat:landingPage ?landingPage . }",
    "  OPTIONAL { ?sub schema:contactPoint/schema:name ?contactName . }",
    "  OPTIONAL { ?sub schema:dateCreated ?dateCreated . }",
    "  OPTIONAL { ?sub schema:datePublished ?datePublished . }",
    "  OPTIONAL { ?sub schema:dateModified ?dateModified . }",
    "",
    "  {",
    paste0("    ", text_search_name),
    "  }",
    "  UNION",
    "  {",
    "    ?sub schema:description ?description .",
    paste0("    ", text_search_description),
    "  }",
    "",
    "  FILTER(?resultType IN (void:Dataset))",
    "  FILTER(NOT EXISTS { ?sub schema:expires ?x . })",
    "  FILTER(NOT EXISTS {",
    "    ?sub schema:creativeWorkStatus",
    "      <https://register.ld.admin.ch/definedTerm/CreativeWorkStatus/Draft> .",
    "  })",
    "}",
    "ORDER BY DESC(?score) ?name",
    sep = "\n"
  )

  raw <- query_lindas(query)

  if (nrow(raw) > 0) {

    if (!is.null(lang_pref)) {
      raw <-
        raw %>%
        dplyr::group_by(.data$sub) %>%
        dplyr::summarise(
          name = pick_pref(.data$name, .data$name_lang, lang_pref),
          description = pick_pref(.data$description, .data$description_lang, lang_pref),
          contactName = pick_pref(.data$contactName, .data$contactName_lang, lang_pref),
          endpoint = dplyr::first(stats::na.omit(.data$endpoint)),
          landingPage = dplyr::first(stats::na.omit(.data$landingPage)),
          dateCreated = dplyr::first(stats::na.omit(.data$dateCreated)),
          datePublished = dplyr::first(stats::na.omit(.data$datePublished)),
          dateModified = dplyr::first(stats::na.omit(.data$dateModified)),
          score = suppressWarnings(max(as.numeric(.data$score), na.rm = TRUE)),
          .groups = "drop"
        )
    }

  dplyr::arrange(raw, dplyr::desc(.data$score), .data$name)

  } else {

    return(tibble::tibble())

  }
}
