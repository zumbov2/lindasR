#' Predefined SPARQL queries for LINDAS
#'
#' @format A named list of SPARQL query strings.
#' @noRd
lindas_queries <-
  list(
    datasets = '
PREFIX schema: <http://schema.org/>
PREFIX rdf:    <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX void:   <http://rdfs.org/ns/void#>
PREFIX dcat:   <http://www.w3.org/ns/dcat#>

SELECT DISTINCT
  ?sub
  ?name
  (LANG(?name) AS ?name_lang)
  ?description
  (LANG(?description) AS ?description_lang)
  ?endpoint
  ?landingPage
  ?contactName
  (LANG(?contactName) AS ?contactName_lang)
  ?dateCreated
  ?datePublished
  ?dateModified

WHERE {
  ?sub schema:name ?name .
  ?sub rdf:type ?resultType .

  OPTIONAL {
    ?sub schema:description ?description .
  }

  OPTIONAL {
    ?sub void:sparqlEndpoint ?endpoint .
  }

  OPTIONAL {
    ?sub dcat:landingPage ?landingPage .
  }

  OPTIONAL {
    ?sub schema:contactPoint/schema:name ?contactName .
  }

  OPTIONAL {
    ?sub schema:dateCreated ?dateCreated .
  }

  OPTIONAL {
    ?sub schema:datePublished ?datePublished .
  }

  OPTIONAL {
    ?sub schema:dateModified ?dateModified .
  }

  FILTER(?resultType IN (void:Dataset))
  FILTER(NOT EXISTS { ?sub schema:expires ?x . })
  FILTER(NOT EXISTS {
    ?sub schema:creativeWorkStatus <https://register.ld.admin.ch/definedTerm/CreativeWorkStatus/Draft> .
  })
}
'
  )
