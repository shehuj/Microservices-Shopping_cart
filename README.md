# Shopping Cart

A Spring Boot shopping cart web application containerised with Docker, deployed to an AWS EKS cluster via GitHub Actions CI/CD with Terraform-managed infrastructure.

## Repository Structure

```
├── app/                        # Application code
│   ├── src/                    # Java source
│   ├── Dockerfile              # Container image definition
│   ├── pom.xml                 # Maven build
│   └── scripts/                # Local dev scripts
└── infra/                      # Infrastructure as code
    ├── eks/                    # EKS cluster Terraform (VPC, nodes, IAM)
    ├── main.tf                 # Kubernetes resource Terraform (namespace, secrets, policies)
    └── deploymentservice.yml   # Kubernetes app manifest
```

## Stack

| Layer | Technology |
|---|---|
| App | Spring Boot 1.5.3, Java 8, Spring Security, Spring Data JPA, Thymeleaf |
| Database | H2 (in-memory, dev/test) · MySQL (production) |
| Container | Docker → Docker Hub (`captcloud01/shopping-cart`) |
| Cluster | AWS EKS (Kubernetes 1.32, t3.medium nodes, 1–4 auto-scaled) |
| Networking | VPC with public + private subnets across 3 AZs, NAT Gateways |
| Infra-as-Code | Terraform (AWS + Kubernetes providers, S3 remote state) |
| CI/CD | GitHub Actions |

## Pipelines

### `infra.yml` — Infra Provision (`dev` branch)

Triggered on push to `dev` when `infra/**` changes, or manually via `workflow_dispatch`.
Runs in strict sequence — EKS cluster must exist before Kubernetes resources are created.

```
1 · EKS Cluster          infra/eks/  →  VPC, subnets, IAM roles, EKS cluster, node group
          │
          ▼  (needs: provision-eks)
2 · Kubernetes Resources  infra/      →  Namespace, Docker Hub pull secret, network policies, PDB
```

| Input | Behaviour |
|---|---|
| `plan` | Init → Validate → Plan only (no apply) |
| `apply` *(default on push)* | Init → Validate → Plan → Apply if changes detected |
| `destroy` | Destroy immediately, skipping plan |

### `ci.yml` — CI (`main` PR)

Triggered on pull request to `main`.

```
Validate Infra  ──►  Build / Test / Push
```

| Job | What it does |
|---|---|
| **Validate Infra** | Asserts `app/Dockerfile` and `infra/deploymentservice.yml` exist; validates manifest with `kubeconform` |
| **Build, Test & Push** | Runs Maven tests in `app/`, builds image, smoke-tests container on port 8070, pushes `captcloud01/shopping-cart:pr-<n>` to Docker Hub |

### `cd.yml` — CD (`main` push)

Triggered on merge to `main`.

```
Build & Push  ──►  Deploy
```

| Job | What it does |
|---|---|
| **Build & Push** | Builds JAR from `app/`, pushes `captcloud01/shopping-cart:<sha>` and `latest` to Docker Hub |
| **Deploy** | Configures kubeconfig via `aws eks update-kubeconfig`, substitutes SHA tag into manifest, deletes and recreates deployment and service, waits for rollout |

### `cleanup.yml` — Full Teardown (`dev` branch only)

Manual trigger only (`workflow_dispatch`). Enforces `dev` branch via a guard job.
Destroys all resources in reverse-provisioning order.

```
Guard (dev only)
      │
      ▼
1 · Delete App Resources    kubectl delete deployment + service
      │
      ▼
2 · Destroy K8s Infra       terraform destroy infra/  (namespace, pull secret, network policies, PDB)
      │
      ▼
3 · Destroy EKS Cluster     terraform destroy infra/eks/  (node group, cluster, VPC, NAT GWs, IAM)
```

## Infrastructure

### EKS Cluster (`infra/eks/`)

State: `shopping-cart/eks/terraform.tfstate`

- VPC `10.0.0.0/16` — 3 public subnets (ALB/NAT) + 3 private subnets (nodes) across 3 AZs
- 3 NAT Gateways for HA egress from private subnets
- EKS cluster with control plane logging enabled
- Managed node group — `t3.medium`, min 1 / desired 2 / max 4

### Kubernetes Resources (`infra/`)

State: `shopping-cart/k8s/terraform.tfstate`

- **Namespace** `shopping-cart` with pod-security `restricted` enforcement
- **Image pull secret** `dockerhub-credentials` — Docker Hub auth for private pulls
- **Network policies** — ingress on port 8070 only; egress restricted to DNS (53) and HTTPS (443)
- **Pod Disruption Budget** — minimum 1 pod available at all times

### App Deployment (`infra/deploymentservice.yml`)

- 2 replicas in `shopping-cart` namespace
- Image tag substituted at deploy time via `sed` — `__TAG__` placeholder replaced with commit SHA
- Security: `runAsNonRoot`, `allowPrivilegeEscalation: false`, all capabilities dropped, seccomp `RuntimeDefault`
- Resources: 250m CPU / 256Mi memory request · 500m CPU / 512Mi limit
- Public LoadBalancer service on port 8070

## Local Development

All commands run from the `app/` directory:

```bash
cd app

# Run tests
mvn clean verify

# Build JAR
mvn clean package -DskipTests

# Build and run with Docker
cd .. && ./app/scripts/run_docker.sh
```

App runs on **port 8070**.

## GitHub Secrets

| Secret | Used by |
|---|---|
| `DOCKER_USERNAME` | CI, CD, Infra |
| `DOCKER_PASSWORD` | CI, CD, Infra, Cleanup |
| `AWS_ACCESS_KEY_ID` | Infra, CD, Cleanup |
| `AWS_SECRET_ACCESS_KEY` | Infra, CD, Cleanup |
| `AWS_REGION` | Infra, CD, Cleanup |
| `TF_STATE_BUCKET` | Infra, Cleanup |
