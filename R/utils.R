#' Select preferred value by language order
#'
#' @param value Character vector of values.
#' @param lang Character vector of language codes corresponding to \code{value}.
#' @param lang_pref Preferred order of language codes.
#'
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

#' Escape special characters for SPARQL string literals
#'
#' @param x A character string.
#'
#' @return An escaped character string.
#' @noRd
escape_sparql_string <- function(x) {
  x <- gsub("\\\\", "\\\\\\\\", x, perl = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x
  }

#' Build a Stardog full-text search clause
#'
#' @param search Search term as a character string.
#' @param literal_var SPARQL variable containing the literal to search.
#' @param score_var SPARQL variable receiving the relevance score.
#'
#' @return A SPARQL clause as a character string.
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

#' Retrieve cube metadata for a LINDAS dataset
#'
#' @param dataset_uri Dataset URI.
#'
#' @return A tibble with observation set and observation constraint.
#' @noRd
get_cube_metadata <- function(dataset_uri) {

  if (!nzchar(dataset_uri)) stop("`dataset_uri` must not be empty.")

  res <- get_resource(dataset_uri, lang_pref = NULL)

  tibble::tibble(
    observation_set = res$o[res$p == "https://cube.link/observationSet"][1],
    observation_constraint = res$o[res$p == "https://cube.link/observationConstraint"][1]
  )
}


#' Retrieve schema information for a LINDAS cube dataset
#'
#' \code{get_dataset_schema} retrieves the observation schema of a cube dataset
#' from its observation constraint.
#'
#' Labels are taken from the property-shape metadata, not from the path URI
#' itself.
#'
#' @importFrom dplyr group_by summarise arrange
#' @importFrom magrittr %>%
#'
#' @param dataset_uri Dataset URI.
#' @param lang_pref Preferred order of language codes used to resolve
#'   multilingual labels. Supported language codes typically include
#'   \code{"de"}, \code{"fr"}, \code{"it"}, \code{"rm"}, and \code{"en"}.
#'
#' @return A tibble describing the observation properties, including
#'   property-shape URI, path, preferred label, order, datatype, node kind,
#'   minimum count, and maximum count.
#' @export
get_dataset_schema <- function(dataset_uri, lang_pref = c("en", "de", "fr", "it", "rm")) {

  cube_meta <- get_cube_metadata(dataset_uri)
  shape_uri <- cube_meta$observation_constraint[1]

  if (is.na(shape_uri) || !nzchar(shape_uri)) stop("No observation constraint found for this dataset.")

  query <- paste(
    "PREFIX sh: <http://www.w3.org/ns/shacl#>",
    "PREFIX schema: <http://schema.org/>",
    "",
    "SELECT ?propertyShape ?path ?label (LANG(?label) AS ?label_lang) ?order ?datatype ?nodeKind ?minCount ?maxCount",
    "WHERE {",
    sprintf("  <%s> sh:property ?propertyShape .", shape_uri),
    "  ?propertyShape sh:path ?path .",
    "  OPTIONAL { ?propertyShape schema:name ?label . }",
    "  OPTIONAL { ?propertyShape sh:order ?order . }",
    "  OPTIONAL { ?propertyShape sh:datatype ?datatype . }",
    "  OPTIONAL { ?propertyShape sh:nodeKind ?nodeKind . }",
    "  OPTIONAL { ?propertyShape sh:minCount ?minCount . }",
    "  OPTIONAL { ?propertyShape sh:maxCount ?maxCount . }",
    "}",
    "ORDER BY ?order ?path ?label",
    sep = "\n"
    )

  raw <- query_lindas(query)

  raw %>%
    dplyr::group_by(
      .data$propertyShape,
      .data$path,
      .data$order,
      .data$datatype,
      .data$nodeKind,
      .data$minCount,
      .data$maxCount
    ) %>%
    dplyr::summarise(
      label = pick_pref(.data$label, .data$label_lang, lang_pref),
      label_lang = pick_pref(.data$label_lang, .data$label_lang, lang_pref),
      .groups = "drop"
    ) %>%
    dplyr::arrange(.data$order, .data$path)
}

#' Retrieve preferred labels for URIs from LINDAS
#'
#' \code{get_uri_labels} retrieves preferred \code{schema:name} labels for a set
#' of URIs.
#'
#' @importFrom dplyr group_by summarise
#' @importFrom magrittr %>%
#'
#' @param uris Character vector of URIs.
#' @param lang_pref Preferred order of language codes used to resolve labels.
#'   Supported language codes typically include \code{"de"}, \code{"fr"},
#'   \code{"it"}, \code{"rm"}, \code{"en"}, and \code{""}.
#'
#' @return A tibble with columns \code{uri}, \code{label}, and
#'   \code{label_lang}.
#' @noRd
get_uri_labels <- function(uris, lang_pref = c("en", "de", "fr", "it", "rm")) {

  uris <- unique(stats::na.omit(uris))
  uris <- uris[grepl("^https?://", uris)]

  if (length(uris) == 0) {
    return(tibble::tibble(
      uri = character(),
      label = character(),
      label_lang = character()
      ))
    }

  values_block <- paste(sprintf("<%s>", uris), collapse = " ")

  query <- paste(
    "SELECT ?uri ?label (LANG(?label) AS ?label_lang)",
    "WHERE {",
    "  ?uri <http://schema.org/name> ?label .",
    sprintf("  VALUES ?uri { %s }", values_block),
    "}",
    "ORDER BY ?uri ?label",
    sep = "\n"
  )

  raw <- query_lindas(query)

  raw %>%
    dplyr::group_by(.data$uri) %>%
    dplyr::summarise(
      label = pick_pref(.data$label, .data$label_lang, lang_pref),
      label_lang = pick_pref(.data$label_lang, .data$label_lang, lang_pref),
      .groups = "drop"
    )

  }

#' Detect whether a vector contains URI-like values
#'
#' @param x Character vector.
#'
#' @return Logical scalar.
#' @noRd
looks_like_uri <- function(x) {

  x <- stats::na.omit(x)
  if (length(x) == 0) return(FALSE)
  mean(grepl("^https?://", x)) > 0.8

}

#' Extract the terminal segment of a URI
#'
#' Returns the final path fragment of a URI (after the last '/' or '#'),
#' which can be used as a machine-friendly column name.
#'
#' @param path A character string containing a URI.
#'
#' @return A character string with the last segment of the URI.
#' @noRd
make_machine_name <- function(path) sub("^.*[/#]", "", path)
