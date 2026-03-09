#' Retrieve inbound triples for a given LINDAS resource
#'
#' \code{get_resource_inbound} retrieves all triples in which the given URI
#' appears in object position.
#'
#' If the subject has multilingual literals attached, no language reduction is
#' applied because this function returns inbound references rather than
#' properties of a single subject.
#'
#' @importFrom dplyr arrange
#'
#' @param uri Resource URI.
#'
#' @return A tibble with subject, predicate, and object for all inbound triples.
#' @export
#'
#' @examples
#' \dontrun{
#' get_resource_inbound("https://ld.admin.ch/canton/21")
#' }
get_resource_inbound <- function(uri) {

  if (!nzchar(uri)) stop("`uri` must not be empty.")

  query <- paste(
    "SELECT ?s ?p ?o",
    "WHERE {",
    sprintf("  VALUES ?o { <%s> }", uri),
    "  ?s ?p ?o .",
    "}",
    "ORDER BY ?s ?p",
    sep = "\n"
  )

  query_lindas(query)
}
