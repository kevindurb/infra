#! /bin/bash

yq -i '
  with(select(.kind == "Ingress");
    .metadata.annotations["cert-manager.io/cluster-issuer"] = "cloudflare-issuer"
    | .spec.rules[0].host as $host
    | with(.spec.tls[0];
      .secretName = "durbin-casa-wildcard-cert"
      | .hosts[0] alias = "host"
    )
    | .spec.rules[0].host anchor = "host"
  )
' "$1"
