#!/bin/bash

KUBE_SCORE=${KUBE_SCORE:-kube-score}

for chart in `ls charts`;
do
helm template --values charts/$chart/ci/ci-values.yaml charts/$chart | ${KUBE_SCORE} score - \
    --ignore-test pod-networkpolicy \
    --ignore-test deployment-has-poddisruptionbudget \
    --ignore-test deployment-has-host-podantiaffinity \
    --ignore-test pod-probes \
    --ignore-test container-image-tag \
    --enable-optional-test container-security-context-privileged \
    --ignore-test container-security-context \
    --ignore-test container-security-context-user-group-id \
    --ignore-test container-security-context-readonlyrootfilesystem \
    #
done