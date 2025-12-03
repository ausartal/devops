# Pre-Submission Checklist

Use this checklist to verify everything is ready before submitting your project.

---

## 📋 File Verification

### Core Files
- [ ] `.drone.yml` exists and has 4 stages
- [ ] `Dockerfile` exists and builds successfully
- [ ] `README-DRONE.md` is complete and readable
- [ ] `package.json` configured correctly

### Kubernetes Manifests
- [ ] `k8s/deployment.yaml` exists
- [ ] `k8s/service.yaml` exists
- [ ] `k8s/rbac.yaml` exists
- [ ] `k8s/namespaces.yaml` exists
- [ ] `k8s/imagePullSecret.yaml` exists (example)

### Scripts
- [ ] `scripts/deploy-k8s.sh` exists and is executable
- [ ] `scripts/verify-rbac.sh` exists and is executable

### Documentation
- [ ] `docs/TROUBLESHOOTING.md` exists
- [ ] `docs/RBAC_VERIFICATION.md` exists
- [ ] `docs/FLOWCHART.md` exists
- [ ] `docs/DRONE_PROJECT_SUMMARY.md` exists

---

## 🔧 Pipeline Configuration

### .drone.yml Structure
- [ ] Has `build` stage (npm ci, lint, test)
- [ ] Has `publish` stage (docker build & push)
- [ ] Has `trivy-scan` stage
- [ ] Has `deploy-to-dev` stage
- [ ] Has `deploy-to-staging` stage
- [ ] Trivy stage has `--exit-code 1`
- [ ] Trivy stage is between publish and deploy
- [ ] deploy-to-staging has `trigger: manual`

### Branch Configuration
- [ ] main branch triggers deploy-to-dev
- [ ] staging branch triggers deploy-to-staging
- [ ] Correct namespaces used (dev-ahmad, staging-ahmad)

---

## 🔐 Security Configuration

### ImagePullSecret
- [ ] deployment.yaml has `imagePullSecrets:` section
- [ ] imagePullSecret.yaml shows creation example
- [ ] Secret created in dev-ahmad namespace
- [ ] Secret created in staging-ahmad namespace

### RBAC (Principle of Least Privilege)
- [ ] rbac.yaml has ServiceAccount
- [ ] rbac.yaml has Role
- [ ] rbac.yaml has RoleBinding
- [ ] Role has: get, list, watch, create, update, patch
- [ ] Role does NOT have: delete
- [ ] RBAC applied to staging-ahmad namespace

---

## ☸️ Kubernetes Setup

### Namespaces
- [ ] dev-ahmad namespace exists
- [ ] staging-ahmad namespace exists

### Secrets
- [ ] harbor-registry-secret exists in dev-ahmad
- [ ] harbor-registry-secret exists in staging-ahmad

### RBAC Resources
- [ ] ServiceAccount drone-deployer exists in staging-ahmad
- [ ] Role deployment-manager exists in staging-ahmad
- [ ] RoleBinding drone-deployer-binding exists in staging-ahmad

### Verification Commands
```bash
# Check namespaces
kubectl get ns | grep ahmad

# Check secrets
kubectl get secret harbor-registry-secret -n dev-ahmad
kubectl get secret harbor-registry-secret -n staging-ahmad

# Check RBAC
kubectl get sa,role,rolebinding -n staging-ahmad
```

---

## 🔍 Drone CI Configuration

### Secrets
- [ ] docker_username secret added to Drone
- [ ] docker_password secret added to Drone
- [ ] kube_config secret added to Drone (base64 encoded)
- [ ] slack_webhook secret added (optional)

### Repository
- [ ] Repository activated in Drone
- [ ] Webhook configured
- [ ] .drone.yml syntax validated (`drone lint .drone.yml`)

---

## 🧪 Testing & Verification

### Local Tests
- [ ] Application builds locally (`npm install && npm test`)
- [ ] Docker image builds (`docker build -t test .`)
- [ ] Kubernetes manifests valid (`kubectl apply --dry-run=client -f k8s/`)

### RBAC Verification
- [ ] Ran verify-rbac.sh script
- [ ] All tests passed
- [ ] DELETE command returns Forbidden

### Manual Verification
```bash
# This command MUST return Forbidden error
kubectl delete deployment ci-cd-app -n staging-ahmad \
  --as=system:serviceaccount:staging-ahmad:drone-deployer
```

- [ ] Command executed
- [ ] Result shows "Forbidden"
- [ ] Screenshot captured

---

## 📸 Screenshots Captured

- [ ] Screenshot 1: Drone Pipeline Success (all 4 stages green)
- [ ] Screenshot 2: Manual Approval UI (waiting for approval)
- [ ] Screenshot 3: Trivy Scan Results (no HIGH/CRITICAL)
- [ ] Screenshot 4: RBAC DELETE Forbidden (critical!)
- [ ] Screenshot 5: Kubernetes Deployments (kubectl get all)
- [ ] Screenshot 6: ImagePullSecret (kubectl get secret)

### Screenshot Quality Checklist
- [ ] Screenshots are clear and readable
- [ ] Screenshots show full commands
- [ ] Screenshots show full output
- [ ] Screenshots include timestamps (if possible)
- [ ] Screenshots clearly demonstrate requirements

---

## 📝 Documentation Review

