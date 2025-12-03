# Troubleshooting Guide - Drone CI/CD + Kubernetes

This guide provides solutions to common issues you may encounter when running the Level 3 CI/CD pipeline.

---

## Table of Contents

1. [Pipeline Issues](#pipeline-issues)
2. [Kubernetes Issues](#kubernetes-issues)
3. [RBAC Issues](#rbac-issues)
4. [Security Scanning Issues](#security-scanning-issues)
5. [Deployment Issues](#deployment-issues)
6. [Networking Issues](#networking-issues)

---

## Pipeline Issues

### Issue 1: Pipeline Not Triggering

**Symptoms:**
- Git push doesn't trigger Drone pipeline
- No builds appear in Drone UI

**Diagnosis:**
```bash
# Check webhook configuration
drone repo info yourusername/drone-k8s-cicd

# Check repository activation
drone repo ls
```

**Solutions:**

1. **Activate repository in Drone:**
   - Go to Drone UI → Repositories
   - Find your repository
   - Click "ACTIVATE"

2. **Check webhook:**
   - GitHub/GitLab → Settings → Webhooks
   - Verify Drone webhook exists
   - Check recent deliveries for errors

3. **Verify `.drone.yml` syntax:**
   ```bash
   drone lint .drone.yml
   ```

### Issue 2: Secret Not Found

**Symptoms:**
```
Error: secret "docker_username" not found
```

**Solutions:**

1. **Add secrets via Drone CLI:**
   ```bash
   drone secret add \
     --repository yourusername/drone-k8s-cicd \
     --name docker_username \
     --data your-username

   drone secret add \
     --repository yourusername/drone-k8s-cicd \
     --name docker_password \
     --data your-password
   ```

2. **Add secrets via Drone UI:**
   - Repository → Settings → Secrets
   - Add each required secret

3. **Verify secrets exist:**
   ```bash
   drone secret ls --repository yourusername/drone-k8s-cicd
   ```

### Issue 3: Branch Filter Not Working

**Symptoms:**
- Pipeline runs on wrong branches
- Staging deployment triggers on main branch

**Solutions:**

1. **Check branch filter in `.drone.yml`:**
   ```yaml
   when:
     branch:
       - main  # Only main branch
   ```

2. **Verify current branch:**
   ```bash
   git branch --show-current
   ```

3. **Check Drone build logs for branch name:**
   ```
   DRONE_BRANCH=main
   ```

---

## Kubernetes Issues

### Issue 1: ImagePullBackOff

**Symptoms:**
```bash
kubectl get pods -n dev-ahmad
NAME                         READY   STATUS             RESTARTS   AGE
ci-cd-app-xxx-yyy           0/1     ImagePullBackOff   0          2m
```

**Diagnosis:**
```bash
# Check pod events
kubectl describe pod ci-cd-app-xxx-yyy -n dev-ahmad

# Check if secret exists
kubectl get secret harbor-registry-secret -n dev-ahmad
```

**Solutions:**

1. **Create ImagePullSecret:**
   ```bash
   kubectl create secret docker-registry harbor-registry-secret \
     --docker-server=harbor.example.com \
     --docker-username=your-username \
     --docker-password=your-password \
     --docker-email=your-email@example.com \
     -n dev-ahmad
   ```

2. **Verify secret content:**
   ```bash
   kubectl get secret harbor-registry-secret -n dev-ahmad -o jsonpath='{.data.\.dockerconfigjson}' | base64 --decode
   ```

3. **Check deployment uses secret:**
   ```bash
   kubectl get deployment ci-cd-app -n dev-ahmad -o yaml | grep -A2 imagePullSecrets
   ```

4. **Verify image exists in registry:**
   ```bash
   docker pull harbor.example.com/library/ci-cd-app:main-latest
   ```

### Issue 2: CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods -n dev-ahmad
NAME                         READY   STATUS             RESTARTS   AGE
ci-cd-app-xxx-yyy           0/1     CrashLoopBackOff   3          3m
```

**Diagnosis:**
```bash
# Check pod logs
kubectl logs ci-cd-app-xxx-yyy -n dev-ahmad

# Check previous container logs
kubectl logs ci-cd-app-xxx-yyy -n dev-ahmad --previous

# Describe pod
kubectl describe pod ci-cd-app-xxx-yyy -n dev-ahmad
```

**Solutions:**

1. **Check application errors in logs:**
   ```bash
   kubectl logs -f ci-cd-app-xxx-yyy -n dev-ahmad
   ```

2. **Verify environment variables:**
   ```bash
   kubectl get deployment ci-cd-app -n dev-ahmad -o yaml | grep -A10 env:
   ```

3. **Check health probe configuration:**
   ```bash
   kubectl get deployment ci-cd-app -n dev-ahmad -o yaml | grep -A10 livenessProbe
   ```

4. **Increase initial delay:**
   ```yaml
   livenessProbe:
     initialDelaySeconds: 60  # Increase if app needs more startup time
   ```

### Issue 3: Namespace Not Found

**Symptoms:**
```
Error: namespaces "dev-ahmad" not found
```

**Solutions:**

1. **Create namespace:**
   ```bash
   kubectl create namespace dev-ahmad
   ```

2. **Or apply namespace manifest:**
   ```bash
   kubectl apply -f k8s/namespaces.yaml
   ```

3. **Verify namespace exists:**
   ```bash
   kubectl get namespaces | grep ahmad
   ```

---

## RBAC Issues

### Issue 1: ServiceAccount Not Found

**Symptoms:**
```
Error: serviceaccounts "drone-deployer" not found
```

**Solutions:**

1. **Apply RBAC configuration:**
   ```bash
   kubectl apply -f k8s/rbac.yaml -n staging-ahmad
   ```

2. **Verify ServiceAccount exists:**
   ```bash
   kubectl get serviceaccount drone-deployer -n staging-ahmad
   ```

3. **Check all RBAC resources:**
   ```bash
   kubectl get sa,role,rolebinding -n staging-ahmad
   ```

### Issue 2: DELETE Not Forbidden (PoLP Not Working)

**Symptoms:**
- DELETE command succeeds (should fail)
- PoLP verification test fails

**Diagnosis:**
```bash
# This should FAIL but doesn't
kubectl delete deployment ci-cd-app -n staging-ahmad \
  --as=system:serviceaccount:staging-ahmad:drone-deployer --dry-run=server
```

**Solutions:**

1. **Check Role permissions:**
   ```bash
   kubectl get role deployment-manager -n staging-ahmad -o yaml
   ```

2. **Verify DELETE is NOT in verbs list:**
   ```yaml
   rules:
     - apiGroups: ["apps"]
       resources: ["deployments"]
       verbs: ["get", "list", "watch", "create", "update", "patch"]
       # DELETE should NOT be here!
   ```

3. **Reapply RBAC:**
   ```bash
   kubectl delete -f k8s/rbac.yaml -n staging-ahmad
   kubectl apply -f k8s/rbac.yaml -n staging-ahmad
   ```

4. **Verify RoleBinding:**
   ```bash
   kubectl get rolebinding drone-deployer-binding -n staging-ahmad -o yaml
   ```

### Issue 3: Deployment Forbidden (Too Restrictive)

**Symptoms:**
```
Error: User "system:serviceaccount:staging-ahmad:drone-deployer" cannot update
resource "deployments" in API group "apps" in the namespace "staging-ahmad"
```

**Solutions:**

1. **Check if Role includes UPDATE:**
   ```yaml
   rules:
     - apiGroups: ["apps"]
       resources: ["deployments"]
       verbs: ["get", "list", "watch", "create", "update", "patch"]  # Need update & patch
   ```

2. **Reapply RBAC with correct permissions:**
   ```bash
   kubectl apply -f k8s/rbac.yaml -n staging-ahmad
   ```

3. **Test UPDATE permission:**
   ```bash
   kubectl patch deployment ci-cd-app -n staging-ahmad \
     --type=json -p='[{"op": "replace", "path": "/spec/replicas", "value": 2}]' \
     --as=system:serviceaccount:staging-ahmad:drone-deployer --dry-run=server
   ```

---

## Security Scanning Issues

### Issue 1: Trivy Scan Fails Pipeline

**Symptoms:**
```
Error: HIGH/CRITICAL vulnerabilities found
Exit code 1
Pipeline failed at trivy-scan stage
```

**Diagnosis:**
```bash
# Run Trivy locally
docker pull harbor.example.com/library/ci-cd-app:main-latest
trivy image --severity HIGH,CRITICAL harbor.example.com/library/ci-cd-app:main-latest
```

**Solutions:**

1. **Fix npm vulnerabilities:**
   ```bash
   npm audit
   npm audit fix
   npm audit fix --force  # If needed
   ```

2. **Update base image:**
   ```dockerfile
   # Use latest patch version
   FROM node:18.19-alpine  # Instead of node:18-alpine
   ```

3. **Update dependencies:**
   ```bash
   npm update
   npm outdated  # Check for updates
   ```

4. **Temporary bypass (TESTING ONLY):**
   ```yaml
   # In .drone.yml (NOT for production!)
   - trivy image --severity HIGH,CRITICAL --exit-code 0 <image>
   ```

### Issue 2: Trivy Cannot Pull Image

**Symptoms:**
```
Error: unable to pull image: authentication required
```

**Solutions:**

1. **Login to registry in Trivy step:**
   ```yaml
   - name: trivy-scan
     image: aquasec/trivy:latest
     environment:
       TRIVY_USERNAME:
         from_secret: docker_username
       TRIVY_PASSWORD:
         from_secret: docker_password
     commands:
       - trivy image --username $TRIVY_USERNAME --password $TRIVY_PASSWORD <image>
   ```

2. **Use public image for testing:**
   ```yaml
   # Publish to public registry temporarily
   registry: docker.io
   ```

---

## Deployment Issues

### Issue 1: Rollout Stuck

**Symptoms:**
```
Waiting for deployment "ci-cd-app" rollout to finish: 1 old replicas are pending termination...
```

**Diagnosis:**
```bash
# Check rollout status
kubectl rollout status deployment/ci-cd-app -n dev-ahmad

# Check pod events
kubectl get events -n dev-ahmad --sort-by='.lastTimestamp'
```

**Solutions:**

1. **Check pod resources:**
   ```bash
   kubectl describe nodes
   kubectl top nodes
   ```

2. **Reduce resource requests:**
   ```yaml
   resources:
     requests:
       memory: "64Mi"   # Reduce if cluster low on resources
       cpu: "50m"
   ```

3. **Force rollout:**
   ```bash
   kubectl rollout restart deployment/ci-cd-app -n dev-ahmad
   ```

4. **Manual pod deletion:**
   ```bash
   kubectl delete pod -l app=ci-cd-app -n dev-ahmad
   ```

### Issue 2: Image Not Updated

**Symptoms:**
- Deployment succeeds but old image still running
- Changes not reflected in application

**Solutions:**

1. **Check image tag:**
   ```bash
   kubectl get deployment ci-cd-app -n dev-ahmad -o jsonpath='{.spec.template.spec.containers[0].image}'
   ```

2. **Verify imagePullPolicy:**
   ```yaml
   imagePullPolicy: Always  # Force pull every time
   ```

3. **Force new rollout:**
   ```bash
   kubectl rollout restart deployment/ci-cd-app -n dev-ahmad
   ```

4. **Check if IMAGE_PLACEHOLDER was replaced:**
   ```bash
   # Should NOT see IMAGE_PLACEHOLDER
   kubectl get deployment ci-cd-app -n dev-ahmad -o yaml | grep image:
   ```

---

## Networking Issues

### Issue 1: Service Not Accessible

**Symptoms:**
- Cannot access application via service
- Connection timeout

**Diagnosis:**
```bash
# Check service
kubectl get svc ci-cd-app -n dev-ahmad

# Check endpoints
kubectl get endpoints ci-cd-app -n dev-ahmad

# Check pods
kubectl get pods -l app=ci-cd-app -n dev-ahmad
```

**Solutions:**

1. **Verify service selector matches pod labels:**
   ```bash
   # Service selector
   kubectl get svc ci-cd-app -n dev-ahmad -o jsonpath='{.spec.selector}'
   
   # Pod labels
   kubectl get pods -l app=ci-cd-app -n dev-ahmad -o jsonpath='{.items[0].metadata.labels}'
   ```

2. **Test pod directly:**
   ```bash
   # Port forward to pod
   POD_NAME=$(kubectl get pods -l app=ci-cd-app -n dev-ahmad -o jsonpath='{.items[0].metadata.name}')
   kubectl port-forward -n dev-ahmad $POD_NAME 8080:3000
   curl http://localhost:8080/health
   ```

3. **Check pod logs:**
   ```bash
   kubectl logs -f -l app=ci-cd-app -n dev-ahmad
   ```

### Issue 2: Health Check Failing

**Symptoms:**
```
Readiness probe failed: HTTP probe failed with statuscode: 404
```

**Solutions:**

1. **Verify health endpoint exists:**
   ```bash
   # Port forward and test
   kubectl port-forward -n dev-ahmad svc/ci-cd-app 8080:80
   curl http://localhost:8080/health
   ```

2. **Check probe configuration:**
   ```yaml
   readinessProbe:
     httpGet:
       path: /health  # Verify this path exists
       port: http     # Verify port name matches
   ```

3. **Increase initial delay:**
   ```yaml
   readinessProbe:
     initialDelaySeconds: 30  # Give app more time to start
   ```

---

## General Debugging Commands

### Get Full Deployment State
```bash
kubectl get all -n dev-ahmad
kubectl describe deployment ci-cd-app -n dev-ahmad
kubectl get events -n dev-ahmad --sort-by='.lastTimestamp'
```

### Check Logs
```bash
# All pods
kubectl logs -l app=ci-cd-app -n dev-ahmad

# Specific pod
kubectl logs pod-name -n dev-ahmad

# Follow logs
kubectl logs -f -l app=ci-cd-app -n dev-ahmad
```

### Interactive Debugging
```bash
# Exec into pod
kubectl exec -it pod-name -n dev-ahmad -- /bin/sh

# Run debug pod
kubectl run debug --image=alpine -it --rm -n dev-ahmad -- /bin/sh
```

### RBAC Debugging
```bash
# Check what ServiceAccount can do
kubectl auth can-i --list \
  --as=system:serviceaccount:staging-ahmad:drone-deployer \
  -n staging-ahmad

# Test specific permission
kubectl auth can-i delete deployments \
  --as=system:serviceaccount:staging-ahmad:drone-deployer \
  -n staging-ahmad
```

---

## Quick Fix Checklist

Before asking for help, verify:

- [ ] Namespaces exist (`kubectl get ns | grep ahmad`)
- [ ] ImagePullSecrets exist in both namespaces
- [ ] RBAC applied to staging namespace
- [ ] Docker image exists in registry
- [ ] Drone secrets configured correctly
- [ ] `.drone.yml` syntax is valid (`drone lint`)
- [ ] Kubernetes cluster is healthy (`kubectl get nodes`)
- [ ] Pods are running (`kubectl get pods -n dev-ahmad`)

---

## Still Having Issues?

1. **Check Drone logs:**
   - Drone UI → Build → Click on failed step → View logs

2. **Check Kubernetes events:**
   ```bash
   kubectl get events -n dev-ahmad --sort-by='.lastTimestamp' | tail -20
   ```

3. **Run verification script:**
   ```bash
   chmod +x scripts/verify-rbac.sh
   ./scripts/verify-rbac.sh staging-ahmad
   ```

4. **Compare with working example:**
   - Review this repository's configuration
   - Check for typos in namespace names, secret names, etc.

---

**Remember:** Most issues are due to:
1. Missing secrets or incorrect credentials
2. Typos in namespace names
3. RBAC not applied
4. Image doesn't exist in registry

Good luck! 🚀
