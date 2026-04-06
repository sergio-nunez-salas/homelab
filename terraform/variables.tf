# =============================================================================
# variables.tf - Variables configurables del proyecto
# =============================================================================
#
# CONCEPTOS CLAVE:
#
# - "variable": define un parametro que puedes cambiar sin tocar el codigo.
#   Es como un argumento de una funcion: defines nombre, tipo y descripcion.
#
# - "type": el tipo de dato (string, number, bool, list, map, object...).
#
# - "default": valor por defecto. Si no lo pones, Terraform te lo pedira
#   al ejecutar "terraform apply".
#
# - "sensitive": si es true, Terraform no mostrara el valor en la terminal.
#   Usalo para passwords y tokens.
#
# - Los valores reales se ponen en "terraform.tfvars" (que NO se sube a Git).
#
# =============================================================================


# =============================================================================
# CONEXION A PROXMOX
# =============================================================================

variable "proxmox_url" {
  description = "URL de la API de Proxmox (ej: https://192.168.1.100:8006)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Token de API de Proxmox. Formato: usuario@realm!nombre-token=uuid-del-token"
  type        = string
  sensitive   = true
}


# =============================================================================
# NODOS PROXMOX
# =============================================================================
# Tienes 2 nodos fisicos en tu homelab:
#   - PC viejo (i5-10400F, 16GB, NVMe 250GB, GTX 1660)
#   - Chuwi N100 (8GB)
# Cada VM se crea en un nodo concreto. Aqui defines sus nombres tal como
# aparecen en la interfaz de Proxmox (ej: "pve", "pve-chuwi").

variable "proxmox_node_main" {
  description = "Nombre del nodo Proxmox principal (PC viejo) tal como aparece en la UI"
  type        = string
  default     = "pve"
}

variable "proxmox_node_secondary" {
  description = "Nombre del nodo Proxmox secundario (Chuwi N100) tal como aparece en la UI"
  type        = string
  default     = "pve-chuwi"
}


# =============================================================================
# ALMACENAMIENTO
# =============================================================================
# El "storage" en Proxmox es donde se guardan los discos de las VMs.
# Lo normal es "local-lvm" (en el SSD/NVMe del nodo).

variable "storage_pool" {
  description = "Pool de almacenamiento en Proxmox para los discos de las VMs"
  type        = string
  default     = "local-lvm"
}


# =============================================================================
# RED
# =============================================================================

variable "network_bridge" {
  description = "Bridge de red en Proxmox (normalmente vmbr0)"
  type        = string
  default     = "vmbr0"
}

variable "network_gateway" {
  description = "Gateway de tu red local (la IP de tu router)"
  type        = string
  default     = "192.168.1.1"
}

variable "network_dns" {
  description = "Servidor DNS (tu router o 8.8.8.8)"
  type        = string
  default     = "8.8.8.8"
}


# =============================================================================
# VM: MASTER (K3s control plane)
# =============================================================================

variable "master_vmid" {
  description = "ID numerico de la VM en Proxmox (cada VM tiene un ID unico)"
  type        = number
  default     = 100
}

variable "master_name" {
  description = "Nombre de la VM"
  type        = string
  default     = "k3s-master"
}

variable "master_cores" {
  description = "Numero de cores de CPU asignados"
  type        = number
  default     = 4
}

variable "master_memory" {
  description = "RAM en MB (4096 = 4GB)"
  type        = number
  default     = 4096
}

variable "master_disk_size" {
  description = "Tamano del disco en GB"
  type        = number
  default     = 32
}

variable "master_ip" {
  description = "IP fija de la VM (formato CIDR: 192.168.1.50/24)"
  type        = string
}


# =============================================================================
# VM: WORKER1 / IALAB (K3s worker con GPU)
# =============================================================================

variable "worker1_vmid" {
  description = "ID de la VM en Proxmox"
  type        = number
  default     = 101
}

