#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")/.."

helm lint $DIR/helm-chart-sources/*
helm package $DIR/helm-chart-sources/*
helm repo index --url https://criblio.github.io/helm-charts/ $DIR
