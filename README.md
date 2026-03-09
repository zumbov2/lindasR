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
library(lindasR)

datasets <- get_datasets()
datasets
```

## Download a dataset

Many datasets in LINDAS are published as RDF cubes. `get_data()` automatically detects the cube structure and returns the observations as a tidy table.

``` r
data <- get_data("https://politics.ld.admin.ch/fc/cube-president")

data
```

## Full-text search in the knowledge graph

Search across literals stored in LINDAS.

``` r
search_lindas("Fraumünster")
```

# LINDAS

More information about the Swiss Linked Data infrastructure:

https://lindas.admin.ch/

SPARQL endpoint:

https://ld.admin.ch/query


# Contributing

Contributions and feedback are welcome.

Bug reports and feature requests can be submitted via:

https://github.com/zumbov2/lindasR/issues
