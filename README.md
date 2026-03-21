# 🏠 Homelab Kubernetes Cluster

Este repositorio documenta la construcción de un clúster Kubernetes en mi homelab con dos servidores físicos, utilizando Proxmox, K3s, TrueNAS y NFS. El objetivo es aprender tecnologías cloud-native y tener una base para servicios como Jellyfin, Pi-hole e IA local.

## 🎯 Objetivos
- Aprender orquestación de contenedores con Kubernetes.
- Integrar almacenamiento persistente con TrueNAS vía NFS.
- Usar GPU para aceleración (IA y transcodificación).
- Preparar el entorno para GitOps con ArgoCD.

## 🏗️ Arquitectura
- **Hipervisor**: Proxmox VE (2 nodos: PC i5-10400F + GTX 1660 y Chuwi N100)
- **Virtualización**: VMs para el clúster K3s y TrueNAS
- **Orquestación**: K3s (cluster de 3 nodos)
- **Almacenamiento**: TrueNAS Scale con ZFS y NFS
- **Persistencia**: Provisionador NFS para Kubernetes

## 📋 Estado Actual
- ✅ Clúster K3s con 3 nodos (1 master, 2 workers)
- ✅ GPU passthrough en worker1 (GTX 1660)
- ✅ TrueNAS configurado con dataset
- ✅ NFS exportado y accesible
- ✅ Helm instalado
- ✅ Provisionador NFS desplegado

## 🚀 Pasos Realizados (resumen)

### 1. Preparación del hardware
- Instalación de Proxmox en dos nodos físicos.
- Configuración de GPU passthrough para la GTX 1660 (IOMMU, vfio-pci, etc.).

### 2. Creación de máquinas virtuales
- **`MASTER`**: Master K3s (Debian, 4GB RAM, 4 cores)
- **`worker1`**: Worker con GPU (Ubuntu, 8GB RAM, 4 cores)
- **`worker2`**: Worker ligero (Debian, 2GB RAM, 2 cores)
- **`truenas`**: TrueNAS Scale (8GB RAM, 2 cores, HDD 1TB en passthrough)

### 3. Instalación de K3s
```bash
# En master
curl -sfL https://get.k3s.io | sh -s - server --cluster-init

# En workers (usando token e IP del master)
curl -sfL https://get.k3s.io | K3S_URL=https://<master-ip>:6443 K3S_TOKEN=<token> sh -

### 4. Configuración de almacenamiento NFS
- En TrueNAS: crear dataset `/mnt/HDD1TB/kubernetes` y exportarlo vía NFS con `maproot` root.
- Verificar montaje desde los workers:
```bash
sudo mount -t nfs <IP_TRUENAS>:/mnt/HDD1TB/kubernetes /mnt/test

### 5. Instalación de Helm y provisionador NFS
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=<IP_TRUENAS> \
  --set nfs.path=/mnt/<TU-PATH>

### 6. Verificación
kubectl get storageclass
kubectl get pods -n default | grep nfs

## 🧪 Prueba de PVC
Se ha probado con un PersistentVolumeClaim (PVC) y un pod que escribe un archivo en el NFS. El archivo apareció en TrueNAS, confirmando el correcto funcionamiento del almacenamiento persistente.

## 📈 Próximos pasos
- Instalar ArgoCD para GitOps.
- Desplegar servicios: Pi-hole, Jellyfin (con GPU), Open WebUI, etc.
- Configurar monitoreo con Prometheus y Grafana.

## 📚 Tecnologías utilizadas
| Tecnología | Descripción |
|------------|-------------|
| Proxmox VE | Hipervisor para VMs y contenedores |
| K3s | Kubernetes ligero para homelab |
| TrueNAS Scale | Almacenamiento ZFS con NFS |
| Helm | Gestor de paquetes para Kubernetes |
| NFS | Protocolo de almacenamiento compartido |
| GPU Passthrough | Asignación directa de GPU a VM |

