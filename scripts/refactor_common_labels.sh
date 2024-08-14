#! /bin/bash

# shellcheck disable=SC2016
yq -i '
with(select(.kind == "Kustomization" and has("commonLabels") and has("labels") == false);
    .commonLabels as $labels
    | with(.labels[0];
      .pairs = $labels
      | .includeSelectors = true
      | .includeTemplates = true
    )
    | del(.commonLabels)
  )
' "$1"
