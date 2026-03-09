#' Retrieve datasets from LINDAS
#'
#' \code{get_datasets} retrieves dataset metadata from LINDAS.
#'
#' Dataset metadata in LINDAS may exist in multiple language versions. By
#' default, multilingual fields are reduced according to the preferred language
#' order given in \code{lang_pref}.
#'
#' @importFrom dplyr group_by summarise arrange first
#' @importFrom stats na.omit
#'
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
#' @return A tibble containing dataset metadata from LINDAS. If
#'   \code{lang_pref} is not \code{NULL}, one preferred value per multilingual
#'   field is returned for each dataset. Otherwise, all language versions are
#'   retained.
#' @export
#'
#' @examples
#' \dontrun{
#' # Prefer English, then German, then French, Italian, and Romansh
#' get_datasets()
#'
#' # Prefer German metadata when available
#' get_datasets(lang_pref = c("de", "fr", "it", "rm", "en"))
#'
#' # Get all available language versions
#' get_datasets(lang_pref = NULL)
#' }
get_datasets <- function(lang_pref = c("en", "de", "fr", "it", "rm")) {

  raw <- query_lindas(lindas_queries$datasets)

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
        .groups = "drop"
      )
  }

  dplyr::arrange(raw, .data$name)
}
