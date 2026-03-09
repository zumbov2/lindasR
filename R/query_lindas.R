#' Query the LINDAS SPARQL endpoint
#'
#' \code{query_lindas} sends a SPARQL query to the LINDAS endpoint and returns
#' the result as a tibble.
#'
#' @importFrom httr POST add_headers stop_for_status content
#' @importFrom jsonlite fromJSON
#' @importFrom tibble tibble
#' @importFrom purrr map_chr
#'
#' @param query A SPARQL query as a character string.
#'
#' @return A tibble containing the query result. If the query returns no rows,
#'   an empty tibble is returned.
#' @export
query_lindas <- function(query) {

  res <-
    httr::POST(
      url = "https://ld.admin.ch/query",
      body = list(query = query),
      encode = "form",
      httr::add_headers(Accept = "application/sparql-results+json")
    )

  httr::stop_for_status(res)

  txt <- httr::content(res, as = "text", encoding = "UTF-8")
  json <- jsonlite::fromJSON(txt, simplifyVector = FALSE)

  vars <- json$head$vars
  rows <- json$results$bindings

  if (length(rows) == 0) return(tibble::tibble())

  tibble::tibble(
    !!!stats::setNames(
      lapply(vars, function(v) {
        purrr::map_chr(rows, function(r) {
          if (!is.null(r[[v]]$value)) r[[v]]$value else NA_character_
        })
      }),
      vars
    )
  )
}
