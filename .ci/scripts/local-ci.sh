#!/bin/bash

docker run --rm -it -w /repo -v `pwd`:/repo quay.io/helmpack/chart-testing ct lint --config=.ci/ct-config.yaml 
