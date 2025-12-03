# RBAC Verification Guide

This document provides comprehensive steps to verify that **Principle of Least Privilege (PoLP)** is correctly implemented in the Kubernetes RBAC configuration.

---

## What is PoLP?

**Principle of Least Privilege (PoLP)** is a security principle that states:

> *A user, program, or process should have only the minimum privileges necessary to perform its function.*

In our CI/CD context:
- The `drone-deployer` ServiceAccount **CAN** update deployments (needed for CI/CD)
- The `drone-deployer` ServiceAccount **CANNOT** delete deployments (prevents accidents)

---

## RBAC Configuration

### ServiceAccount
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: drone-deployer
  namespace: staging-ahmad
```

### Role (Minimal Permissions)
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
  namespace: staging-ahmad
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
    # NOTE: "delete" is intentionally MISSING
```

### RoleBinding
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: drone-deployer-binding
  namespace: staging-ahmad
subjects:
  - kind: ServiceAccount
    name: drone-deployer
    namespace: staging-ahmad
roleRef:
  kind: Role
  name: deployment-manager
  apiGroup: rbac.authorization.k8s.io
```

---

## Manual Verification Steps

### Step 1: Apply RBAC Configuration

```bash
# Apply the RBAC configuration
kubectl apply -f k8s/rbac.yaml -n staging-ahmad

# Verify resources created
kubectl get sa,role,rolebinding -n staging-ahmad
```

**Expected output:**
```
NAME                             SECRETS   AGE
serviceaccount/drone-deployer   0         10s

NAME                                       CREATED AT
role.rbac.authorization.k8s.io/deployment-manager   2024-01-01T00:00:00Z

NAME                                                      ROLE                      AGE
rolebinding.rbac.authorization.k8s.io/drone-deployer-binding   Role/deployment-manager   10s
```

### Step 2: Ensure Deployment Exists

```bash
# Check if deployment exists
kubectl get deployment ci-cd-app -n staging-ahmad

# If not, create a test deployment
kubectl create deployment ci-cd-app --image=nginx -n staging-ahmad
```

### Step 3: Test GET Permission (Should SUCCEED)

```bash
kubectl get deployment ci-cd-app -n staging-ahmad \
  --as=system:serviceaccount:staging-ahmad:drone-deployer
```

**Expected output:**
```
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
ci-cd-app   1/1     1            1           2m
```

✅ **Result:** ServiceAccount CAN read deployments

### Step 4: Test UPDATE Permission (Should SUCCEED)

```bash
kubectl patch deployment ci-cd-app -n staging-ahmad \
  --type=json \
  -p='[{"op": "replace", "path": "/spec/replicas", "value": 2}]' \
  --as=system:serviceaccount:staging-ahmad:drone-deployer
```

**Expected output:**
```
deployment.apps/ci-cd-app patched
```

✅ **Result:** ServiceAccount CAN update deployments

### Step 5: Test DELETE Permission (Should FAIL - This Proves PoLP!)

```bash
kubectl delete deployment ci-cd-app -n staging-ahmad \
  --as=system:serviceaccount:staging-ahmad:drone-deployer
```

**Expected output (MUST SEE THIS):**
```
Error from server (Forbidden): deployments.apps "ci-cd-app" is forbidden:
User "system:serviceaccount:staging-ahmad:drone-deployer" cannot delete
resource "deployments" in API group "apps" in the namespace "staging-ahmad"
```

✅ **Result:** ServiceAccount CANNOT delete deployments

🎉 **This proves PoLP is working correctly!**

---

## Automated Verification Script

### Usage

```bash
# Make script executable
chmod +x scripts/verify-rbac.sh

# Run verification
./scripts/verify-rbac.sh staging-ahmad
```

### Script Output

```
=========================================
RBAC PoLP Verification Script
=========================================
Namespace: staging-ahmad
ServiceAccount: drone-deployer
=========================================

