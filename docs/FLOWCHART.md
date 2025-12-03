# CI/CD Pipeline Flowchart

This document provides a visual representation of the Drone CI/CD pipeline flow.

---

## Complete Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        GIT REPOSITORY                            │
│                                                                   │
│  ┌──────────┐                           ┌──────────┐            │
│  │  main    │                           │ staging  │            │
│  │  branch  │                           │  branch  │            │
│  └────┬─────┘                           └────┬─────┘            │
│       │                                      │                   │
│       │ git push                             │ git push          │
│       │                                      │                   │
└───────┼──────────────────────────────────────┼──────────────────┘
        │                                      │
        ▼                                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DRONE CI TRIGGER                          │
│  • Webhook receives push event                                  │
│  • Clones repository                                            │
│  • Reads .drone.yml                                             │
│  • Starts pipeline execution                                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │      STAGE 1: BUILD                    │
        │  ┌──────────────────────────────────┐  │
        │  │  • npm ci                        │  │
        │  │  • npm run lint                  │  │
        │  │  • npm test                      │  │
        │  │  • npm run build                 │  │
        │  └──────────────────────────────────┘  │
        │         Environment: node:18-alpine    │
        │         Trigger: main OR staging       │
        └────────────────┬───────────────────────┘
                         │
                    ✅ SUCCESS
                         │
                         ▼
        ┌────────────────────────────────────────┐
        │      STAGE 2: PUBLISH                  │
        │  ┌──────────────────────────────────┐  │
        │  │  • Build Docker image            │  │
        │  │  • Tag: branch-sha8              │  │
        │  │  • Tag: branch-latest            │  │
        │  │  • Push to Harbor/DockerHub      │  │
        │  └──────────────────────────────────┘  │
        │         Plugin: plugins/docker         │
        │         Trigger: push to main/staging  │
        └────────────────┬───────────────────────┘
                         │
                    ✅ SUCCESS
                         │
                         ▼
        ┌────────────────────────────────────────┐
        │      STAGE 3: TRIVY SCAN               │
        │  ┌──────────────────────────────────┐  │
        │  │  • Pull image from registry      │  │
        │  │  • Scan for vulnerabilities      │  │
        │  │  • Check: HIGH/CRITICAL          │  │
        │  │  • Exit code 1 if found          │  │
        │  └──────────────────────────────────┘  │
        │         Image: aquasec/trivy:latest    │
        │         🚨 QUALITY GATE 🚨             │
        └────────────────┬───────────────────────┘
                         │
                    ┌────┴────┐
               ✅ PASS    ❌ FAIL
                    │            │
                    │            └──────> PIPELINE STOPS
                    │                    (Security issues found)
                    ▼
        ┌──────────────────────────────────┐
        │  Branch Decision Point           │
        │                                  │
        │  main branch?  staging branch?   │
        └────┬─────────────────────┬───────┘
             │                     │
    ┌────────┴────────┐   ┌────────┴────────┐
    │ main = YES      │   │ staging = YES   │
    │ staging = NO    │   │ main = NO       │
    └────┬────────────┘   └────┬────────────┘
         │                     │
         ▼                     ▼
