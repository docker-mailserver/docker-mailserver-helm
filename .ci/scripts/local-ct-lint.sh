#!/bin/bash

docker run --rm -it -w /repo -v $(pwd):/repo quay.io/helmpack/chart-testing:v3.15.0 ct lint --all --config .ci/ct-config.yaml