Test 1: Verifying UPDATE permission...
✅ PASS - ServiceAccount CAN read deployment

Test 2: Verifying PATCH permission...
✅ PASS - ServiceAccount CAN patch deployment

Test 3: Verifying DELETE is FORBIDDEN (proves PoLP)...
✅ PASS (PoLP VERIFIED!) - ServiceAccount CANNOT delete deployment
This proves Principle of Least Privilege is working correctly!

Test 4: Verifying pod LIST permission...
✅ PASS - ServiceAccount CAN list pods

=========================================
RBAC Verification Summary
=========================================
✅ ServiceAccount HAS permissions:
   - GET deployment
   - PATCH deployment
   - LIST pods

⛔ ServiceAccount DOES NOT HAVE permissions:
   - DELETE deployment (proves PoLP!)

🎉 All RBAC tests passed!
Principle of Least Privilege (PoLP) is correctly implemented.
=========================================
```

---

## Screenshot Requirements for Grading

**You MUST capture a screenshot showing:**

### Screenshot 1: DELETE Command Forbidden

```bash
kubectl delete deployment ci-cd-app -n staging-ahmad \
  --as=system:serviceaccount:staging-ahmad:drone-deployer
```

**Screenshot must clearly show:**
- The full command
- Error message containing "Forbidden"
- Error message containing the ServiceAccount name
- Error message stating "cannot delete resource"

**Example:**
```
$ kubectl delete deployment ci-cd-app -n staging-ahmad \
>   --as=system:serviceaccount:staging-ahmad:drone-deployer

Error from server (Forbidden): deployments.apps "ci-cd-app" is forbidden:
User "system:serviceaccount:staging-ahmad:drone-deployer" cannot delete
resource "deployments" in API group "apps" in the namespace "staging-ahmad"
```

### Screenshot 2: Verification Script Success

```bash
./scripts/verify-rbac.sh staging-ahmad
```

**Screenshot must show:**
- All tests passing (✅)
- Specific test for DELETE being forbidden
- Summary showing PoLP is verified

---

## Understanding the Verification

### Why These Tests Prove PoLP?

1. **GET/UPDATE Tests Pass:**
   - Proves ServiceAccount has necessary permissions for CI/CD
   - Can read and modify deployments (needed for deployment updates)

2. **DELETE Test Fails:**
   - Proves ServiceAccount does NOT have excessive permissions
   - Cannot accidentally delete production deployments
   - Follows "least privilege" principle

3. **Combination:**
   - ServiceAccount has exactly the permissions it needs, no more
   - This is the definition of PoLP ✅

### What Would Happen Without PoLP?

Without PoLP (if DELETE was allowed):
```yaml
# BAD EXAMPLE - DO NOT USE
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["*"]  # ALL permissions including delete
```

**Problems:**
- CI/CD pipeline could accidentally delete production
- Single command error = production down
- No safety net
- Violates security best practices

---

## Advanced Verification

### Check All Permissions

```bash
# List what the ServiceAccount can do
kubectl auth can-i --list \
  --as=system:serviceaccount:staging-ahmad:drone-deployer \
  -n staging-ahmad
```

**Expected output (partial):**
```
Resources                                    Verbs
deployments.apps                             [get list watch create update patch]
replicasets.apps                             [get list watch]
pods                                         [get list watch]
pods/log                                     [get list]
```

**Note:** `delete` should NOT appear for deployments

### Test Individual Permissions

```bash
# Can GET? (Should be YES)
kubectl auth can-i get deployments \
  --as=system:serviceaccount:staging-ahmad:drone-deployer \
  -n staging-ahmad

# Can UPDATE? (Should be YES)
kubectl auth can-i update deployments \
  --as=system:serviceaccount:staging-ahmad:drone-deployer \
  -n staging-ahmad

