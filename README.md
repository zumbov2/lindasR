<img src="img/logo.png" height="120px" align="right" style="padding-left:10px;background-color:white;"/>

![Lifecycle](https://img.shields.io/badge/lifecycle-maturing-orange.svg)

# lindasR

R interface to the **Swiss Federal Linked Data Service (LINDAS)**.

`lindasR` provides a lightweight wrapper around the LINDAS SPARQL
endpoint and makes it easier to explore datasets and query linked
government data directly from R.

[LINDAS](https://lindas.admin.ch/) is the Linked Data infrastructure of
the Swiss federal administration. It publishes government data as
knowledge graphs that can be queried via SPARQL.

# Installation

``` r
# Install from GitHub
remotes::install_github("zumbov2/lindasR")
```

# Features

The package currently provides tools to:

-   query the LINDAS SPARQL endpoint
-   retrieve dataset metadata
-   explore RDF cube structures
-   download full observation datasets
-   perform full-text search across literals
-   work with multilingual metadata (DE, FR, IT, RM, EN)

# Examples

## List datasets available in LINDAS

``` r
lindasR::get_datasets()
#>
#> # A tibble: 273 × 9
#>    sub            name  description contactName endpoint landingPage dateCreated
#>    <chr>          <chr> <chr>       <chr>       <chr>    <chr>       <chr>      
#>  1 https://commu… Adve… "This data… BAKOM | OF… https:/… https://we… 2024-03-28 
#>  2 https://envir… Air … "The proje… Sektion Um… https:/… https://ww… 2022-05-30 
#>  3 https://commu… Anal… "This data… Fachabteil… https:/… https://ww… 2025-12-10 
#>  4 https://agric… Anim… "Whoever k… <NA>        <NA>     <NA>        2021-04-05 
#>  5 https://healt… Anim…  <NA>       Animal Exp… https:/… <NA>        2024-09-20 
#>  6 https://healt… Anim…  <NA>       Animal Exp… https:/… <NA>        2025-06-30 
#>  7 https://healt… Anim…  <NA>       Animal Exp… https:/… <NA>        2024-11-21 
#>  8 https://healt… Anim…  <NA>       Animal Exp… https:/… <NA>        2024-11-19 
#>  9 https://commu… Annu… "This data… BAKOM | OF… https:/… https://we… 2024-03-28 
#> 10 https://healt… Annu… "Origin in… Data Compe… https:/… <NA>        2024-09-20 
#> # ℹ 263 more rows
#> # ℹ 2 more variables: datePublished <chr>, dateModified <chr>
```

## Download a dataset

Many datasets in LINDAS are published as RDF cubes. `get_data()` automatically detects the cube structure and returns the observations as a tidy table.

``` r
lindasR::get_data(
  dataset_uri = "https://politics.ld.admin.ch/fc/cube-president",
  lang_pref = "de"
  )
#>   
#> # A tibble: 180 × 4
#>    Jahr  BundespräsidentIn               `Vize-PräsidentIn` `Vize-PräsidentIn 2`
#>    <chr> <chr>                           <chr>              <chr>               
#>  1 1848  Furrer, Jonas                   Druey, Daniel-Hen… https://cube.link/U…
#>  2 1849  Furrer, Jonas                   Druey, Daniel-Hen… https://cube.link/U…
#>  3 1850  Druey, Daniel-Henri             https://politics.… https://cube.link/U…
#>  4 1851  https://politics.ld.admin.ch/f… Furrer, Jonas      https://cube.link/U…
#>  5 1852  Furrer, Jonas                   Naeff, Wilhelm Ma… https://cube.link/U…
#>  6 1853  Naeff, Wilhelm Matthias         Frey-Herosé, Frie… https://cube.link/U…
#>  7 1854  Frey-Herosé, Friedrich          Ochsenbein, Ulrich https://cube.link/U…
#>  8 1855  Furrer, Jonas                   Stämpfli, Jakob    https://cube.link/U…
#>  9 1856  Stämpfli, Jakob                 Fornerod, Constant https://cube.link/U…
#> 10 1857  Fornerod, Constant              Furrer, Jonas      https://cube.link/U…
#> # ℹ 170 more rows
```

## Full-text search in the knowledge graph

Search across literals stored in LINDAS.

``` r
lindasR::search_lindas("Fraumünster")
#>
#> # A tibble: 177 × 4
#>    s                                        p                        l     score
#>    <chr>                                    <chr>                    <chr> <chr>
#>  1 https://culture.ld.admin.ch/ais/21857753 https://www.ica.org/sta… "Inh… 11.0…
#>  2 https://culture.ld.admin.ch/ais/21717293 https://www.ica.org/sta… "Inh… 11.0…
#>  3 https://culture.ld.admin.ch/ais/21687956 https://www.ica.org/sta… "Gen… 11.0…
#>  4 https://culture.ld.admin.ch/ais/21832777 https://www.ica.org/sta… "Inh… 11.0…
#>  5 https://culture.ld.admin.ch/ais/21774282 https://www.ica.org/sta… "Inh… 11.0…
#>  6 https://culture.ld.admin.ch/ais/30694535 https://www.ica.org/sta… "Gen… 10.4…
#>  7 https://culture.ld.admin.ch/ais/29658269 https://www.ica.org/sta… "Seq… 10.4…
#>  8 https://culture.ld.admin.ch/ais/21901733 https://www.ica.org/sta… "Inh… 10.4…
#>  9 https://culture.ld.admin.ch/ais/21796651 https://www.ica.org/sta… "Inh… 10.4…
#> 10 https://culture.ld.admin.ch/ais/30694534 https://www.ica.org/sta… "Gen… 10.4…
#> # ℹ 167 more rows
```

## End-to-End example
``` r

library(lindasR)
library(tidyverse)
library(lubridate)
library(geomtextpath)
library(ggtext)
library(scales)
  
df <-
  get_data(
    "https://agriculture.ld.admin.ch/foag/cube/MilkDairyProducts/Consumption_Price_Month",
    lang_pref = "de"
    )

cheese_selection <- c(
  "Sbrinz", "Gruyère mild", "Emmentaler mild", 
  "Appenzeller mild", "Raclettekäse", "Mozzarella"
  )

df |>
  filter(
    Produktionssystem == "Konventionell",
    Produktherkunft == "Schweiz",
    !(Produktgruppe == "Käse" & !Produkt %in% cheese_selection),
    !(Produktgruppe == "Konsummilch" & str_detect(Produkt, "Past"))
    ) |>
  group_by(Datum, Produktuntergruppe) |>
  slice(1) |>
  mutate(
    Datum = dmy(paste0("1.", Datum)),
    Preis = as.numeric(Preis),
    Produktgruppe = paste0(Produktgruppe, " (1 ", Einheit, ")")
    ) |>
  ggplot(aes(Datum, Preis, color = Produkt, label = Produkt)) +
  geom_line(alpha = 0.4) +
  geom_textsmooth(
    linewidth = 1.25,
    family = "Roboto Condensed",
    size = 11/.pt,
    method = 'loess',
    formula = 'y ~ x'
    ) +
  facet_wrap(.~Produktgruppe, scales = "free_y") +
  scale_y_continuous(labels = function(x) paste("CHF", number(x, accuracy = 0.01))) +
  labs(
    title = "Preisentwicklung ausgewählter <b style='color:#E0EBA1;'>Milchprodukte</b> im Schweizer Detailhandel",
    subtitle = "Die Grafik zeigt die <b>monatlichen Durchschnittspreise ausgewählter Milchprodukte</b> im Schweizer Detailhandel seit 2022. Grundlage sind Daten der <b>Marktanalysen des Bundesamts für Landwirtschaft (BLW)</b>.<br>
    Die dünnen Linien zeigen die beobachteten Monatswerte, während die hervorgehobenen Linien eine <b>geglättete Trendkurve (LOESS)</b> darstellen, um die längerfristige Preisentwicklung sichtbar zu machen.<br>
    Berücksichtigt werden ausschliesslich <b>Milchprodukte aus Schweizer Herkunft und konventioneller Produktion</b>.",
    caption = "<b>Quelle:</b> Bundesamt für Landwirtschaft, Fachbereich Marktanalysen • Gestaltung inspiriert von Cédric Scherer"
    ) +
  theme_custom()

```

<img src="https://raw.githubusercontent.com/zumbov2/lindasR/master/img/plot.png" width="800">

# Disclaimer

Some parts of this package were developed with the assistance of a Large Language Model (LLM).  

# LINDAS

More information about the Swiss Linked Data infrastructure:

https://lindas.admin.ch/

SPARQL endpoint:

https://ld.admin.ch/query


# Contributing

Contributions and feedback are welcome.