variable "worker1_name" {
  description = "Nombre de la VM"
  type        = string
  default     = "k3s-worker1-ialab"
}

variable "worker1_cores" {
  description = "Cores de CPU"
  type        = number
  default     = 4
}

variable "worker1_memory" {
  description = "RAM en MB (8192 = 8GB)"
  type        = number
  default     = 8192
}

variable "worker1_disk_size" {
  description = "Tamano del disco en GB"
  type        = number
  default     = 64
}

variable "worker1_ip" {
  description = "IP fija (formato CIDR)"
  type        = string
}

# La GPU se pasa por PCI passthrough. Este es el ID del dispositivo PCI
# de tu GTX 1660 en el host Proxmox. Lo puedes ver con "lspci" en Proxmox.
variable "worker1_gpu_pci_id" {
  description = "ID PCI de la GPU para passthrough (ej: 0000:01:00). Dejar vacio si no quieres passthrough."
  type        = string
  default     = ""
}


# =============================================================================
# VM: WORKER2 (K3s worker ligero)
# =============================================================================

variable "worker2_vmid" {
  description = "ID de la VM en Proxmox"
  type        = number
  default     = 102
}

variable "worker2_name" {
  description = "Nombre de la VM"
  type        = string
  default     = "k3s-worker2"
}

variable "worker2_cores" {
  description = "Cores de CPU"
  type        = number
  default     = 2
}

variable "worker2_memory" {
  description = "RAM en MB (2048 = 2GB)"
  type        = number
  default     = 2048
}

variable "worker2_disk_size" {
  description = "Tamano del disco en GB"
  type        = number
  default     = 20
}

variable "worker2_ip" {
  description = "IP fija (formato CIDR)"
  type        = string
}


# =============================================================================
# VM: TRUENAS (almacenamiento ZFS + NFS)
# =============================================================================

variable "truenas_vmid" {
  description = "ID de la VM en Proxmox"
  type        = number
  default     = 200
}

variable "truenas_name" {
  description = "Nombre de la VM"
  type        = string
  default     = "truenas"
}

variable "truenas_cores" {
  description = "Cores de CPU"
  type        = number
  default     = 2
}

variable "truenas_memory" {
  description = "RAM en MB (8192 = 8GB). TrueNAS necesita bastante RAM para ZFS."
  type        = number
  default     = 8192
}

variable "truenas_disk_size" {
  description = "Disco del sistema en GB (no es el HDD de datos)"
  type        = number
  default     = 32
}

variable "truenas_ip" {
  description = "IP fija (formato CIDR)"
  type        = string
}

# El HDD de 1TB se pasa por passthrough al completo a la VM de TrueNAS.
# Necesitas el ID del disco en el host (ej: /dev/disk/by-id/ata-WDC_xxx).
variable "truenas_hdd_passthrough_id" {
  description = "ID del disco HDD para passthrough a TrueNAS (ver con 'ls -l /dev/disk/by-id/' en Proxmox)"
  type        = string
  default     = ""
}


# =============================================================================
# PLANTILLA CLOUD-INIT
# =============================================================================
# Cloud-init es un sistema que configura una VM automaticamente en el primer
# arranque: establece hostname, IP, usuario, clave SSH, etc.
# Necesitas una plantilla (template) de VM con cloud-init preinstalado.
# Ver el README.md de este directorio para como crearla.

variable "cloud_init_template_name" {
  description = "Nombre de la plantilla de VM con cloud-init en Proxmox"
  type        = string
  default     = "debian-12-cloudinit"
}

variable "cloud_init_user" {
  description = "Usuario que se creara en las VMs via cloud-init"
  type        = string
  default     = "sergio"
}

variable "cloud_init_ssh_public_key" {
  description = "Tu clave publica SSH (el contenido de ~/.ssh/id_rsa.pub). Se inyecta en las VMs para acceso sin password."
  type        = string
  default     = ""
}
