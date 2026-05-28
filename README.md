# Shopping Cart

A Spring Boot shopping cart web application deployed to Kubernetes via GitHub Actions CI/CD.

## Stack

- **App:** Spring Boot 1.5.3, Java 8, Spring Security, Spring Data JPA, Thymeleaf
- **Database:** H2 (in-memory for dev/test), MySQL (production)
- **Container:** Docker, published to Docker Hub
- **Orchestration:** Kubernetes (2 replicas, LoadBalancer)
- **Infra-as-Code:** Terraform (Kubernetes provider, S3 remote state)
- **CI/CD:** GitHub Actions

## CI/CD Pipelines

### CI — Pull Request to `main`

Runs in strict sequence:

```
Terraform Apply  ──►  Validate Infra  ──►  Build / Test / Push
```

| Job | What it does |
|---|---|
| **Terraform Apply** | Inits S3 backend, validates and applies `infra/` against the cluster |
| **Validate Infrastructure** | Asserts `Dockerfile` and `deploymentservice.yml` exist; kubectl dry-runs the k8s manifest |
| **Build, Test & Push** | Runs Maven tests, builds Docker image, smoke-tests the container, pushes `<user>/shopping-cart:pr-<n>` to Docker Hub |

### CD — Merge to `main`

```
Build & Push  ──►  Deploy
```

| Job | What it does |
|---|---|
| **Build & Push** | Builds JAR, pushes `<user>/shopping-cart:<sha>` and `latest` to Docker Hub |
| **Deploy** | Substitutes the commit SHA image tag into `deploymentservice.yml`, applies it with kubectl, waits for rollout |

### Infra Provision — `infra/**` changes or manual trigger

Triggered automatically when files under `infra/` change on `main`, or manually via `workflow_dispatch`.

| Input | Behaviour |
|---|---|
| `plan` | Init → Validate → Plan only |
| `apply` *(default on push)* | Init → Validate → Plan → Apply |
| `destroy` | Init → Destroy |

## Infrastructure (`infra/`)

Terraform manages the Kubernetes namespace and supporting resources:

- **Namespace** — with pod-security enforcement labels (`restricted`)
- **Image pull secret** — Docker Hub credentials for private image pulls
- **Network policies** — ingress on port 8070 only; egress restricted to DNS
- **Pod Disruption Budget** — minimum 1 pod available during disruptions

State is stored in S3 (`shopping-cart/k8s/terraform.tfstate`).

## Local Development

```bash
# Build and run with Docker
./scripts/run_docker.sh

# Run tests
mvn clean verify

# Build JAR only
mvn clean package -DskipTests
```

App runs on **port 8070**.

## GitHub Secrets Required

| Secret | Used by |
|---|---|
| `DOCKER_USERNAME` | CI, CD, Infra |
| `DOCKER_PASSWORD` | CI, CD, Infra |
| `KUBECONFIG` | CI (infra apply), CD (deploy) |
| `KUBE_CONTEXT` | CI (infra apply), Infra |
| `AWS_ACCESS_KEY_ID` | CI (infra apply), Infra (S3 state) |
| `AWS_SECRET_ACCESS_KEY` | CI (infra apply), Infra (S3 state) |
| `TF_STATE_BUCKET` | CI (infra apply), Infra |
| `TF_STATE_REGION` | CI (infra apply), Infra |
