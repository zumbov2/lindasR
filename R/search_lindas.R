#' Search literals in LINDAS using full-text search
#'
#' \code{search_lindas} performs a full-text search over literals in LINDAS
#' using Stardog text search and returns matching triples with a relevance score.
#'
#' @importFrom utils head
#'
#' @param search Search term as a character string.
#'
#' @return A tibble with the subject, predicate, literal, and score of the
#'   matching triples.
#' @export
#'
#' @examples
#' \dontrun{
#' search_lindas("Fraumünster")
#' }
search_lindas <- function(search) {

  search <- trimws(search)
  if (!nzchar(search)) stop("`search` must not be empty.")

  text_search <- build_text_search_clause(search)

  query <-
    paste(
      "SELECT DISTINCT ?s ?p ?l ?score",
      "WHERE {",
      "  ?s ?p ?l .",
      paste0("  ", text_search),
      "}",
      "ORDER BY DESC(?score)",
      sep = "\n"
    )

  query_lindas(query)

}