┌────────────────────┐   ┌────────────────────┐
│ STAGE 4A:          │   │ STAGE 4B:          │
│ DEPLOY TO DEV      │   │ DEPLOY TO STAGING  │
│ (AUTOMATIC)        │   │ (MANUAL APPROVAL)  │
├────────────────────┤   ├────────────────────┤
│ • Namespace:       │   │ ⏸️  WAIT FOR       │
│   dev-ahmad        │   │   APPROVAL         │
│                    │   │                    │
│ • Setup kubectl    │   │ User clicks        │
│ • Create namespace │   │ "PROMOTE" in       │
│ • Apply deployment │   │ Drone UI           │
│ • Apply service    │   │                    │
│ • Wait rollout     │   │ ▼                  │
│ • Show status      │   │ ✅ APPROVED        │
│                    │   │                    │
│ ✅ DEPLOYED        │   │ • Namespace:       │
│                    │   │   staging-ahmad    │
│                    │   │ • Setup kubectl    │
│                    │   │ • Create namespace │
│                    │   │ • Apply RBAC       │
│                    │   │ • Apply deployment │
│                    │   │ • Apply service    │
│                    │   │ • Wait rollout     │
│                    │   │ • Verify PoLP      │
│                    │   │                    │
│                    │   │ ✅ DEPLOYED        │
└────────────────────┘   └────────────────────┘
         │                     │
         │                     │
         └──────────┬──────────┘
                    │
                    ▼
        ┌────────────────────────────────────────┐
        │      STAGE 5: NOTIFY (Optional)        │
        │  ┌──────────────────────────────────┐  │
        │  │  • Send Slack notification       │  │
        │  │  • Report: SUCCESS or FAILURE    │  │
        │  │  • Include: branch, commit, etc  │  │
        │  └──────────────────────────────────┘  │
        │         Trigger: Always (on finish)    │
        └────────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │  PIPELINE END  │
                    │  ✅ SUCCESS     │
                    └────────────────┘
