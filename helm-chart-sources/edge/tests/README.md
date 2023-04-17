# Unit Tests for the Cribl Edge Chart

## Prerequisites
Install the unittest plugin from quintush

```bash
helm plugin install https://github.com/quintush/helm-unittest
```

## Run Tests
```bash
cd $(git rev-parse --show-toplevel)
helm unittest helm-chart-sources/edge
```
