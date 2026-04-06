# =============================================================================
# main.tf - Configuracion principal de Terraform
# =============================================================================
#
# CONCEPTOS CLAVE:
#
# - "Provider": es el plugin que Terraform usa para hablar con una plataforma.
#   En nuestro caso, el provider de Proxmox permite crear VMs, discos, redes,
#   etc. en tu servidor Proxmox a traves de su API.
#
# - "terraform { }": bloque donde defines la version de Terraform y los
#   providers que necesitas. Es lo primero que Terraform lee.
#
# - "provider { }": bloque donde configuras COMO conectarte a Proxmox
#   (URL, credenciales, etc.)
#
# =============================================================================

# --- Bloque terraform: define que providers necesitamos ---
# Esto es como un "package.json" o "requirements.txt": lista las dependencias.
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      # "bpg/proxmox" es el provider mas moderno y mantenido para Proxmox VE.
      # Terraform lo descargara automaticamente al ejecutar "terraform init".
      source  = "bpg/proxmox"
      version = ">= 0.66.0"
    }
  }
}

# --- Bloque provider: como nos conectamos a Proxmox ---
# Aqui NO ponemos credenciales directamente. Las leemos de variables
# (definidas en variables.tf y rellenadas en terraform.tfvars).
provider "proxmox" {
  # URL de la API de Proxmox. Ejemplo: "https://192.168.1.100:8006"
  # IMPORTANTE: es la misma URL que usas para entrar a la interfaz web,
  # pero Terraform habla con la API, no con la web.
  endpoint = var.proxmox_url

  # Credenciales para autenticarse en Proxmox.
  # Puedes usar usuario+password O un API token (mas seguro).
  # Recomendacion: crea un API token en Proxmox > Datacenter > API Tokens.
  api_token = var.proxmox_api_token

  # Si tu Proxmox usa un certificado SSL autofirmado (lo normal en homelab),
  # esto evita que Terraform rechace la conexion por "certificado no confiable".
  insecure = true

  # Configuracion de SSH para operaciones que requieren acceso directo
  # al nodo (como subir ISOs o plantillas cloud-init).
  ssh {
    agent = false
  }
}
