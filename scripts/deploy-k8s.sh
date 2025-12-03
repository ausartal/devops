#!/bin/bash

set -e

# ========================================================
# Kubernetes Deployment Script
# This script deploys the application to specified namespace
# ========================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# ========================================================
# Configuration
# ========================================================
NAMESPACE="${1:-dev-ahmad}"
IMAGE_TAG="${2:-main-latest}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-harbor.example.com}"
IMAGE_NAME="${IMAGE_NAME:-ci-cd-app}"

log_info "========================================="
log_info "Kubernetes Deployment Script"
log_info "========================================="
log_info "Namespace: $NAMESPACE"
log_info "Image: $DOCKER_REGISTRY/library/$IMAGE_NAME:$IMAGE_TAG"
log_info "========================================="

# ========================================================
# Step 1: Create namespace if not exists
# ========================================================
log_step "Creating namespace $NAMESPACE (if not exists)..."
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# ========================================================
# Step 2: Create ImagePullSecret if not exists
# ========================================================
log_step "Checking ImagePullSecret..."
if ! kubectl get secret harbor-registry-secret -n $NAMESPACE &>/dev/null; then
    log_warn "ImagePullSecret not found. Please create it:"
    log_warn "kubectl create secret docker-registry harbor-registry-secret \\"
    log_warn "  --docker-server=$DOCKER_REGISTRY \\"
    log_warn "  --docker-username=YOUR_USERNAME \\"
    log_warn "  --docker-password=YOUR_PASSWORD \\"
    log_warn "  --docker-email=YOUR_EMAIL \\"
    log_warn "  -n $NAMESPACE"
else
    log_info "✅ ImagePullSecret exists"
fi

# ========================================================
# Step 3: Apply RBAC (for staging namespace)
# ========================================================
if [[ $NAMESPACE == staging-* ]]; then
    log_step "Applying RBAC configuration..."
    kubectl apply -f k8s/rbac.yaml -n $NAMESPACE
    log_info "✅ RBAC applied"
fi

# ========================================================
# Step 4: Deploy application
# ========================================================
log_step "Deploying application..."

# Replace image placeholder and apply deployment
sed "s|IMAGE_PLACEHOLDER|$DOCKER_REGISTRY/library/$IMAGE_NAME:$IMAGE_TAG|g" \
    k8s/deployment.yaml | kubectl apply -f - -n $NAMESPACE

# Apply service
kubectl apply -f k8s/service.yaml -n $NAMESPACE

log_info "✅ Deployment configuration applied"

# ========================================================
# Step 5: Wait for rollout
# ========================================================
log_step "Waiting for rollout to complete..."
kubectl rollout status deployment/ci-cd-app -n $NAMESPACE --timeout=300s

# ========================================================
# Step 6: Show deployment status
# ========================================================
log_info "========================================="
log_info "Deployment Status"
log_info "========================================="

echo ""
log_step "Pods:"
kubectl get pods -n $NAMESPACE -l app=ci-cd-app

echo ""
log_step "Services:"
kubectl get svc -n $NAMESPACE -l app=ci-cd-app

echo ""
log_step "Deployment:"
kubectl get deployment ci-cd-app -n $NAMESPACE

# ========================================================
# Step 7: Verify RBAC (for staging)
# ========================================================
if [[ $NAMESPACE == staging-* ]]; then
    echo ""
    log_info "========================================="
    log_info "RBAC Verification (PoLP)"
    log_info "========================================="
    log_warn "To verify Principle of Least Privilege, run:"
    echo ""
    echo "kubectl delete deployment ci-cd-app -n $NAMESPACE \\"
    echo "  --as=system:serviceaccount:$NAMESPACE:drone-deployer"
    echo ""
    log_warn "Expected: Error from server (Forbidden) - This proves PoLP works! ✅"
fi

log_info ""
log_info "✅ Deployment completed successfully!"
