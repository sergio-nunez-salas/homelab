# =============================================================================
# outputs.tf - Datos que Terraform muestra tras ejecutar "terraform apply"
# =============================================================================
#
# CONCEPTO CLAVE:
#
# - "output": es un valor que Terraform imprime en la terminal cuando termina.
#   Es util para ver las IPs de las VMs creadas, sus IDs, etc.
#   Tambien sirve para pasar datos entre modulos de Terraform (mas avanzado).
#
# Despues de ejecutar "terraform apply", veras algo asi en la terminal:
#
#   Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
#
#   Outputs:
#
#   master_ip = "192.168.1.50"
#   worker1_ip = "192.168.1.51"
#   ...
#
# =============================================================================

output "master_ip" {
  description = "IP del nodo master de K3s"
  value       = var.master_ip
}

output "master_vmid" {
  description = "ID de la VM del master en Proxmox"
  value       = var.master_vmid
}

output "worker1_ip" {
  description = "IP del worker1 (IALAB) con GPU"
  value       = var.worker1_ip
}

output "worker1_vmid" {
  description = "ID de la VM del worker1 en Proxmox"
  value       = var.worker1_vmid
}

output "worker2_ip" {
  description = "IP del worker2 (ligero)"
  value       = var.worker2_ip
}

output "worker2_vmid" {
  description = "ID de la VM del worker2 en Proxmox"
  value       = var.worker2_vmid
}

output "truenas_ip" {
  description = "IP de TrueNAS (almacenamiento NFS)"
  value       = var.truenas_ip
}

output "truenas_vmid" {
  description = "ID de la VM de TrueNAS en Proxmox"
  value       = var.truenas_vmid
}

output "cluster_summary" {
  description = "Resumen del cluster K3s"
  value       = <<-EOT

    ╔══════════════════════════════════════════════════════╗
    ║           CLUSTER K3s - HOMELAB                     ║
    ╠══════════════════════════════════════════════════════╣
    ║  MASTER:  ${var.master_ip}  (${var.master_memory}MB RAM, ${var.master_cores} cores)
    ║  WORKER1: ${var.worker1_ip}  (${var.worker1_memory}MB RAM, ${var.worker1_cores} cores, GPU)
    ║  WORKER2: ${var.worker2_ip}  (${var.worker2_memory}MB RAM, ${var.worker2_cores} cores)
    ║  TRUENAS: ${var.truenas_ip}  (${var.truenas_memory}MB RAM, NFS)
    ╚══════════════════════════════════════════════════════╝

  EOT
}