```

---

## Detailed Stage Breakdown

### Stage 1: Build

```
┌──────────────────────────────────────┐
│          BUILD STAGE                 │
├──────────────────────────────────────┤
│ Container: node:18-alpine            │
│                                      │
│ Steps:                               │
│  1. npm ci                           │
│     └─> Install dependencies         │
│         (clean install)              │
│                                      │
│  2. npm run lint                     │
│     └─> ESLint checks                │
│         ├─> Code style               │
│         └─> Code quality             │
│                                      │
│  3. npm test                         │
│     └─> Run Jest tests               │
│         ├─> Unit tests               │
│         ├─> Integration tests        │
│         └─> Coverage report          │
│                                      │
│  4. npm run build                    │
│     └─> Build application            │
│                                      │
│ Exit Codes:                          │
│  0 = Success ✅                      │
│  1 = Failure ❌                      │
└──────────────────────────────────────┘
```

### Stage 2: Publish

```
┌──────────────────────────────────────┐
│        PUBLISH STAGE                 │
├──────────────────────────────────────┤
│ Plugin: plugins/docker               │
│                                      │
│ Steps:                               │
│  1. Read Dockerfile                  │
│  2. Build image:                     │
│     docker build -t <image>:<tag> .  │
│                                      │
│  3. Create tags:                     │
│     • main-a1b2c3d4                  │
│     • main-latest                    │
│     (or staging-x, staging-latest)   │
│                                      │
│  4. Login to registry:               │
│     docker login harbor.example.com  │
│                                      │
│  5. Push images:                     │
│     docker push <image>:<each-tag>   │
│                                      │
│ Credentials:                         │
│  • docker_username (secret)          │
│  • docker_password (secret)          │
└──────────────────────────────────────┘
```

### Stage 3: Trivy Scan (Quality Gate)

```
┌──────────────────────────────────────┐
│      TRIVY SECURITY SCAN             │
├──────────────────────────────────────┤
│ Container: aquasec/trivy:latest      │
│                                      │
│ Steps:                               │
│  1. Pull image from registry         │
│                                      │
│  2. Scan image:                      │
│     trivy image \                    │
│       --severity HIGH,CRITICAL \     │
│       --exit-code 1 \                │
│       <image>:<tag>                  │
│                                      │
│  3. Check results:                   │
│     ┌─────────────────────┐          │
│     │ No HIGH/CRITICAL?   │          │
│     └──┬──────────┬───────┘          │
│        │ YES      │ NO               │
│        ▼          ▼                  │
│     ✅ PASS    ❌ FAIL               │
│     Continue   STOP PIPELINE         │
│                                      │
│ 🚨 THIS IS THE QUALITY GATE 🚨       │
│    Pipeline cannot proceed if        │
│    vulnerabilities are found!        │
└──────────────────────────────────────┘
```

### Stage 4A: Deploy to DEV

```
┌──────────────────────────────────────┐
│      DEPLOY TO DEV (Automatic)       │
├──────────────────────────────────────┤
│ Container: bitnami/kubectl:latest    │
│ Namespace: dev-ahmad                 │
│ Trigger: Push to main branch         │
│                                      │
│ Steps:                               │
│  1. Setup kubectl:                   │
│     mkdir -p ~/.kube                 │
│     echo $KUBE_CONFIG > config       │
│                                      │
│  2. Create namespace (if needed):    │
│     kubectl create ns dev-ahmad      │
│                                      │
│  3. Replace IMAGE_PLACEHOLDER:       │
│     sed "s|IMAGE_PLACEHOLDER|        │
│         harbor.../ci-cd-app:tag|"    │
│                                      │
│  4. Apply manifests:                 │
│     kubectl apply -f deployment.yaml │
│     kubectl apply -f service.yaml    │
│                                      │
│  5. Wait for rollout:                │
│     kubectl rollout status \         │
│       deployment/ci-cd-app \         │
│       -n dev-ahmad                   │
│                                      │
│  6. Show status:                     │
│     kubectl get pods,svc -n dev-ahmad│
│                                      │
│ ✅ Deployment complete!              │
└──────────────────────────────────────┘
```

### Stage 4B: Deploy to STAGING

```
┌──────────────────────────────────────┐
│    DEPLOY TO STAGING (Manual)        │
├──────────────────────────────────────┤
│ Container: bitnami/kubectl:latest    │
│ Namespace: staging-ahmad             │
│ Trigger: Push to staging + MANUAL    │
│                                      │
│ ⏸️  MANUAL APPROVAL REQUIRED          │
│ ┌────────────────────────────────┐   │
│ │ Pipeline PAUSES here           │   │
│ │ User must click "PROMOTE"      │   │
│ │ in Drone UI                    │   │
│ └────────────────────────────────┘   │
│                                      │
│ After approval:                      │
│                                      │
│  1. Setup kubectl (same as dev)      │
│                                      │
│  2. Create namespace (if needed):    │
│     kubectl create ns staging-ahmad  │
│                                      │
│  3. Apply RBAC:                      │
│     kubectl apply -f rbac.yaml       │
│     └─> Creates ServiceAccount,      │
│         Role, RoleBinding            │
│                                      │
│  4. Apply deployment & service       │
│                                      │
│  5. Wait for rollout                 │
│                                      │
│  6. Show RBAC verification msg       │
│                                      │
│ ✅ Deployment complete!              │
│ 🔐 With PoLP RBAC!                   │
└──────────────────────────────────────┘
```

---

## Branch Strategy

```
main branch (development)
│
├─> Auto trigger on push
├─> Runs: Build → Publish → Scan → Deploy to DEV
└─> No manual approval needed
    ✅ Fast feedback for developers


staging branch (pre-production)
│
├─> Auto trigger on push
├─> Runs: Build → Publish → Scan → ⏸️  WAIT → Deploy to STAGING
│                                     │
│                                     └─> Manual approval required
└─> Allows review before staging deployment
    🔒 Controlled release process
```

---

## Security Gates

```
┌─────────────────────────────────────────┐
│         SECURITY CHECKPOINTS            │
├─────────────────────────────────────────┤
│                                         │
│  Gate 1: Code Quality                   │
│  ├─ ESLint (lint errors)                │
│  └─ Tests (test failures)               │
│     ❌ Fails → Stop pipeline            │
│                                         │
│  Gate 2: Security Scan                  │
│  ├─ Trivy scan                          │
│  └─ HIGH/CRITICAL vulns                 │
│     ❌ Found → Stop pipeline            │
│                                         │
│  Gate 3: Manual Approval (Staging)      │
│  ├─ Human review                        │
│  └─ Click to approve                    │
│     ⏸️  Not approved → Pipeline waits   │
│                                         │
│  Gate 4: RBAC PoLP (Staging)            │
│  ├─ ServiceAccount permissions          │
│  └─ Cannot delete deployments           │
│     🔒 Safety enforced                  │
│                                         │
└─────────────────────────────────────────┘
```

---

## Failure Scenarios

### Scenario 1: Build Fails

```
Build Stage → npm test fails
    │
    ▼
