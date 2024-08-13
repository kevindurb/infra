#! /bin/bash

# shellcheck disable=SC2016
yq -i '
  with(select(.kind == "Ingress");
    with(.metadata.annotations;
      .["nginx.ingress.kubernetes.io/auth-method"] = "GET"
      | .["nginx.ingress.kubernetes.io/auth-url"] = "http://authelia-service.default.svc.cluster.local/api/authz/auth-request"
      | .["nginx.ingress.kubernetes.io/auth-signin"] = "https://auth.durbin.casa?rm=$request_method"
      | .["nginx.ingress.kubernetes.io/auth-response-headers"] = "Remote-User,Remote-Name,Remote-Groups,Remote-Email"
    )
  )
' "$1"
