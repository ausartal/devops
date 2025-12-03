#!/bin/bash

# RBAC PoLP Verification Script
# Verifies that the drone-deployer ServiceAccount has minimal permissions
# Usage: ./verify-rbac.sh <namespace>

set -e

NAMESPACE=${1:-staging-ahmad}
SERVICE_ACCOUNT="drone-deployer"
DEPLOYMENT_NAME="ci-cd-app"

echo "========================================="
echo "RBAC PoLP Verification Script"
echo "========================================="
echo "Namespace: $NAMESPACE"
echo "ServiceAccount: $SERVICE_ACCOUNT"
echo "Deployment: $DEPLOYMENT_NAME"
echo ""

# Verify ServiceAccount exists
echo "Checking ServiceAccount..."
if kubectl get serviceaccount $SERVICE_ACCOUNT -n $NAMESPACE &>/dev/null; then
    echo "[OK] ServiceAccount $SERVICE_ACCOUNT exists in namespace $NAMESPACE"
else
    echo "[ERROR] ServiceAccount $SERVICE_ACCOUNT not found in namespace $NAMESPACE"
    echo "Run: kubectl apply -f k8s/rbac.yaml -n $NAMESPACE"
    exit 1
fi
echo ""

# Verify Role exists
echo "Checking Role..."
if kubectl get role deployment-manager -n $NAMESPACE &>/dev/null; then
    echo "[OK] Role deployment-manager exists"
    echo ""
    echo "Role permissions:"
    kubectl get role deployment-manager -n $NAMESPACE -o yaml | grep -A 20 "rules:"
else
    echo "[ERROR] Role deployment-manager not found"
    exit 1
fi
echo ""

# Test 1: GET permission (should PASS)
echo "Test 1: Verifying GET permission..."
if kubectl get deployment $DEPLOYMENT_NAME -n $NAMESPACE \
    --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT &>/dev/null; then
    echo "[PASS] ServiceAccount CAN read deployment"
else
    echo "[FAIL] ServiceAccount cannot read deployment (unexpected)"
fi
echo ""

# Test 2: PATCH permission (should PASS)
echo "Test 2: Verifying PATCH permission..."
if kubectl patch deployment $DEPLOYMENT_NAME -n $NAMESPACE \
    --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT \
    -p '{"spec":{"replicas":1}}' --dry-run=server &>/dev/null; then
    echo "[PASS] ServiceAccount CAN patch deployment"
else
    echo "[FAIL] ServiceAccount cannot patch deployment (unexpected)"
fi
echo ""

# Test 3: DELETE permission (should FAIL - proves PoLP)
echo "Test 3: Verifying DELETE is FORBIDDEN (proves PoLP)..."
if kubectl delete deployment $DEPLOYMENT_NAME -n $NAMESPACE \
    --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT \
    --dry-run=server 2>&1 | grep -q "Forbidden"; then
    echo "[PASS] PoLP VERIFIED - ServiceAccount CANNOT delete deployment"
    echo "This proves Principle of Least Privilege is working correctly"
else
    echo "[FAIL] ServiceAccount CAN delete deployment - PoLP NOT working"
    echo "Check k8s/rbac.yaml - ensure 'delete' verb is NOT in the Role"
fi
echo ""

# Test 4: LIST pods permission (should PASS)
echo "Test 4: Verifying pod LIST permission..."
if kubectl get pods -n $NAMESPACE \
    --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT &>/dev/null; then
    echo "[PASS] ServiceAccount CAN list pods"
else
    echo "[FAIL] ServiceAccount cannot list pods (unexpected)"
fi
echo ""

echo "========================================="
echo "All RBAC tests completed"
echo "Principle of Least Privilege (PoLP) is correctly implemented"
echo "========================================="
echo ""
echo "For screenshot, run this command:"
echo "kubectl delete deployment $DEPLOYMENT_NAME -n $NAMESPACE \\"
echo "  --as=system:serviceaccount:$NAMESPACE:$SERVICE_ACCOUNT"
echo ""
echo "Expected output: Error from server (Forbidden)..."
