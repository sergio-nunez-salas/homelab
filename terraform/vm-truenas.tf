# =============================================================================
# vm-truenas.tf - Maquina virtual de TrueNAS Scale
# =============================================================================
#
# TrueNAS Scale es tu servidor de almacenamiento. Gestiona el HDD de 1TB
# con ZFS y lo exporta via NFS para que Kubernetes lo use como volumen
# persistente (a traves del provisionador nfs-client).
#
# DIFERENCIAS CON LAS VMs DE K3s:
#
# - NO usa cloud-init (TrueNAS tiene su propio instalador).
#   Se instala desde ISO manualmente la primera vez.
#
# - Tiene un disco extra: el HDD de 1TB pasado por passthrough.
#   Proxmox le entrega el disco fisico entero a la VM, como si estuviera
#   conectado directamente. Esto es necesario para que ZFS funcione bien.
#
# =============================================================================

resource "proxmox_virtual_environment_vm" "truenas" {
  vm_id     = var.truenas_vmid
  node_name = var.proxmox_node_main
  name      = var.truenas_name

  # TrueNAS no se clona de plantilla: se instala desde ISO.
  # Cuando ejecutes "terraform apply" por primera vez, esta VM se creara
  # VACIA. Tendras que conectar la ISO de TrueNAS y arrancarla manualmente
  # desde la consola de Proxmox para instalar el SO.
  #
  # Despues de la primera instalacion, Terraform gestionara la VM
  # (encenderla, apagarla, cambiar specs) sin tocar el SO instalado.

  cpu {
    cores = var.truenas_cores
    type  = "host"
  }

  # TrueNAS usa mucha RAM para la cache ZFS (ARC).
  # 8GB es el minimo recomendado. ZFS cachea datos en RAM para acelerar
  # lecturas, asi que cuanta mas RAM le des, mejor rendimiento de disco.
  memory {
    dedicated = var.truenas_memory
  }

  # --- Disco del sistema ---
  # Aqui se instala TrueNAS Scale. Es un disco pequeno (32GB)
  # que solo contiene el sistema operativo.
  disk {
    interface    = "scsi0"
    size         = var.truenas_disk_size
    datastore_id = var.storage_pool
  }

  # --- HDD 1TB passthrough (disco de datos) ---
  # Este es el disco fisico de 1TB que TrueNAS gestionara con ZFS.
  # Se pasa "en crudo" a la VM: Proxmox no lo toca, TrueNAS lo ve
  # como un disco fisico directo.
  #
  # NOTA: Solo se anade si has configurado el ID del disco en las variables.
  # Si no lo configuras, la VM se crea sin disco de datos y puedes
  # anadirlo manualmente despues desde Proxmox.
  dynamic "disk" {
    for_each = var.truenas_hdd_passthrough_id != "" ? [1] : []
    content {
      interface    = "scsi1"
      datastore_id = var.storage_pool
      size         = 1000
      file_id      = var.truenas_hdd_passthrough_id
    }
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  # --- Configuracion de red via cloud-init ---
  # Aunque TrueNAS no usa cloud-init para instalar el SO,
  # le pasamos la config de red para que Proxmox la tenga registrada.
  initialization {
    ip_config {
      ipv4 {
        address = var.truenas_ip
        gateway = var.network_gateway
      }
    }

    dns {
      servers = [var.network_dns]
    }
  }

  on_boot = true
  tags    = ["storage", "truenas", "terraform"]
}
