# SRE/DevOps Learning Roadmap

## Aplicando Skills da Vaga Conquest One ao RHCSA Practice Labs

Este documento mapeia como aplicar cada tecnologia da vaga SRE/DevOps ao projeto existente.

---

## 1. Docker - Containerização

### O que fazer:
- Criar `Dockerfile` para a API Flask
- Criar `Dockerfile` para os VMs de teste (usando containers ao invés de Vagrant)
- Criar `docker-compose.yml` para orquestração local

### Estrutura proposta:
```
docker/
├── Dockerfile.api          # Flask API container
├── Dockerfile.examnode     # Rocky Linux exam node
├── docker-compose.yml      # Full stack local
└── docker-compose.dev.yml  # Dev with hot reload
```

### Exemplo Dockerfile.api:
```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY api/ ./api/
COPY static/ ./static/
COPY exam-grader.sh checks/ ./
EXPOSE 8080
CMD ["python", "api/app.py"]
```

### Aprendizado:
- Multi-stage builds
- Layer caching
- Security best practices (non-root user)
- Health checks

---

## 2. Kubernetes - Orquestração

### O que fazer:
- Criar manifests K8s para deploy da aplicação
- Configurar Services, Deployments, ConfigMaps, Secrets
- Implementar probes (liveness/readiness)

### Estrutura proposta:
```
k8s/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── kustomization.yaml
├── overlays/
│   ├── dev/
│   └── prod/
└── README.md
```

### Exemplo deployment.yaml:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rhcsa-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: rhcsa-api
  template:
    metadata:
      labels:
        app: rhcsa-api
    spec:
      containers:
      - name: api
        image: rhcsa-practice-labs:latest
        ports:
        - containerPort: 8080
        livenessProbe:
          httpGet:
            path: /api/healthcheck
            port: 8080
        readinessProbe:
          httpGet:
            path: /api/healthcheck
            port: 8080
        resources:
          limits:
            memory: "256Mi"
            cpu: "500m"
```

### Aprendizado:
- Kustomize para ambiente múltiplos
- Resource limits e requests
- Pod disruption budgets
- Network policies

---

## 3. Helm - Gerenciamento de Charts

### O que fazer:
- Criar Helm chart para a aplicação
- Parametrizar configurações
- Versionar releases

### Estrutura proposta:
```
helm/
└── rhcsa-labs/
    ├── Chart.yaml
    ├── values.yaml
    ├── values-dev.yaml
    ├── values-prod.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        ├── configmap.yaml
        ├── ingress.yaml
        └── _helpers.tpl
```

### Exemplo values.yaml:
```yaml
replicaCount: 2
image:
  repository: ghcr.io/your-org/rhcsa-practice-labs
  tag: "latest"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  className: nginx
  hosts:
    - host: rhcsa.example.com
      paths:
        - path: /
          pathType: Prefix

resources:
  limits:
    cpu: 500m
    memory: 256Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### Aprendizado:
- Template functions
- Chart dependencies
- Helm hooks (pre-install, post-upgrade)
- Chart testing

---

## 4. GitHub Actions - CI/CD

### O que fazer:
- Pipeline de build e test
- Build e push de imagem Docker
- Deploy automatizado
- Security scanning

### Estrutura proposta:
```
.github/
└── workflows/
    ├── ci.yml           # Lint, test, build
    ├── cd.yml           # Deploy to environments
    ├── security.yml     # Vulnerability scanning
    └── release.yml      # Semantic versioning
```

### Exemplo ci.yml:
```yaml
name: CI Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Lint Python
        uses: py-actions/flake8@v2
      - name: Lint Shell
        uses: ludeeus/action-shellcheck@master
        with:
          scandir: './checks'

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
      - name: Install deps
        run: pip install -r api/requirements.txt pytest
      - name: Run tests
        run: pytest tests/

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build Docker image
        run: docker build -t rhcsa-labs:${{ github.sha }} -f docker/Dockerfile.api .
      - name: Push to GHCR
        if: github.ref == 'refs/heads/main'
        run: |
          echo ${{ secrets.GITHUB_TOKEN }} | docker login ghcr.io -u ${{ github.actor }} --password-stdin
          docker tag rhcsa-labs:${{ github.sha }} ghcr.io/${{ github.repository }}:latest
          docker push ghcr.io/${{ github.repository }}:latest
```

