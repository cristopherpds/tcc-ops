# tcc-ops

Repositório de **operações e infraestrutura** da prova de conceito (PoC) do TCC
**"GitOps: Automação e Gestão de Infraestrutura utilizando Repositórios Git"**, de
Cristopher J. Paiva da Silva.

Este repositório atua como o **repositório GitOps** da solução: ele é a *single
source of truth* que descreve, de forma **declarativa**, o estado desejado da
infraestrutura na nuvem e da aplicação executada no cluster Kubernetes. Nenhuma
alteração é aplicada manualmente no cluster — tudo é definido aqui em Git e
reconciliado automaticamente pelo ArgoCD.

> A aplicação de exemplo (API em Python/FastAPI) e o pipeline de Integração
> Contínua ficam no repositório separado [`tcc-app`](https://github.com/cristopherpds/tcc-app).
> Este repositório (`tcc-ops`) cuida apenas da infraestrutura e da Entrega Contínua.

## Papel na arquitetura GitOps

A solução é dividida em dois repositórios para garantir separação de
responsabilidades e rastreabilidade:

| Repositório | Responsabilidade |
|-------------|------------------|
| `tcc-app`   | Código-fonte da aplicação + pipeline de CI (GitHub Actions) que constrói e publica a imagem Docker no GitHub Container Registry (GHCR). |
| **`tcc-ops`** (este) | Provisionamento da infraestrutura (Terraform), manifestos declarativos do Kubernetes e configuração do ArgoCD para a Entrega Contínua (CD). |

Fluxo de ponta a ponta:

```
Dev faz push em tcc-app
        │
        ▼
GitHub Actions (CI): build da imagem Docker → publica no GHCR
        │
        └──► atualiza a tag da imagem em k8s/deployment.yml
             e faz commit na branch deploy/app deste repositório (tcc-ops)
                      │
                      ▼
             ArgoCD detecta a divergência (monitorando deploy/app)
                      │
                      ▼
             Sincroniza automaticamente o cluster GKE com o estado do Git
```

## Estrutura do repositório

```
tcc-ops/
├── terraform/        # Provisionamento da infraestrutura no Google Cloud (GKE)
│   ├── provider.tf   # Provider Google (HashiCorp), projeto e região
│   ├── variables.tf  # Variáveis: project_id, region, cluster_name
│   ├── gke.tf        # APIs do GCP, rede VPC e cluster GKE em modo Autopilot
│   ├── iam.tf        # Service Account "github-ci" e permissões no GKE
│   ├── wif.tf        # Workload Identity Federation (OIDC) para o GitHub Actions
│   └── outputs.tf    # Saídas: IDs do pool/provider WIF e e-mail da SA
│
├── argocd/           # Bootstrap e configuração do ArgoCD
│   ├── namespaces/   # Namespace "argocd"
│   ├── project.yml   # AppProject que restringe repositórios e recursos permitidos
│   ├── application.yml# Application que aponta para a branch deploy/app, path k8s
│   └── ingress/      # Ingress (GCE) + ManagedCertificate para a UI do ArgoCD
│
└── k8s/              # Manifestos declarativos da aplicação (estado desejado)
    ├── namespaces/   # Namespace "app"
    ├── deployment.yml# Deployment da aplicação (imagem do GHCR, probes, recursos)
    ├── service.yml   # Service do tipo LoadBalancer (porta 80 → 8080)
    ├── configmap.yml # Variáveis de ambiente da aplicação
    ├── hpa.yml       # Horizontal Pod Autoscaler
    └── rbac/         # Role e RoleBinding que autorizam o ArgoCD no namespace app
```

## Componentes em detalhe

### Infraestrutura — Terraform (`terraform/`)
Provisiona, como código, todo o ambiente no **Google Cloud Platform**:

- Habilita as APIs necessárias (Compute, Container e Artifact Registry).
- Cria uma rede **VPC** e um cluster **GKE em modo Autopilot** (gerenciamento
  automático de nós).
- Configura **Workload Identity Federation (WIF)** com OIDC, permitindo que o
  pipeline do GitHub Actions se autentique no GCP **sem chaves de serviço**
  (autenticação federada restrita ao repositório `cristopherpds/tcc-ops`).
- Cria a Service Account `github-ci` com a permissão `roles/container.developer`
  para operar sobre o cluster.

### Entrega Contínua — ArgoCD (`argocd/`)
Configura o ArgoCD como agente de reconciliação GitOps:

- **AppProject** (`project.yml`): delimita quais repositórios, destinos e tipos de
  recurso a aplicação pode gerenciar.
- **Application** (`application.yml`): monitora este repositório na branch
  `deploy/app`, path `k8s`, com `syncPolicy.automated` (`prune` e `selfHeal`
  habilitados) — ou seja, o cluster é corrigido automaticamente sempre que diverge
  do estado declarado no Git.
- **Ingress + ManagedCertificate**: expõem a interface web do ArgoCD em
  `argocd.cristopherpds.dev` com TLS gerenciado pelo GKE.

### Aplicação — Manifestos Kubernetes (`k8s/`)
Descreve o estado desejado da aplicação no cluster:

- **Deployment**: 2 réplicas da imagem `ghcr.io/cristopherpds/tcc-app`, com
  *readiness*/*liveness probes* (`/health/ready` e `/health/live`), limites de
  recursos e injeção de variáveis via ConfigMap. **A tag da imagem neste arquivo é
  o ponto atualizado automaticamente pelo pipeline de CI.**
- **Service**: do tipo `LoadBalancer`, expondo a aplicação na porta 80.
- **ConfigMap**, **HPA** e **RBAC** (Role/RoleBinding que concedem ao ArgoCD as
  permissões necessárias no namespace `app`).

## Como utilizar

> Pré-requisitos: conta no Google Cloud, `gcloud`, `terraform` e `kubectl`
> configurados, e o ArgoCD instalado no cluster.

1. **Provisionar a infraestrutura:**
   ```bash
   cd terraform
   terraform init
   terraform apply -var="project_id=SEU_PROJETO_GCP"
   ```

2. **Conectar ao cluster GKE** criado pelo Terraform:
   ```bash
   gcloud container clusters get-credentials tcc-autopilot --region europe-west1
   ```

3. **Aplicar a configuração do ArgoCD** (namespace, project, application e ingress):
   ```bash
   kubectl apply -f argocd/namespaces/
   kubectl apply -f argocd/project.yml
   kubectl apply -f argocd/application.yml
   kubectl apply -f argocd/ingress/
   ```

A partir daí, o ArgoCD passa a sincronizar os manifestos de `k8s/` (branch
`deploy/app`) com o cluster automaticamente. Cada nova versão publicada pelo
pipeline em `tcc-app` atualiza a imagem no `deployment.yml` e dispara uma nova
sincronização — sem intervenção manual.

## Tecnologias

- **Terraform** — Infraestrutura como Código (IaC)
- **Google Kubernetes Engine (GKE Autopilot)** — orquestração de contêineres
- **ArgoCD** — Entrega Contínua baseada em GitOps
- **GitHub Container Registry (GHCR)** — registro das imagens da aplicação
- **Workload Identity Federation (OIDC)** — autenticação federada do CI no GCP
