#!/bin/bash
set -e
shopt -s nullglob
DIR="$(dirname "$(readlink -f "$0")")/.."

echo "Starting kubeconform tests..."

for chart in $DIR/helm-chart-sources/*; do
  CHART=$(basename $chart)
  echo "Running tests for $CHART..."

  for values in $chart/tests/fixtures/*; do
    TEST=$(basename $values)
    echo "** Linting chart"
    helm lint -f $values $chart
    echo "** Evaluating fixture $TEST"
    helm template -f $values $chart | kubeconform -summary
  done
done