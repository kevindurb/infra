#! /bin/bash

# shellcheck disable=SC2016
yq -i '
  with(select(.kind == "Ingress" and .spec.ingressClassName == "nginx");
    .spec.ingressClassName = "external"
    | with(.metadata.annotations;
      .["external-dns.alpha.kubernetes.io/target"] = "external.durbin.casa"
    )
  )
' "$1"

# shellcheck disable=SC2016
yq -i '
  with(select(.kind == "Ingress" and .spec.ingressClassName == "internal");
    with(.metadata.annotations;
      .["external-dns.alpha.kubernetes.io/target"] = "internal.durbin.casa"
    )
  )
' "$1"
