#!/bin/bash
set -e

echo "📊 Deploying monitoring stack..."

# Create monitoring namespace
kubectl apply -f k8s-manifests/monitoring/prometheus.yaml

# Deploy Grafana
kubectl apply -f k8s-manifests/monitoring/grafana.yaml

# Wait for pods
echo "⏳ Waiting for monitoring pods to be ready..."
kubectl wait --namespace monitoring --for=condition=ready pod --selector=app=prometheus --timeout=300s
kubectl wait --namespace monitoring --for=condition=ready pod --selector=app=grafana --timeout=300s

# Port forward Grafana
echo "🔗 Grafana available at: http://localhost:3000"
echo "🔗 Prometheus available at: http://localhost:9090"
echo ""
echo "📝 Default Grafana credentials: admin/admin"
echo "📝 Run: kubectl port-forward svc/grafana 3000:3000 -n monitoring"