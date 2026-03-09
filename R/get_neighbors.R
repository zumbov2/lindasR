#' Retrieve neighboring triples for a LINDAS resource
#'
#' \code{get_neighbors} retrieves triples connected to a given resource URI.
#' Both outgoing triples (where the URI is the subject) and incoming triples
#' (where the URI is the object) can be returned.
#'
#' @importFrom dplyr bind_rows arrange
#'
#' @param uri Resource URI.
#' @param direction Direction of traversal. One of
#'   \code{"out"}, \code{"in"}, or \code{"both"}.
#'
#' @return A tibble containing neighboring triples with columns:
#'   \code{s}, \code{p}, \code{o}, and \code{direction}.
#' @export
#'
#' @examples
#' \dontrun{
#' get_neighbors("https://ld.admin.ch/canton/21")
#'
#' get_neighbors(
#'   "https://ld.admin.ch/canton/21",
#'   direction = "out"
#' )
#' }
get_neighbors <- function(uri, direction = "both") {

  if (!nzchar(uri)) stop("`uri` must not be empty.")
  if (!direction %in% c("out", "in", "both")) stop("`direction` must be 'out', 'in', or 'both'.")

  res <- list()

  if (direction %in% c("out", "both")) {

    query_out <- paste(
      "SELECT ?s ?p ?o",
      "WHERE {",
      sprintf("  VALUES ?s { <%s> }", uri),
      "  ?s ?p ?o .",
      "}",
      sep = "\n"
    )

    out <- query_lindas(query_out)
    out$direction <- "out"

    res$out <- out
  }

  if (direction %in% c("in", "both")) {

    query_in <- paste(
      "SELECT ?s ?p ?o",
      "WHERE {",
      sprintf("  VALUES ?o { <%s> }", uri),
      "  ?s ?p ?o .",
      "}",
      sep = "\n"
    )

    inbound <- query_lindas(query_in)
    inbound$direction <- "in"

    res$inbound <- inbound
  }

  res %>%
    dplyr::bind_rows() %>%
    dplyr::arrange(direction, p)
}
