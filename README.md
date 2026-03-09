# lindasR

R interface to the **Swiss Federal Linked Data Service (LINDAS)**.

The package provides a lightweight wrapper around the LINDAS SPARQL
endpoint and makes it easier to query datasets and perform full‑text
searches from R.

[LINDAS](https://lindas.admin.ch/) is the Linked Data infrastructure of the Swiss federal
administration and allows government data to be published and queried as
knowledge graphs via SPARQL.

## Installation

``` r
# install from GitHub
remotes::install_github("zumbov2/lindasR")
```

## What the package does

-   query the LINDAS SPARQL endpoint
-   retrieve dataset metadata
-   perform full‑text search across literals

## Example

Query datasets published in LINDAS:

``` r
library(lindasR)

datasets <- get_datasets()
datasets
```

Search across literals in the LINDAS knowledge graph:

``` r
search_lindas("Fraumünster")
```


