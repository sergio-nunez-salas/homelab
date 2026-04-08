# Homelab - Infraestructura Cloud-Native con Kubernetes y GitOps

Repositorio que documenta y gestiona la infraestructura de mi homelab: un cluster Kubernetes (K3s) sobre Proxmox, con GitOps (ArgoCD), almacenamiento persistente (TrueNAS + NFS) e infraestructura como codigo (Terraform).

---

## Arquitectura

```
┌──────────────────────────────────────────────────────────────────┐
│                        RED LOCAL (LAN)                           │
│                                                                  │
│  ┌─────────────────────┐       ┌─────────────────────────────┐  │
│  │  CHUWI N100 (8GB)   │       │  PC i5-10400F (16GB DDR4)   │  │
│  │  Proxmox VE         │       │  Proxmox VE                 │  │
│  │                     │       │                              │  │
│  │  (nodo secundario)  │       │  ┌────────┐ ┌────────────┐  │  │
│  │                     │       │  │ MASTER │ │ worker1    │  │  │
│  └─────────────────────┘       │  │ 4C/4GB │ │ (IALAB)   │  │  │
│                                │  │ Debian │ │ 4C/8GB    │  │  │
│                                │  │ K3s    │ │ Ubuntu    │  │  │
│                                │  │ server │ │ K3s agent │  │  │
│                                │  └────────┘ │ GPU 1660  │  │  │
│                                │             └────────────┘  │  │
│                                │  ┌────────┐ ┌────────────┐  │  │
│                                │  │worker2 │ │  TrueNAS   │  │  │
│                                │  │ 2C/2GB │ │  8GB RAM   │  │  │
│                                │  │ Debian │ │  HDD 1TB   │  │  │
│                                │  │ K3s    │ │  ZFS + NFS │  │  │
│                                │  │ agent  │ │            │  │  │
│                                │  └────────┘ └────────────┘  │  │
│                                └─────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

---

## Hardware

| Nodo | CPU | RAM | Almacenamiento | GPU | Rol |
|------|-----|-----|----------------|-----|-----|
| PC principal | Intel i5-10400F (6C/12T) | 16 GB DDR4 | NVMe 250 GB + HDD 1 TB | GTX 1660 Ti | Proxmox: VMs de K3s + TrueNAS |
| Chuwi N100 | Intel N100 (4C/4T) | 8 GB DDR5 | SSD 512 GB | Integrada | Proxmox: nodo secundario |

## Maquinas virtuales

| VM | SO | RAM | Cores | Disco | Extras | Funcion |
|----|-----|-----|-------|-------|--------|---------|
| MASTER | Debian | 4 GB | 4 | 32 GB | - | K3s control plane |
| worker1 (IALAB) | Ubuntu | 8 GB | 4 | 64 GB | GPU passthrough (GTX 1660) | K3s worker (cargas GPU) |
| worker2 | Debian | 2 GB | 2 | 20 GB | - | K3s worker (cargas ligeras) |
| TrueNAS | TrueNAS Scale | 8 GB | 2 | 32 GB + HDD 1TB | HDD passthrough | Almacenamiento ZFS + NFS |

---

## Stack tecnologico

| Capa | Tecnologia | Descripcion |
|------|-----------|-------------|
| Hipervisor | Proxmox VE | Virtualizacion de los 2 nodos fisicos |
| Orquestacion | K3s | Kubernetes ligero (1 master + 2 workers) |
| Almacenamiento | TrueNAS Scale | ZFS sobre HDD 1TB, exportado via NFS |
| Persistencia K8s | nfs-subdir-external-provisioner | Provisionador dinamico de PVCs desde NFS |
| Paquetes K8s | Helm | Gestor de charts para Kubernetes |
| GitOps | ArgoCD | Despliegue declarativo desde este repositorio |
| Reverse proxy | Nginx Proxy Manager | Proxy inverso con UI web |
| IaC | Terraform | Definicion de toda la infra de VMs como codigo |
| Configuracion | Ansible | Instalacion automatica de K3s en las VMs |
| CI/CD | GitHub Actions | Validacion automatica en cada push (YAML, K8s, Terraform, Ansible) |
| Dashboard | Heimdall | Panel de acceso a servicios |

---

## Estructura del repositorio

```
homelab/
├── .github/workflows/
│   └── ci.yaml                             # Pipeline CI: lint YAML, validar K8s y Terraform
├── ansible/                                # Configuracion automatica de K3s (Ansible)
│   ├── ansible.cfg                         # Configuracion de Ansible
│   ├── inventory/hosts.yml                 # IPs de las VMs del cluster
│   ├── playbooks/                          # Playbooks ejecutables
│   │   ├── site.yml                        # Desplegar cluster completo
│   │   ├── k3s-master.yml                  # Solo master
│   │   └── k3s-workers.yml                 # Solo workers
│   ├── roles/                              # Roles (tareas agrupadas)
│   │   ├── common/                         # Preparacion base de las VMs
│   │   ├── k3s_master/                     # Instalar K3s server
│   │   └── k3s_worker/                     # Instalar K3s agent
│   └── README.md                           # Guia didactica de Ansible
├── apps/                                   # Aplicaciones desplegadas via ArgoCD
│   └── nginx-proxy-manager/
│       └── deployment.yaml                 # Namespace, PVCs, Deployment, Service
├── secrets/
│   └── sealed-github-token.yaml            # Token de GitHub cifrado (Sealed Secrets)
├── terraform/                              # Infraestructura como codigo (Proxmox)
│   ├── main.tf                             # Provider de Proxmox
│   ├── variables.tf                        # Variables configurables
│   ├── terraform.tfvars.example            # Plantilla de valores (sin secretos)
│   ├── vms-k3s.tf                          # VMs del cluster K3s (master + workers)
│   ├── vm-truenas.tf                       # VM de TrueNAS con HDD passthrough
│   ├── outputs.tf                          # IPs y resumen post-despliegue
│   └── README.md                           # Guia didactica de Terraform
├── .gitignore
├── .yamllint.yml                           # Configuracion de yamllint para el CI
└── README.md                               # Este fichero
```

---

## Estado actual

### Infraestructura base

- [x] Proxmox instalado en 2 nodos fisicos
- [x] GPU passthrough configurado (IOMMU, vfio-pci) para GTX 1660
- [x] 4 VMs creadas y operativas
- [x] Cluster K3s funcional (1 master + 2 workers)
- [x] TrueNAS con dataset ZFS y NFS exportado
- [x] Provisionador NFS desplegado en Kubernetes (StorageClass `nfs-client`)
- [x] PVCs probados y funcionando (escritura verificada en TrueNAS)

### GitOps y servicios

- [x] ArgoCD instalado y accesible (NodePort)
- [x] Repositorio GitHub conectado a ArgoCD
- [x] Nginx Proxy Manager desplegado via GitOps (primera app)
- [x] Heimdall desplegado
- [x] Almacenamiento persistente validado con PVCs sobre NFS

### Infraestructura como codigo

- [x] Terraform: definicion completa de las 4 VMs (K3s + TrueNAS)
- [x] Variables parametrizadas (RAM, cores, IPs, GPU, HDD passthrough)
- [x] Plantilla de configuracion sin secretos (`terraform.tfvars.example`)
- [x] Documentacion didactica incluida

### Configuracion automatica (Ansible)

- [x] Playbooks para instalar K3s automaticamente (master + workers)
- [x] Roles separados: common (preparacion SO), k3s_master, k3s_worker
- [x] Inventario con IPs reales de las VMs del cluster
- [x] Documentacion didactica incluida

### CI/CD

- [x] Pipeline GitHub Actions con 4 validaciones automaticas
- [x] Lint YAML con yamllint (ficheros de apps y workflows)
- [x] Validacion de manifiestos Kubernetes con kubeconform
- [x] Comprobacion de formato Terraform con terraform fmt
- [x] Lint de playbooks y roles Ansible con ansible-lint

---

## Pasos realizados

### 1. Preparacion del hardware

- Instalacion de Proxmox VE en los 2 nodos fisicos.
- Configuracion de GPU passthrough para la GTX 1660 (IOMMU habilitado en BIOS, modulos vfio-pci en el kernel).

### 2. Creacion de maquinas virtuales

Las 4 VMs se crearon en Proxmox sobre el nodo principal (PC i5-10400F):

```bash
# MASTER, worker1 (IALAB), worker2: creadas desde plantilla Debian/Ubuntu
# TrueNAS: instalada desde ISO oficial de TrueNAS Scale
# HDD 1TB: pasado por passthrough completo a la VM de TrueNAS
```

### 3. Instalacion de K3s

```bash
# En el master
curl -sfL https://get.k3s.io | sh -s - server --cluster-init

