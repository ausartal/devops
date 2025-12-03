#!/bin/bash

# =============================================================================
# DEMO SCRIPT - Level 3 CI/CD Drone + Kubernetes
# =============================================================================
# Script ini membantu menjalankan demo untuk penilai
# Jalankan dengan: ./demo-level3.sh
# =============================================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

STUDENT_NAME="ahmad"
DEV_NS="dev-${STUDENT_NAME}"
STAGING_NS="staging-${STUDENT_NAME}"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}DEMO SCRIPT - Level 3 CI/CD${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# =============================================================================
# TAHAP 1: Persiapan & Verifikasi
# =============================================================================
echo -e "${YELLOW}TAHAP 1: Verifikasi Persiapan${NC}"
echo ""

echo "1.1 Verifikasi namespaces..."
if kubectl get namespace $DEV_NS &>/dev/null; then
    echo -e "${GREEN}[OK] Namespace $DEV_NS exists${NC}"
else
    echo -e "${RED}[FAIL] Namespace $DEV_NS not found${NC}"
    echo "Run: kubectl create namespace $DEV_NS"
    exit 1
fi

if kubectl get namespace $STAGING_NS &>/dev/null; then
    echo -e "${GREEN}[OK] Namespace $STAGING_NS exists${NC}"
else
    echo -e "${RED}[FAIL] Namespace $STAGING_NS not found${NC}"
    echo "Run: kubectl create namespace $STAGING_NS"
    exit 1
fi
echo ""

echo "1.2 Verifikasi ImagePullSecret..."
if kubectl get secret harbor-registry-secret -n $DEV_NS &>/dev/null; then
    echo -e "${GREEN}[OK] ImagePullSecret exists in $DEV_NS${NC}"
else
    echo -e "${YELLOW}[WARNING] ImagePullSecret not found in $DEV_NS${NC}"
fi

if kubectl get secret harbor-registry-secret -n $STAGING_NS &>/dev/null; then
    echo -e "${GREEN}[OK] ImagePullSecret exists in $STAGING_NS${NC}"
else
    echo -e "${YELLOW}[WARNING] ImagePullSecret not found in $STAGING_NS${NC}"
fi
echo ""

echo "1.3 Verifikasi RBAC..."
if kubectl get serviceaccount drone-deployer -n $STAGING_NS &>/dev/null; then
    echo -e "${GREEN}[OK] ServiceAccount drone-deployer exists${NC}"
else
    echo -e "${YELLOW}[WARNING] ServiceAccount not found${NC}"
fi

if kubectl get role deployment-manager -n $STAGING_NS &>/dev/null; then
    echo -e "${GREEN}[OK] Role deployment-manager exists${NC}"
else
    echo -e "${YELLOW}[WARNING] Role not found${NC}"
fi

if kubectl get rolebinding drone-deployer-binding -n $STAGING_NS &>/dev/null; then
    echo -e "${GREEN}[OK] RoleBinding drone-deployer-binding exists${NC}"
else
    echo -e "${YELLOW}[WARNING] RoleBinding not found${NC}"
fi
echo ""

read -p "Press ENTER to continue to TAHAP 2..."

# =============================================================================
# TAHAP 2: Show Configuration Files
# =============================================================================
echo -e "${YELLOW}TAHAP 2: Tunjukkan File Konfigurasi${NC}"
echo ""

echo "2.1 Structure .drone.yml..."
echo -e "${BLUE}Stages:${NC}"
echo "  1. Build (npm ci, lint, test)"
echo "  2. Publish (Docker push)"
echo "  3. Trivy Scan (--exit-code 1)"
echo "  4. Deploy (dev: automatic, staging: manual)"
echo ""

echo "2.2 RBAC Configuration..."
echo -e "${BLUE}Checking Role verbs...${NC}"
kubectl get role deployment-manager -n $STAGING_NS -o yaml | grep -A 10 "rules:"
echo ""

read -p "Press ENTER to continue to TAHAP 3..."

# =============================================================================
# TAHAP 3: Show Running Deployments
# =============================================================================
echo -e "${YELLOW}TAHAP 3: Tunjukkan Deployment yang Running${NC}"
echo ""

echo "3.1 DEV Namespace ($DEV_NS)..."
kubectl get all -n $DEV_NS
echo ""

echo "3.2 STAGING Namespace ($STAGING_NS)..."
kubectl get all -n $STAGING_NS
echo ""

read -p "Press ENTER to continue to TAHAP 4 (RBAC Demo)..."

# =============================================================================
# TAHAP 4: RBAC PoLP Demonstration (CRITICAL!)
# =============================================================================
echo -e "${YELLOW}TAHAP 4: Demonstrasi RBAC (Principle of Least Privilege)${NC}"
echo -e "${RED}[CRITICAL] INI YANG PALING PENTING UNTUK SCREENSHOT${NC}"
echo ""

SERVICE_ACCOUNT="system:serviceaccount:${STAGING_NS}:drone-deployer"

echo "4.1 Test operasi yang DIIZINKAN (harus SUKSES)..."
echo -e "${BLUE}Command: kubectl get deployment ci-cd-app -n $STAGING_NS --as=$SERVICE_ACCOUNT${NC}"
if kubectl get deployment ci-cd-app -n $STAGING_NS --as=$SERVICE_ACCOUNT &>/dev/null; then
    echo -e "${GREEN}[PASS] ServiceAccount CAN read deployment${NC}"
    kubectl get deployment ci-cd-app -n $STAGING_NS --as=$SERVICE_ACCOUNT
else
    echo -e "${RED}[FAIL] ServiceAccount cannot read (unexpected)${NC}"
fi
echo ""

echo "4.2 Test operasi yang DILARANG (harus GAGAL dengan Forbidden)..."
echo -e "${BLUE}Command: kubectl delete deployment ci-cd-app -n $STAGING_NS --as=$SERVICE_ACCOUNT${NC}"
echo -e "${RED}[SCREENSHOT] SCREENSHOT COMMAND DAN OUTPUT INI${NC}"
echo ""

# Run the forbidden command and capture output
if kubectl delete deployment ci-cd-app -n $STAGING_NS --as=$SERVICE_ACCOUNT 2>&1 | grep -q "Forbidden"; then
    echo -e "${GREEN}[PASS] PoLP VERIFIED - ServiceAccount CANNOT delete deployment${NC}"
    echo -e "${GREEN}Output menunjukkan 'Forbidden' - Principle of Least Privilege bekerja${NC}"
    
    # Show the actual forbidden output
    echo -e "\n${BLUE}Actual output:${NC}"
    kubectl delete deployment ci-cd-app -n $STAGING_NS --as=$SERVICE_ACCOUNT 2>&1 || true
else
    echo -e "${RED}[FAIL] ServiceAccount dapat delete (PoLP tidak bekerja)${NC}"
    echo -e "${RED}Periksa kembali k8s/rbac.yaml - pastikan TIDAK ada 'delete' verb${NC}"
fi
echo ""

read -p "Press ENTER to continue to TAHAP 5..."

# =============================================================================
# TAHAP 5: Verification Summary
# =============================================================================
echo -e "${YELLOW}TAHAP 5: Ringkasan Verifikasi${NC}"
echo ""

echo -e "${BLUE}Checklist untuk Screenshot:${NC}"
echo "[ ] Screenshot 1: Drone Pipeline Success (4 stages)"
echo "[ ] Screenshot 2: Manual Approval UI (PROMOTE button)"
echo "[ ] Screenshot 3: Trivy Scan Results"
echo "[ ] Screenshot 4: RBAC DELETE Forbidden (dari TAHAP 4)"
echo "[ ] Screenshot 5: Deployments Running (dari TAHAP 3)"
echo "[ ] Screenshot 6: ImagePullSecret Configuration"
echo ""

echo -e "${BLUE}Command untuk Screenshot 6:${NC}"
echo "kubectl get secret harbor-registry-secret -n $STAGING_NS -o yaml"
echo ""

echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}Demo Complete${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo "1. Pastikan semua 6 screenshot sudah diambil"
echo "2. Siapkan presentasi dengan flowchart"
echo "3. Siapkan penjelasan troubleshooting"
echo "4. Review SUBMISSION_CHECKLIST.md"
echo ""

echo -e "${YELLOW}Untuk trigger pipeline:${NC}"
echo "  - DEV:     git push origin main"
echo "  - STAGING: git push origin staging (lalu approve di Drone UI)"
echo ""

echo -e "${GREEN}Selesai${NC}"
