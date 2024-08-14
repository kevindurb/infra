#! /bin/bash

# shellcheck disable=SC2016
yq -i '
  with(select(.kind == "Kustomization");
    .commonLabels as $labels
    | with(.labels[0];
      .pairs = $labels
      | .includeSelectors = true
      | .includeTemplates = true
    )
    | del(.commonLabels)
  )
' "$1"