### README-DRONE.md
- [ ] Table of contents complete
- [ ] Project overview clear
- [ ] Level 3 requirements checklist included
- [ ] Architecture diagram present
- [ ] Prerequisites listed
- [ ] Quick start guide complete
- [ ] Setup instructions detailed
- [ ] Pipeline explanation clear
- [ ] RBAC section comprehensive
- [ ] Testing & verification steps included
- [ ] Troubleshooting section present
- [ ] Screenshots requirements documented

### TROUBLESHOOTING.md
- [ ] Pipeline issues covered
- [ ] Kubernetes issues covered
- [ ] RBAC issues covered
- [ ] Security scanning issues covered
- [ ] Solutions provided for each issue

### RBAC_VERIFICATION.md
- [ ] PoLP explained
- [ ] Manual verification steps detailed
- [ ] Automated script usage documented
- [ ] Screenshot requirements clear
- [ ] Why it proves PoLP explained

### FLOWCHART.md
- [ ] Complete pipeline flow shown
- [ ] Stage breakdowns included
- [ ] Branch strategy visualized
- [ ] Success and failure paths shown

---

## 🚀 Deployment Testing

### DEV Deployment
- [ ] Pushed to main branch
- [ ] Pipeline triggered automatically
- [ ] Build stage passed
- [ ] Publish stage passed
- [ ] Trivy scan passed
- [ ] Deploy to dev-ahmad succeeded
- [ ] Pods running in dev-ahmad
- [ ] Service accessible

### STAGING Deployment
- [ ] Pushed to staging branch
- [ ] Pipeline triggered
- [ ] Build stage passed
- [ ] Publish stage passed
- [ ] Trivy scan passed
- [ ] Pipeline paused for approval
- [ ] Clicked "PROMOTE" in Drone UI
- [ ] RBAC applied
- [ ] Deploy to staging-ahmad succeeded
- [ ] Pods running in staging-ahmad
- [ ] Service accessible

---

## 🎯 Final Verification

### Rubric Requirements
- [ ] Security (PoLP) - 40 points
  - [ ] ImagePullSecret implemented
  - [ ] RBAC with minimal permissions
  - [ ] DELETE forbidden (proven)
- [ ] Workflow Control - 30 points
  - [ ] Two environments (dev, staging)
  - [ ] Manual approval for staging
- [ ] Stages & Tools - 20 points
  - [ ] All 4 stages present
  - [ ] Trivy positioned correctly
  - [ ] Trivy fails on HIGH/CRITICAL
- [ ] Documentation - 10 points
  - [ ] Complete README
  - [ ] Setup instructions
  - [ ] Troubleshooting guide

### Score Calculation
- Security: ___/40
- Workflow: ___/30
- Stages: ___/20
- Documentation: ___/10
- **Total: ___/100**

Target: 86-100 (Level 3)

---

## 📦 Submission Package

### Files to Submit
- [ ] All source code files
- [ ] .drone.yml
- [ ] All k8s/*.yaml files
- [ ] All scripts/*.sh files
- [ ] All docs/*.md files
- [ ] README-DRONE.md
- [ ] Screenshots (6 images)

### Submission Format
- [ ] Repository URL provided
- [ ] Screenshots in separate folder
- [ ] README-DRONE.md as main documentation
- [ ] All files committed to Git
- [ ] Repository accessible to lecturer

---

## ✅ Pre-Submission Final Checks

### Code Quality
- [ ] No commented-out code
- [ ] No TODO comments remaining
- [ ] No hardcoded passwords or secrets
- [ ] YAML files properly formatted
- [ ] Scripts have proper permissions (chmod +x)

### Documentation
- [ ] No typos in README
- [ ] All links working (if any)
- [ ] Code examples accurate
- [ ] Commands tested and verified
- [ ] Screenshots match current setup

### Functionality
- [ ] Pipeline runs end-to-end successfully
- [ ] Both environments deployable
- [ ] RBAC verification works
- [ ] No errors in Kubernetes
- [ ] Application accessible

---

## 🎓 Lecturer Expectations

Based on rubric, lecturer expects to see:

1. **Working Pipeline**
   - [ ] Runs without errors
   - [ ] All stages complete
   - [ ] Manual approval functional

2. **Security Implementation**
   - [ ] ImagePullSecret used
   - [ ] RBAC with PoLP proven
   - [ ] DELETE command forbidden

3. **Documentation**
   - [ ] Clear setup instructions
   - [ ] Comprehensive guide
   - [ ] Screenshots proving implementation

4. **Professional Quality**
   - [ ] Clean code
   - [ ] Well organized
   - [ ] Production-ready

---

## 📞 Last-Minute Issues?

If you find issues before submission:

1. Check TROUBLESHOOTING.md
2. Run verify-rbac.sh script
3. Review README-DRONE.md setup steps
4. Test deployments manually
5. Verify all screenshots

---

## ✨ Ready for Submission?

**Only check this box when ALL above items are checked:**

- [ ] **I have verified every item on this checklist**
- [ ] **All 6 screenshots are captured and clear**
- [ ] **RBAC DELETE command shows Forbidden**
- [ ] **Pipeline runs successfully end-to-end**
- [ ] **Documentation is complete and accurate**

---

**If all boxes are checked, you're ready to submit!** 🎉

**Expected Grade: 86-100 (Level 3)** 🏆

---

Good luck! 🚀
