#' Retrieve predicates for a given LINDAS resource
#'
#' \code{get_predicates} retrieves all predicates used for a given subject URI
#' in LINDAS.
#'
#' @importFrom dplyr arrange distinct
#'
#' @param uri Resource URI.
#'
#' @return A tibble with one column, \code{p}, containing the predicates used
#'   for the given resource.
#' @export
#'
#' @examples
#' \dontrun{
#' get_predicates("https://communication.ld.admin.ch/ofcom/srg_revenue_structure/10")
#' }
get_predicates <- function(uri) {

  if (!nzchar(uri)) stop("`uri` must not be empty.")

  query <- paste(
    "SELECT DISTINCT ?p",
    "WHERE {",
    sprintf("  VALUES ?s { <%s> }", uri),
    "  ?s ?p ?o .",
    "}",
    "ORDER BY ?p",
    sep = "\n"
  )

  query_lindas(query)
}
