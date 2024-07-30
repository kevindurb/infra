#! /bin/bash

yq eval-all 'select(.kind == "Service" and .metadata.annotations["gatus.io/enabled"] == "true")' ./dist/*.yml