### Aprendizado:
- Matrix builds
- Caching strategies
- Environment secrets
- Reusable workflows
- Branch protection rules

---

## 5. Terraform - Infrastructure as Code

### O que fazer:
- Provisionar infraestrutura GCP
- Criar GKE cluster
- Configurar CloudSQL
- Gerenciar IAM

### Estrutura proposta:
```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── terraform.tfvars
│   └── prod/
├── modules/
│   ├── gke/
│   ├── cloudsql/
│   ├── iam/
│   └── networking/
└── README.md
```

### Exemplo modules/gke/main.tf:
```hcl
resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  # Usar node pool separado
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.network
  subnetwork = var.subnetwork

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "${var.cluster_name}-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    preemptible  = var.preemptible
    machine_type = var.machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
```

### Aprendizado:
- State management (remote backend)
- Workspaces
- Module composition
- Terraform Cloud/Enterprise
- Import existing resources

---

## 6. GCP - Cloud Provider

### Serviços a implementar:

#### GKE (Google Kubernetes Engine)
- Cluster para rodar a aplicação
- Node pools com autoscaling
- Workload Identity

#### IAM
- Service accounts para aplicação
- Least privilege principle
- Workload Identity Federation

#### CloudSQL
- Substituir SQLite por PostgreSQL managed
- Private IP connectivity
- Automated backups

#### Cloud Monitoring
- Custom metrics da aplicação
- Alertas de SLO/SLI
- Dashboards

### Estrutura proposta:
```
gcp/
├── cloudsql/
│   └── migration.sql     # Schema migration
├── monitoring/
│   ├── dashboards/
│   └── alerts/
└── iam/
    └── roles.yaml
```

---

## 7. Observabilidade

### O que fazer:
- Instrumentar a API Flask
- Configurar logging estruturado
- Implementar métricas customizadas
- Distributed tracing

### Estrutura proposta:
```
observability/
├── prometheus/
│   └── rules.yaml
├── grafana/
│   └── dashboards/
│       └── rhcsa-labs.json
├── elk/
│   └── logstash.conf
└── datadog/
    └── monitors.yaml
```

### Instrumentação Flask:
```python
# api/metrics.py
from prometheus_client import Counter, Histogram, generate_latest
import time

REQUEST_COUNT = Counter(
    'rhcsa_request_total',
    'Total requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'rhcsa_request_latency_seconds',
    'Request latency',
    ['method', 'endpoint']
)

TASK_GRADING = Histogram(
    'rhcsa_task_grading_seconds',
    'Task grading duration',
    ['task_id']
)

TASK_RESULTS = Counter(
    'rhcsa_task_results_total',
    'Task grading results',
    ['task_id', 'result']  # passed/failed
)
```

### Logging estruturado:
```python
import structlog

logger = structlog.get_logger()

@app.route('/api/grade-task/<task_id>')
def grade_task(task_id):
    logger.info(
        "grading_task",
        task_id=task_id,
        user_agent=request.headers.get('User-Agent')
    )
```

### Aprendizado:
- RED method (Rate, Errors, Duration)
- USE method (Utilization, Saturation, Errors)
- SLI/SLO/SLA definition
- Alert fatigue prevention

---

## 8. Git - Boas Práticas

### O que fazer:
- Implementar Conventional Commits
- Branch protection rules
- Git hooks (pre-commit)
- Semantic versioning

### Estrutura proposta:
```
.github/
├── CODEOWNERS
├── pull_request_template.md
└── ISSUE_TEMPLATE/
    ├── bug_report.md
    └── feature_request.md

.husky/
└── pre-commit

.commitlintrc.json
```