# Can DELETE? (Should be NO - proves PoLP!)
kubectl auth can-i delete deployments \
  --as=system:serviceaccount:staging-ahmad:drone-deployer \
  -n staging-ahmad
```

**Expected outputs:**
```
yes  # GET - allowed
yes  # UPDATE - allowed
no   # DELETE - forbidden (proves PoLP!)
```

---

## Troubleshooting RBAC

### Problem: DELETE is Not Forbidden

**Symptoms:**
- DELETE command succeeds (should fail)
- `kubectl auth can-i delete deployments` returns `yes`

**Solution:**

1. Check Role permissions:
   ```bash
   kubectl get role deployment-manager -n staging-ahmad -o yaml
   ```

2. Verify DELETE is NOT in verbs list:
   ```yaml
   rules:
     - apiGroups: ["apps"]
       resources: ["deployments"]
       verbs: ["get", "list", "watch", "create", "update", "patch"]
       # DELETE should NOT be here!
   ```

3. If DELETE is present, edit the role:
   ```bash
   kubectl edit role deployment-manager -n staging-ahmad
   # Remove "delete" from verbs list
   ```

4. Or reapply RBAC:
   ```bash
   kubectl delete -f k8s/rbac.yaml -n staging-ahmad
   kubectl apply -f k8s/rbac.yaml -n staging-ahmad
   ```

### Problem: UPDATE is Forbidden

**Symptoms:**
- UPDATE/PATCH commands fail
- CI/CD pipeline cannot deploy

**Solution:**

1. Verify Role includes UPDATE and PATCH:
   ```yaml
   verbs: ["get", "list", "watch", "create", "update", "patch"]
   ```

2. Reapply RBAC if needed:
   ```bash
   kubectl apply -f k8s/rbac.yaml -n staging-ahmad
   ```

### Problem: ServiceAccount Not Found

**Symptoms:**
```
Error: User "system:serviceaccount:staging-ahmad:drone-deployer" cannot ...
serviceaccount "drone-deployer" not found
```

**Solution:**

1. Create ServiceAccount:
   ```bash
   kubectl apply -f k8s/rbac.yaml -n staging-ahmad
   ```

2. Verify it exists:
   ```bash
   kubectl get sa drone-deployer -n staging-ahmad
   ```

---

## Why PoLP Matters

### Security Benefits

1. **Prevents Accidental Deletion:**
   - CI/CD script error won't delete production
   - Human error protection

2. **Audit Trail:**
   - Deletion requires admin access
   - Can track who deleted what

3. **Compliance:**
   - Meets security standards (SOC 2, ISO 27001)
   - Demonstrates security awareness

### Real-World Example

**Without PoLP:**
```bash
# Oops! Wrong namespace variable
kubectl delete deployment myapp -n $WRONG_NAMESPACE
# Production deleted! 💥
```

**With PoLP:**
```bash
# Same mistake, but...
kubectl delete deployment myapp -n $WRONG_NAMESPACE \
  --as=system:serviceaccount:staging-ahmad:drone-deployer
# Error: Forbidden ✅ Production safe!
```

---

## Summary

### What ServiceAccount CAN Do:
- ✅ Read deployments (GET, LIST, WATCH)
- ✅ Create deployments (CREATE)
- ✅ Update deployments (UPDATE, PATCH)
- ✅ View pods and logs (monitoring)

### What ServiceAccount CANNOT Do:
- ❌ Delete deployments
- ❌ Delete pods
- ❌ Access secrets
- ❌ Modify RBAC rules

### Proof of PoLP:
```bash
kubectl delete deployment ci-cd-app -n staging-ahmad \
  --as=system:serviceaccount:staging-ahmad:drone-deployer
# → Error: Forbidden ✅
```

**This is what the lecturer wants to see!** 🎓

---

## References

- [Kubernetes RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Principle of Least Privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/overview/)

---

**📸 Remember to take screenshots of the DELETE command being forbidden for your submission!**
