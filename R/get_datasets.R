#' Retrieve datasets from LINDAS
#'
#' \code{get_datasets} retrieves dataset metadata from LINDAS and resolves
#' multilingual fields according to a preferred language order.
#'
#' @importFrom dplyr group_by summarise arrange
#' @importFrom stats na.omit
#'
#' @param lang_pref Preferred order of language codes used to resolve
#'   multilingual values. Defaults to \code{c("de", "fr", "it", "rm", "en")}.
#'
#' @return A tibble with one row per dataset.
#' @export
#'
#' @examples
#' \dontrun{
#' get_datasets()
#'
#' get_datasets(lang_pref = c("en", "de", "fr", "it", "rm"))
#' }
get_datasets <- function(lang_pref = c("de", "fr", "it", "rm", "en")) {

  raw <- query_lindas(lindas_queries$datasets)

  raw %>%
    dplyr::group_by(sub) %>%
    dplyr::summarise(
      name = pick_pref(name, name_lang, lang_pref),
      description = pick_pref(description, description_lang, lang_pref),
      contactName = pick_pref(contactName, contactName_lang, lang_pref),
      endpoint = dplyr::first(stats::na.omit(endpoint)),
      landingPage = dplyr::first(stats::na.omit(landingPage)),
      dateCreated = dplyr::first(stats::na.omit(dateCreated)),
      datePublished = dplyr::first(stats::na.omit(datePublished)),
      dateModified = dplyr::first(stats::na.omit(dateModified)),
      .groups = "drop"
    ) %>%
    dplyr::arrange(name)

}