### Conventional Commits:
```
feat(api): add task filtering by category
fix(grader): handle timeout in SSH connection
docs(readme): add deployment instructions
chore(deps): update Flask to 3.0.0
ci(actions): add security scanning workflow
```

---

## 9. Nexus - Gerenciamento de Artefatos

### O que fazer:
- Configurar Nexus como Docker registry
- Proxy para PyPI
- Hospedar Helm charts

### Estrutura proposta:
```
nexus/
├── docker-compose.yml    # Local Nexus instance
├── configure.sh          # Repository setup script
└── README.md
```

### Aprendizado:
- Repository types (hosted, proxy, group)
- Cleanup policies
- Security scanning integration
- High availability setup

---

## 10. Python/Shell Automation

### O que fazer:
- Scripts de deploy
- Automation de tasks repetitivas
- CLI tools

### Estrutura proposta:
```
scripts/
├── deploy.py             # Deployment automation
├── cleanup.py            # Resource cleanup
├── rotate-secrets.sh     # Secret rotation
└── healthcheck.sh        # System health checks
```

### Exemplo deploy.py:
```python
#!/usr/bin/env python3
"""Deployment automation script"""
import click
import subprocess
from pathlib import Path

@click.group()
def cli():
    """RHCSA Labs deployment CLI"""
    pass

@cli.command()
@click.option('--env', type=click.Choice(['dev', 'staging', 'prod']))
@click.option('--dry-run', is_flag=True)
def deploy(env, dry_run):
    """Deploy to specified environment"""
    click.echo(f"Deploying to {env}...")
    # Implementation

@cli.command()
def rollback():
    """Rollback to previous version"""
    # Implementation

if __name__ == '__main__':
    cli()
```

---

## 11. AIOps / AI para Observabilidade (Diferencial)

### O que fazer:
- Anomaly detection em métricas
- Log analysis com ML
- Predictive alerting
- ChatOps com LLM

### Estrutura proposta:
```
aiops/
├── anomaly_detection/
│   └── detect.py         # Time series anomaly detection
├── log_analysis/
│   └── classify.py       # Log classification
└── chatops/
    └── slack_bot.py      # AI-powered incident response
```

### Exemplo simples de anomaly detection:
```python
import numpy as np
from sklearn.ensemble import IsolationForest

def detect_anomalies(metrics: list[float], threshold: float = 0.1):
    """Detect anomalies in time series metrics"""
    model = IsolationForest(contamination=threshold)
    data = np.array(metrics).reshape(-1, 1)
    predictions = model.fit_predict(data)
    return [i for i, p in enumerate(predictions) if p == -1]
```

---

## Roadmap de Implementação

### Fase 1 - Foundation (2 semanas)
1. ✅ Análise do projeto atual
2. 🔲 Dockerização da aplicação
3. 🔲 Testes unitários básicos
4. 🔲 GitHub Actions CI básico

### Fase 2 - Kubernetes (2 semanas)
1. 🔲 Manifests K8s
2. 🔲 Helm chart
3. 🔲 Local testing com kind/minikube

### Fase 3 - Cloud (3 semanas)
1. 🔲 Terraform modules
2. 🔲 GKE cluster
3. 🔲 CloudSQL migration
4. 🔲 CD pipeline

### Fase 4 - Observability (2 semanas)
1. 🔲 Prometheus metrics
2. 🔲 Grafana dashboards
3. 🔲 Alerting rules
4. 🔲 Structured logging

### Fase 5 - Advanced (ongoing)
1. 🔲 Nexus setup
2. 🔲 AIOps experiments
3. 🔲 Chaos engineering
4. 🔲 Cost optimization

---

## Próximos Passos

Quer que eu comece a implementar alguma dessas fases? Sugiro começar por:

1. **Docker** - Base para todo o resto
2. **GitHub Actions** - CI imediato com cada commit
3. **Observability** - Métricas na API existente

Cada uma dessas pode ser implementada incrementalmente sem quebrar o projeto atual.
