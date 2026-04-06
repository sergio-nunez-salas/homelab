# Terraform - Infraestructura como Codigo (IaC) del Homelab

## Que es Terraform y por que lo usamos

Terraform es una herramienta que te permite **describir tu infraestructura en ficheros de texto** en lugar de crearla a mano desde una interfaz grafica.

**Sin Terraform (como lo haces ahora):**

1. Abres Proxmox en el navegador
2. Click en "Create VM"
3. Rellenas nombre, RAM, cores, disco...
4. Repites para cada VM
5. Si algo se rompe, tienes que recordar como lo configuraste

**Con Terraform:**

1. Describes las VMs en ficheros `.tf`
2. Ejecutas `terraform apply`
3. Terraform crea todas las VMs automaticamente
4. Si algo se rompe, ejecutas `terraform apply` y se recrea todo igual
5. Los ficheros estan en Git: tienes historial completo de cambios

---

## Requisitos previos

### 1. Instalar Terraform

En la maquina desde la que vayas a ejecutar Terraform (tu PC o una VM):

**Windows (con winget):**

```bash
winget install Hashicorp.Terraform
```

**Linux (Debian/Ubuntu):**

```bash
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

**Verificar instalacion:**

```bash
terraform --version
```

### 2. Crear un API Token en Proxmox

Terraform necesita autenticarse en Proxmox para crear VMs. Lo mas seguro es usar un API token (en vez de tu password de root).

1. Abre la interfaz web de Proxmox: `https://<IP>:8006`
2. Ve a: **Datacenter > Permissions > API Tokens**
3. Click en **Add**
4. Rellena:
   - **User**: `root@pam`
   - **Token ID**: `terraform`
   - **Privilege Separation**: desmarcar (para que tenga todos los permisos)
5. Click **Add**
6. **COPIA EL TOKEN** que aparece (solo se muestra una vez)

El token tiene este formato:

```
root@pam!terraform=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

### 3. Preparar una plantilla cloud-init (para las VMs de K3s)

Cloud-init es un sistema que configura una VM automaticamente en su primer arranque (hostname, IP, usuario, clave SSH). Necesitas crear una plantilla de VM con cloud-init preinstalado.

**En el nodo Proxmox (via SSH):**

```bash
# Descargar imagen cloud de Debian 12
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2

# Crear una VM vacia que servira como plantilla
qm create 9000 --name debian-12-cloudinit --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Importar el disco descargado a la VM
qm importdisk 9000 debian-12-generic-amd64.qcow2 local-lvm

# Configurar el disco importado como disco principal
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Anadir drive de cloud-init (necesario para inyectar config)
qm set 9000 --ide2 local-lvm:cloudinit

# Configurar el orden de arranque
qm set 9000 --boot c --bootdisk scsi0

# Activar QEMU guest agent (para que Proxmox pueda ver la IP de la VM)
qm set 9000 --agent enabled=1

# Convertir la VM en plantilla (ya no se puede modificar, solo clonar)
qm template 9000

# Limpiar el fichero descargado
rm debian-12-generic-amd64.qcow2
```

Ahora tienes una plantilla llamada `debian-12-cloudinit` con ID 9000.

---

## Como usar este directorio

### Paso 1: Configurar tus variables

```bash
# Copiar el fichero de ejemplo
cp terraform.tfvars.example terraform.tfvars

# Editar con tus datos reales
nano terraform.tfvars   # o abrelo con VS Code/Cursor
```

Rellena: URL de Proxmox, API token, IPs de tus VMs, etc.

### Paso 2: Inicializar Terraform

```bash
cd terraform/
terraform init
```

Esto descarga el provider de Proxmox. Solo hay que hacerlo una vez (o cuando cambies de provider/version).

Veras algo como:

```
Initializing the backend...
Initializing provider plugins...
- Installing bpg/proxmox v0.66.0...

Terraform has been successfully initialized!
```

### Paso 3: Ver que haria Terraform (sin tocar nada)

```bash
terraform plan
```

Terraform te muestra EXACTAMENTE que va a crear, modificar o destruir. No toca nada hasta que tu lo confirmes. Es como un "modo preview".

Ejemplo de salida:

```
Plan: 4 to add, 0 to change, 0 to destroy.

  # proxmox_virtual_environment_vm.k3s_master will be created
  + resource "proxmox_virtual_environment_vm" "k3s_master" {
      + name      = "k3s-master"
      + vm_id     = 100
      + node_name = "pve"
      ...
    }
```

### Paso 4: Crear la infraestructura

```bash
terraform apply
```

Terraform te vuelve a mostrar el plan y te pide confirmacion:

```
Do you want to perform these actions?
  Enter a value: yes
```

Escribe `yes` y Terraform creara todas las VMs en Proxmox.

### Paso 5: Ver el estado actual

```bash
# Ver que recursos gestiona Terraform
terraform state list

# Ver detalles de un recurso concreto
terraform state show proxmox_virtual_environment_vm.k3s_master
```

### Paso 6: Modificar algo

Edita el fichero `.tf` correspondiente (por ejemplo, cambia `master_memory` de 4096 a 8192 en `terraform.tfvars`).

```bash
terraform plan   # Ver que va a cambiar
terraform apply  # Aplicar el cambio
```

Terraform solo modificara lo que haya cambiado, no destruye y recrea todo.

### Paso 7: Destruir todo (con cuidado)

```bash
terraform destroy
```

Esto ELIMINA todas las VMs que Terraform creo. Util para empezar de cero, pero **perderas todos los datos de las VMs**.

---

## Estructura de ficheros

| Fichero | Que hace |
|---------|----------|
| `main.tf` | Configura el provider de Proxmox (como conectarse) |
| `variables.tf` | Define todas las variables configurables |
| `terraform.tfvars.example` | Ejemplo de valores (para copiar y rellenar) |
| `terraform.tfvars` | TUS valores reales (NO se sube a Git) |
| `vms-k3s.tf` | Define las 3 VMs del cluster K3s |
| `vm-truenas.tf` | Define la VM de TrueNAS |
| `outputs.tf` | Datos que Terraform muestra al terminar |

---

## Comandos mas usados (cheatsheet)

```bash
terraform init      # Descargar providers (solo la primera vez)
terraform plan      # Ver que haria sin tocar nada
terraform apply     # Crear/modificar infraestructura
terraform destroy   # Eliminar todo lo creado
terraform fmt       # Formatear los ficheros .tf (indentacion)
terraform validate  # Verificar que la sintaxis es correcta
terraform output    # Ver los outputs sin volver a aplicar
terraform state list  # Listar recursos gestionados
```

---

## Diagrama de flujo

```
  terraform.tfvars          variables.tf            main.tf
  (tus datos reales)  --->  (definiciones)  --->  (conexion a Proxmox)
                                  |
                                  v
                          vms-k3s.tf + vm-truenas.tf
                          (definicion de VMs)
                                  |
                          terraform plan
                                  |
                          terraform apply
                                  |
                                  v
                          Proxmox crea las VMs
                                  |
                                  v
                            outputs.tf
                      (muestra IPs y resumen)
```

---

## Proximos pasos (cuando domines esto)

1. **Cloud-init avanzado**: scripts que instalan K3s automaticamente al crear la VM.
2. **Ansible**: herramienta complementaria para configurar las VMs DESPUES de crearlas (instalar paquetes, configurar servicios).
3. **Backend remoto**: guardar el estado de Terraform en un servidor (en vez de en un fichero local) para trabajar en equipo.
4. **Modulos**: reutilizar bloques de Terraform como librerias (por ejemplo, un modulo "vm-k3s" que puedas usar para crear N workers).
