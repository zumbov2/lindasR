#' Retrieve observation data from a LINDAS cube dataset
#'
#' \code{get_data} retrieves the full observation table for a dataset in
#' LINDAS.
#'
#' The function uses the cube's observation constraint to infer the observation
#' columns automatically. Preferred labels for all paths are retrieved from the
#' property-shape metadata and can optionally be used as column names. For
#' URI-valued columns, labels can also be retrieved via \code{schema:name} and
#' used instead of the raw URI values.
#'
#' @importFrom dplyr arrange left_join
#'
#' @param dataset_uri Dataset URI.
#' @param lang_pref Preferred order of language codes used to resolve labels.
#'   Supported language codes typically include \code{"de"}, \code{"fr"},
#'   \code{"it"}, \code{"rm"}, and \code{"en"}.
#' @param drop_paths Predicate URIs to exclude from the final dataset because
#'   they are structural or technical rather than analytical variables.
#' @param use_path_labels If \code{TRUE}, preferred labels of the cube paths are
#'   used as column names where available.
#' @param use_value_labels If \code{TRUE}, URI-valued columns are replaced by
#'   their preferred labels where available.
#' @param make_unique If \code{TRUE} (default), duplicate column names are made
#'   unique using \code{\link[base:make.unique]{make.unique}}.
#'
#' @return A tibble with one row per observation.
#' @export
get_data <- function(dataset_uri, lang_pref = c("en", "de", "fr", "it", "rm"),
    drop_paths = c("http://www.w3.org/1999/02/22-rdf-syntax-ns#type", "https://cube.link/observedBy"),
    use_path_labels = TRUE, use_value_labels = TRUE, make_unique = TRUE) {

  if (!nzchar(dataset_uri)) stop("`dataset_uri` must not be empty.")

  cube_meta <- get_cube_metadata(dataset_uri)
  observation_set <- cube_meta$observation_set[1]

  if (is.na(observation_set) || !nzchar(observation_set)) stop("No observation set found for this dataset.")

  schema <- get_dataset_schema(dataset_uri, lang_pref = lang_pref)
  schema <- schema[!schema$path %in% drop_paths, , drop = FALSE]

  if (nrow(schema) == 0) stop("No usable observation paths found for this dataset.")

  select_vars <- sprintf("?col%s", seq_len(nrow(schema)) - 1)

  lines <- c(
    "#pragma describe.strategy cbd",
    "#pragma join.hash off",
    sprintf("SELECT %s WHERE {", paste(select_vars, collapse = " ")),
    sprintf("  <%s> <https://cube.link/observationSet> ?observationSet0 .", dataset_uri),
    "  ?observationSet0 <https://cube.link/observation> ?source0 ."
  )

  for (i in seq_len(nrow(schema))) {
    lines <- c(
      lines,
      sprintf("  ?source0 <%s> ?col%s .", schema$path[[i]], i - 1)
    )
  }

  lines <- c(lines, "}")
  query <- paste(lines, collapse = "\n")

  res <- query_lindas(query)

  schema$machine_name <- vapply(schema$path, make_machine_name, character(1))
  col_names <- schema$machine_name

  if (use_path_labels) {
    use_label <- !is.na(schema$label) & nzchar(schema$label)
    col_names[use_label] <- schema$label[use_label]
  }

  if (make_unique) col_names <- base::make.unique(col_names)

  names(res) <- col_names

  if (use_value_labels && nrow(res) > 0) {

    uri_cols <- names(res)[vapply(res, looks_like_uri, logical(1))]

    if (length(uri_cols) > 0) {

      all_uris <- unique(unlist(res[uri_cols], use.names = FALSE))
      label_tbl <- get_uri_labels(all_uris, lang_pref = lang_pref)

      for (col in uri_cols) {

        join_tbl <- label_tbl
        names(join_tbl) <- c(
          col,
          paste0(col, "_label"),
          paste0(col, "_label_lang")
        )

        res <- dplyr::left_join(res, join_tbl, by = col)

        use_label <- !is.na(res[[paste0(col, "_label")]]) &
          nzchar(res[[paste0(col, "_label")]])

        res[[col]][use_label] <- res[[paste0(col, "_label")]][use_label]

        res[[paste0(col, "_label")]] <- NULL
        res[[paste0(col, "_label_lang")]] <- NULL
      }
    }
  }

  dplyr::arrange(res, .data[[names(res)[1]]])
}