Pipeline STOPS ❌
    │
    ▼
Developer notified
    │
    ▼
Fix code → Push again
    │
    ▼
Pipeline restarts
```

### Scenario 2: Trivy Finds Vulnerabilities

```
Trivy Scan → HIGH vulnerability found
    │
    ▼
exit-code 1 → Pipeline FAILS ❌
    │
    ▼
Image NOT deployed
    │
    ▼
Developer fixes dependency
    │
    ▼
npm update → rebuild → rescan
```

### Scenario 3: Deployment Rollout Timeout

```
Deploy Stage → kubectl rollout status
    │
    ▼
Timeout after 300s
    │
    ▼
Pipeline FAILS ❌
    │
    ▼
Check pod events
    │
    ▼
Fix resource limits / health checks
```

---

## Success Path (Main Branch)

```
1. Developer: git push origin main
   ↓
2. Drone: Webhook triggered
   ↓
3. Build: ✅ All tests pass
   ↓
4. Publish: ✅ Image pushed to registry
   ↓
5. Trivy: ✅ No vulnerabilities
   ↓
6. Deploy: ✅ Deployed to dev-ahmad
   ↓
7. Verify: ✅ Pods running
   ↓
8. Notify: ✅ Slack notification sent
   ↓
COMPLETE! 🎉
```

---

## Success Path (Staging Branch)

```
1. Developer: git push origin staging
   ↓
2. Drone: Webhook triggered
   ↓
3. Build: ✅ All tests pass
   ↓
4. Publish: ✅ Image pushed to registry
   ↓
5. Trivy: ✅ No vulnerabilities
   ↓
6. Wait: ⏸️  Manual approval required
   ↓
7. Approver: Clicks "PROMOTE" button
   ↓
8. RBAC: ✅ ServiceAccount & Role created
   ↓
9. Deploy: ✅ Deployed to staging-ahmad
   ↓
10. Verify: ✅ Pods running, RBAC working
   ↓
11. Notify: ✅ Slack notification sent
   ↓
COMPLETE! 🎉
```

---

## Time Estimates

```
Stage            | Avg Time  | Max Time
-----------------+-----------+-----------
Build            | 1-2 min   | 5 min
Publish          | 2-3 min   | 10 min
Trivy Scan       | 1-2 min   | 5 min
Deploy (DEV)     | 30-60 sec | 5 min
Manual Approval  | Variable  | ∞
Deploy (Staging) | 30-60 sec | 5 min
-----------------+-----------+-----------
Total (DEV)      | 5-8 min   | 25 min
Total (Staging)  | + approval| + approval
```

---

## Pipeline Visualization (Simple)

```
[Git Push]
    ↓
[Build: 🔨]
    ↓
[Publish: 📦]
    ↓
[Scan: 🔍]
    ↓
   / \
  /   \
main   staging
 ↓       ↓
[DEV]  [⏸️ Approve]
 ✅       ↓
      [STAGING]
         ✅
```

---

## Key Takeaways

1. **4 Main Stages:** Build → Publish → Scan → Deploy
2. **Quality Gate:** Trivy scan prevents insecure deployments
3. **Two Environments:** dev (auto) and staging (manual)
4. **Security:** RBAC with PoLP in staging
5. **Manual Approval:** Required for staging deployments
6. **Fast Feedback:** ~5-8 min from push to deployment (dev)

---

**This flowchart demonstrates a professional CI/CD pipeline that satisfies all Level 3 requirements!** 🚀