# En los workers (usando token e IP del master)
curl -sfL https://get.k3s.io | K3S_URL=https://<master-ip>:6443 K3S_TOKEN=<token> sh -
```

### 4. Almacenamiento NFS

```bash
# Verificar montaje NFS desde los workers
sudo mount -t nfs <IP_TRUENAS>:/mnt/HDD1TB/kubernetes /mnt/test
```

### 5. Helm y provisionador NFS

```bash
helm repo add nfs-subdir-external-provisioner \
  https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update

helm install nfs-provisioner \
  nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=<IP_TRUENAS> \
  --set nfs.path=/mnt/HDD1TB/kubernetes
```

### 6. ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Exponer con NodePort
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'

# Obtener password de admin
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### 7. Nginx Proxy Manager (primera app GitOps)

Desplegado via ArgoCD desde `apps/nginx-proxy-manager/deployment.yaml`:
- Namespace `networking`
- 2 PVCs sobre `nfs-client` (datos + certificados Let's Encrypt)
- Service ClusterIP (puertos 80, 81, 443)
- Acceso via `kubectl port-forward --address 0.0.0.0`

### 8. Terraform (IaC)

Toda la infraestructura de VMs definida en `terraform/` como codigo:
- Provider `bpg/proxmox` para gestionar Proxmox via API
- Las 4 VMs parametrizadas con variables
- GPU passthrough y HDD passthrough configurables
- Guia paso a paso en `terraform/README.md`

### 9. Pipeline CI/CD (GitHub Actions)

Workflow automatico en `.github/workflows/ci.yaml` que se ejecuta en cada push a `main`:
- **Lint YAML**: valida sintaxis YAML de los manifiestos y workflows con `yamllint`
- **Validar K8s**: comprueba que los manifiestos de `apps/` sean recursos Kubernetes validos con `kubeconform`
- **Validar Terraform**: verifica el formato del codigo Terraform con `terraform fmt -check`
- **Lint Ansible**: valida playbooks y roles con `ansible-lint`

### 10. Ansible (configuracion automatica de K3s)

Playbooks y roles en `ansible/` para automatizar la instalacion del cluster:
- Rol `common`: prepara las VMs (actualizaciones, dependencias, swap, kernel, sysctl)
- Rol `k3s_master`: instala K3s server y guarda el token de union
- Rol `k3s_worker`: instala K3s agent y une los workers al cluster
- Guia paso a paso en `ansible/README.md`

---

## Acceso a servicios

| Servicio | URL | Credenciales |
|----------|-----|-------------|
| Proxmox VE | `https://<IP_NODO>:8006` | root / password |
| ArgoCD | `https://<IP_MASTER>:<NodePort>` | admin / (ver comando arriba) |
| Nginx Proxy Manager | `http://<IP_MASTER>:8081` (via port-forward) | admin@example.com / changeme |

---

## Proximos pasos

- [ ] Cloudflare Tunnel para exponer servicios a internet
- [x] Pipeline CI/CD con GitHub Actions (lint YAML + validacion manifests + formato Terraform)
- [x] Branch protection en main (requiere PR + CI verde para mergear)
- [ ] Monitoring: Prometheus + Grafana
- [ ] Desplegar Nextcloud, Jellyfin (con GPU), Pi-hole
- [x] Ansible para provisioning post-VM (instalacion automatica de K3s)
- [ ] Cluster Proxmox entre los 2 nodos fisicos
