# =============================================================================
# vms-k3s.tf - Maquinas virtuales del cluster Kubernetes (K3s)
# =============================================================================
#
# CONCEPTOS CLAVE:
#
# - "resource": es un bloque que le dice a Terraform "quiero que EXISTA esto".
#   Terraform se encarga de crearlo si no existe, actualizarlo si cambio algo,
#   o destruirlo si lo elimino del fichero.
#
# - "proxmox_virtual_environment_vm": tipo de recurso del provider bpg/proxmox.
#   Define una maquina virtual completa en Proxmox.
#
# - "clone": en lugar de instalar un SO desde cero, clonamos una plantilla
#   que ya tiene el SO + cloud-init preinstalado. Esto permite crear VMs
#   en segundos en vez de minutos.
#
# - "cloud-init": sistema que configura la VM en el primer arranque.
#   Le pasa el hostname, la IP, el usuario y la clave SSH automaticamente.
#
# =============================================================================


# =============================================================================
# VM: MASTER - K3s control plane
# =============================================================================
# Esta es la VM principal del cluster. Ejecuta el servidor K3s que gestiona
# todo el cluster de Kubernetes. Las otras VMs (workers) se conectan a esta.

resource "proxmox_virtual_environment_vm" "k3s_master" {
  # --- Identificacion basica ---
  # vm_id: numero unico que identifica la VM en Proxmox.
  # node_name: en que nodo fisico de Proxmox se crea la VM.
  # name: nombre descriptivo que veras en la interfaz de Proxmox.
  vm_id     = var.master_vmid
  node_name = var.proxmox_node_main
  name      = var.master_name

  # --- Clonacion de plantilla ---
  # En vez de instalar Debian desde una ISO (lento), clonamos una plantilla
  # que ya tiene Debian + cloud-init preparado (rapido, ~30 segundos).
  clone {
    vm_id = proxmox_virtual_environment_vm.cloud_init_template.vm_id
  }

  # --- CPU ---
  # "type = host" expone todas las instrucciones de tu CPU real a la VM.
  # Esto da mejor rendimiento que emular una CPU generica.
  cpu {
    cores = var.master_cores
    type  = "host"
  }

  # --- Memoria RAM ---
  memory {
    dedicated = var.master_memory
  }

  # --- Disco principal ---
  # Es el disco donde vive el sistema operativo y K3s.
  disk {
    interface    = "scsi0"
    size         = var.master_disk_size
    datastore_id = var.storage_pool
  }

  # --- Red ---
  # Se conecta al bridge de red de Proxmox (normalmente vmbr0).
  # El modelo "virtio" es el mas rapido para VMs Linux.
  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # --- Cloud-init ---
  # Aqui le decimos a cloud-init que configure en el primer arranque:
  # usuario, clave SSH, IP fija, gateway, DNS y hostname.
  initialization {
    user_account {
      username = var.cloud_init_user
      keys     = var.cloud_init_ssh_public_key != "" ? [var.cloud_init_ssh_public_key] : []
    }

    ip_config {
      ipv4 {
        address = var.master_ip
        gateway = var.network_gateway
      }
    }

    dns {
      servers = [var.network_dns]
    }
  }

  # Arrancar la VM automaticamente cuando Proxmox inicie
  on_boot = true

  # Etiquetas para organizar las VMs en Proxmox
  tags = ["k3s", "master", "terraform"]
}


# =============================================================================
# VM: WORKER1 / IALAB - K3s worker con GPU
# =============================================================================
# Este worker tiene la GTX 1660 pasada por PCI passthrough.
# Se usa para cargas que necesiten GPU: transcodificacion (Jellyfin),
# inferencia IA (Ollama), etc.

resource "proxmox_virtual_environment_vm" "k3s_worker1" {
  vm_id     = var.worker1_vmid
  node_name = var.proxmox_node_main
  name      = var.worker1_name

  clone {
    vm_id = proxmox_virtual_environment_vm.cloud_init_template.vm_id
  }

  cpu {
    cores = var.worker1_cores
    type  = "host"
  }

  memory {
    dedicated = var.worker1_memory
  }

  disk {
    interface    = "scsi0"
    size         = var.worker1_disk_size
    datastore_id = var.storage_pool
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # --- GPU Passthrough (PCI passthrough) ---
  # Pasa la GPU fisica directamente a la VM.
  # La VM ve la GPU como si estuviera conectada fisicamente a ella.
  # Requisitos en el host Proxmox:
  #   1. IOMMU habilitado en BIOS (VT-d)
  #   2. Modulos vfio cargados en el kernel
  #   3. GPU no usada por el host
  # Solo se anade si has configurado el ID PCI en las variables.
  dynamic "hostpci" {
    for_each = var.worker1_gpu_pci_id != "" ? [1] : []
    content {
      device = "hostpci0"
      id     = var.worker1_gpu_pci_id
      pcie   = true
      rombar = true
    }
  }

  initialization {
    user_account {
      username = var.cloud_init_user
      keys     = var.cloud_init_ssh_public_key != "" ? [var.cloud_init_ssh_public_key] : []
    }

    ip_config {
      ipv4 {
        address = var.worker1_ip
        gateway = var.network_gateway
      }
    }

    dns {
      servers = [var.network_dns]
    }
  }

  on_boot = true
  tags    = ["k3s", "worker", "gpu", "terraform"]
}


# =============================================================================
# VM: WORKER2 - K3s worker ligero
# =============================================================================
# Worker minimalista para cargas ligeras. Menos RAM y cores que worker1.

resource "proxmox_virtual_environment_vm" "k3s_worker2" {
  vm_id     = var.worker2_vmid
  node_name = var.proxmox_node_main
  name      = var.worker2_name

  clone {
    vm_id = proxmox_virtual_environment_vm.cloud_init_template.vm_id
  }

  cpu {
    cores = var.worker2_cores
    type  = "host"
  }

  memory {
    dedicated = var.worker2_memory
  }

  disk {
    interface    = "scsi0"
    size         = var.worker2_disk_size
    datastore_id = var.storage_pool
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    user_account {
      username = var.cloud_init_user
      keys     = var.cloud_init_ssh_public_key != "" ? [var.cloud_init_ssh_public_key] : []
    }

    ip_config {
      ipv4 {
        address = var.worker2_ip
        gateway = var.network_gateway
      }
    }

    dns {
      servers = [var.network_dns]
    }
  }

  on_boot = true
  tags    = ["k3s", "worker", "terraform"]
}
