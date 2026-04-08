# Ansible - Configuracion automatica del cluster K3s

## Que es Ansible y por que lo usamos

Ansible es una herramienta que **ejecuta comandos en servidores remotos de forma automatica**. Se conecta por SSH y ejecuta las tareas que defines en ficheros YAML.

**Sin Ansible (como lo hacias antes):**

1. Entras por SSH a cada VM
2. Ejecutas `apt update && apt install curl...`
3. Ejecutas el script de K3s
4. Repites para cada worker, copiando el token a mano
5. Si algo se rompe, tienes que recordar todos los pasos

**Con Ansible:**

1. Defines los pasos en ficheros YAML (una sola vez)
2. Ejecutas `ansible-playbook playbooks/site.yml`
3. Ansible entra a las 3 VMs y lo configura todo solo
4. Si algo se rompe, ejecutas otra vez y solo repite lo que falta

---

## Diferencia entre Terraform y Ansible

| | Terraform | Ansible |
|--|-----------|---------|
| **Que hace** | Crea infraestructura (VMs, discos, redes) | Configura lo que hay dentro (paquetes, servicios) |
| **Cuando se usa** | ANTES: para crear las VMs en Proxmox | DESPUES: cuando las VMs ya existen |
| **Conexion** | API de Proxmox | SSH a las VMs |
| **Ejemplo** | "Crea una VM con 4GB de RAM" | "Instala K3s en esa VM" |

El flujo completo:

```
Terraform (crea VMs) --> Ansible (instala K3s) --> ArgoCD (despliega apps)
```

---

## Requisitos previos

### 1. Instalar Ansible

Ansible se ejecuta desde tu maquina local (o desde una VM de control). **No se instala en los servidores remotos** — solo necesita SSH para conectarse.

**Linux (Debian/Ubuntu):**

```bash
sudo apt update
sudo apt install -y ansible
```

**Windows (via WSL o desde una VM Linux):**

Ansible no funciona nativamente en Windows. Opciones:
- Usar WSL (Windows Subsystem for Linux)
- Ejecutarlo desde una de tus VMs que tenga acceso SSH a las demas

**Verificar instalacion:**

```bash
ansible --version
```

### 2. Tener acceso SSH a las VMs

Ansible se conecta por SSH con el usuario `sergio` (configurado en `ansible.cfg`). Necesitas:

- Que las VMs esten encendidas y accesibles por red
- Que tu clave SSH publica este en las VMs (cloud-init la inyecta automaticamente)

Puedes probar la conexion con:

```bash
# Probar que Ansible puede conectarse a todas las VMs
cd ansible/
ansible all -m ping
```

Si todo va bien, veras algo como:

```
k3s-master | SUCCESS => { "ping": "pong" }
k3s-worker1 | SUCCESS => { "ping": "pong" }
k3s-worker2 | SUCCESS => { "ping": "pong" }
```

---

## Estructura de ficheros

| Fichero / Carpeta | Que hace |
|-------------------|----------|
| `ansible.cfg` | Configuracion de Ansible (usuario SSH, inventario, sudo) |
| `inventory/hosts.yml` | Lista de VMs agrupadas por rol (master, workers) |
| `playbooks/site.yml` | Playbook principal: despliega todo el cluster |
| `playbooks/k3s-master.yml` | Solo configura el master |
| `playbooks/k3s-workers.yml` | Solo configura los workers |
| `roles/common/` | Tareas comunes: actualizar SO, instalar paquetes, desactivar swap |
| `roles/k3s_master/` | Instalar K3s server y guardar token de union |
| `roles/k3s_worker/` | Instalar K3s agent y unirse al cluster |

---

## Como usar

### Desplegar el cluster completo (primera vez)

```bash
cd ansible/
ansible-playbook playbooks/site.yml
```

Esto ejecuta en orden:
1. Prepara las 3 VMs (actualizaciones, dependencias, swap, kernel)
2. Instala K3s server en el master
3. Une los 2 workers al cluster

### Solo reinstalar el master

```bash
ansible-playbook playbooks/k3s-master.yml
```

### Solo anadir/reinstalar workers

```bash
ansible-playbook playbooks/k3s-workers.yml
```

### Probar conexion sin ejecutar nada

```bash
# Ping a todas las VMs
ansible all -m ping

# Ping solo al master
ansible master -m ping

# Ping solo a los workers
ansible workers -m ping
```

### Ejecutar un comando rapido en todas las VMs

```bash
# Ver el hostname de cada VM
ansible all -m command -a "hostname"

# Ver la RAM disponible
ansible all -m command -a "free -h"

# Ver el estado de K3s en el master
ansible master -m command -a "kubectl get nodes"
```

---

## Comandos mas usados (cheatsheet)

```bash
# Desplegar todo
ansible-playbook playbooks/site.yml

# Desplegar con mas detalle (verbose)
ansible-playbook playbooks/site.yml -v

# Simular sin ejecutar nada (dry-run)
ansible-playbook playbooks/site.yml --check

# Ejecutar solo tareas con un tag especifico (futuro)
ansible-playbook playbooks/site.yml --tags "common"

# Ver que hosts estan en un grupo
ansible-inventory --list

# Probar conexion SSH
ansible all -m ping
```

---

## Diagrama de flujo

```
  inventory/hosts.yml         ansible.cfg           playbooks/site.yml
  (IPs de las VMs)     -->  (como conectarse)  -->  (que ejecutar)
                                                          |
                                                          v
                                          +-------------------------------+
                                          |  Fase 1: roles/common        |
                                          |  (en master + workers)       |
                                          |  apt update, swap off, etc.  |
                                          +-------------------------------+
                                                          |
                                                          v
                                          +-------------------------------+
                                          |  Fase 2: roles/k3s_master    |
                                          |  (solo en master)            |
                                          |  Instalar K3s server         |
                                          |  Guardar token               |
                                          +-------------------------------+
                                                          |
                                                    token del master
                                                          |
                                                          v
                                          +-------------------------------+
                                          |  Fase 3: roles/k3s_worker    |
                                          |  (solo en workers)           |
                                          |  Instalar K3s agent          |
                                          |  Unirse al cluster           |
                                          +-------------------------------+
                                                          |
                                                          v
                                                  Cluster K3s listo
```
