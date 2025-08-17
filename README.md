# 🌊 Nitrox 2.0 - Docker VPS Edition

[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://hub.docker.com/r/nitrox/server)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Supported-326CE5?logo=kubernetes)](./kubernetes/)
[![License](https://img.shields.io/badge/License-GPL--3.0-green)](LICENSE.txt)
[![Build Status](https://img.shields.io/badge/Build-Passing-brightgreen)](https://github.com/SkuuIll/NITROX2.0)

**Nitrox 2.0** es una versión mejorada del popular mod multijugador para Subnautica, ahora con **soporte completo para Docker y despliegue en VPS**. Permite a múltiples jugadores explorar, construir y sobrevivir juntos en el mundo oceánico de Subnautica.

## 🚀 Nuevas Características Docker

### ✨ **Despliegue Automatizado**
- **Configuración VPS con un comando**: Script automatizado para preparar servidores
- **Descarga automática de Subnautica**: Integración con SteamCMD
- **Docker Compose listo para usar**: Configuración plug-and-play
- **Soporte Kubernetes**: Manifiestos completos para producción

### 🔧 **Gestión Avanzada**
- **Health Checks integrados**: Monitoreo automático del servidor
- **Backups automáticos**: Sistema de respaldo con rotación
- **Configuración via variables de entorno**: Fácil personalización
- **Logging estructurado**: Logs optimizados para contenedores

### 🛡️ **Seguridad y Rendimiento**
- **Usuario no-root**: Ejecución segura en contenedores
- **Validación de seguridad**: Auditorías automáticas
- **Optimizaciones de red**: Configuración optimizada para VPS
- **Escalado automático**: Soporte HPA en Kubernetes

## 🏃‍♂️ Inicio Rápido

### Opción 1: Despliegue Automático en VPS

```bash
# 1. Configurar VPS (Ubuntu/Debian/CentOS)
curl -fsSL https://raw.githubusercontent.com/SkuuIll/NITROX2.0/master/scripts/setup-vps.sh | sudo bash

# 2. Desplegar servidor Nitrox
./scripts/deploy-vps.sh \
  --admin-password "tu_password_admin" \
  --steam-user "tu_usuario_steam" \
  --steam-pass "tu_password_steam" \
  --server-name "Mi Servidor Nitrox"
```

### Opción 2: Docker Compose Local

```bash
# Clonar repositorio
git clone https://github.com/SkuuIll/NITROX2.0.git
cd NITROX2.0

# Configurar variables de entorno
cp docker-compose.yml docker-compose.local.yml
# Editar docker-compose.local.yml con tus credenciales

# Iniciar servidor
docker-compose -f docker-compose.local.yml up -d
```

### Opción 3: Kubernetes

```bash
# Aplicar manifiestos
kubectl apply -f kubernetes/

# Configurar secretos
kubectl create secret generic steam-credentials \
  --from-literal=username=tu_usuario_steam \
  --from-literal=password=tu_password_steam

kubectl create secret generic nitrox-secrets \
  --from-literal=admin-password=tu_password_admin
```

## 📋 Configuración

### Variables de Entorno

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `NITROX_SERVER_NAME` | Nombre del servidor | `"Nitrox Docker Server"` |
| `NITROX_SERVER_PORT` | Puerto UDP del servidor | `11000` |
| `NITROX_ADMIN_PASSWORD` | Password de administrador | **Requerido** |
| `NITROX_SERVER_PASSWORD` | Password del servidor (opcional) | `""` |
| `NITROX_GAME_MODE` | Modo de juego | `"Survival"` |
| `NITROX_MAX_PLAYERS` | Máximo de jugadores | `100` |
| `STEAM_USERNAME` | Usuario de Steam | **Requerido** |
| `STEAM_PASSWORD` | Password de Steam | **Requerido** |

### Ejemplo Docker Compose

```yaml
version: '3.8'
services:
  nitrox-server:
    image: nitrox/server:latest
    ports:
      - "11000:11000/udp"
    environment:
      - NITROX_SERVER_NAME=Mi Servidor Increíble
      - NITROX_ADMIN_PASSWORD=password_super_seguro
      - STEAM_USERNAME=mi_usuario_steam
      - STEAM_PASSWORD=mi_password_steam
      - NITROX_GAME_MODE=Survival
      - NITROX_MAX_PLAYERS=50
    volumes:
      - nitrox_gamefiles:/app/gamefiles
      - nitrox_saves:/app/saves
      - nitrox_config:/app/config
    restart: unless-stopped

volumes:
  nitrox_gamefiles:
  nitrox_saves:
  nitrox_config:
```

## 🛠️ Comandos Útiles

### Makefile (Desarrollo)

```bash
# Construir imagen Docker
make build

# Desplegar localmente
make deploy-local

# Ver logs del servidor
make logs

# Verificar estado
make status

# Actualizar servidor
make update

# Crear backup
make backup

# Limpiar recursos Docker
make clean
```

### Scripts de Gestión

```bash
# Estado del servidor
./scripts/deploy-vps.sh --status

# Ver logs en tiempo real
./scripts/deploy-vps.sh --logs

# Parar servidor
./scripts/deploy-vps.sh --stop

# Actualizar a nueva versión
./scripts/deploy-vps.sh --update --image nitrox/server:latest
```

## 🏗️ Arquitectura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Clientes      │    │   Load Balancer  │    │   VPS/Cloud     │
│   Subnautica    │◄──►│   (Opcional)     │◄──►│   Docker Host   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                         │
                       ┌─────────────────────────────────┼─────────────────────────────────┐
                       │                                 │                                 │
                ┌──────▼──────┐                 ┌────────▼────────┐                ┌─────▼─────┐
                │   Nitrox    │                 │   Game Files    │                │  Backups  │
                │   Server    │                 │   (SteamCMD)    │                │  & Logs   │
                │ Container   │                 │    Volume       │                │  Volume   │
                └─────────────┘                 └─────────────────┘                └───────────┘
```

## 📊 Características Técnicas

### Requisitos del Sistema
- **CPU**: 2+ cores recomendados
- **RAM**: 4GB mínimo, 8GB recomendado
- **Almacenamiento**: 25GB+ (20GB para Subnautica + datos del servidor)
- **Red**: Puerto UDP 11000 abierto
- **OS**: Linux (Ubuntu 20.04+, Debian 11+, CentOS 8+)

### Tecnologías Utilizadas
- **Docker & Docker Compose**: Containerización
- **Kubernetes**: Orquestación en producción
- **SteamCMD**: Descarga automática de archivos del juego
- **.NET 9.0**: Runtime del servidor
- **Serilog**: Logging estructurado
- **Health Checks**: Monitoreo integrado

## 🔧 Desarrollo

### Construir desde Código Fuente

```bash
# Clonar repositorio
git clone https://github.com/SkuuIll/NITROX2.0.git
cd NITROX2.0

# Construir imagen Docker
./scripts/build-docker.sh --tag latest

# Ejecutar tests
make test

# Análisis de seguridad
make security-scan
```

### Estructura del Proyecto

```
NITROX2.0/
├── docker/                 # Scripts Docker
├── kubernetes/             # Manifiestos K8s
├── scripts/               # Scripts de automatización
├── NitroxServer/Docker/   # Código Docker específico
├── Dockerfile             # Imagen principal
├── docker-compose.yml     # Configuración Compose
└── Makefile              # Comandos automatizados
```

## 🤝 Contribuir

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/nueva-caracteristica`)
3. Commit tus cambios (`git commit -am 'Añadir nueva característica'`)
4. Push a la rama (`git push origin feature/nueva-caracteristica`)
5. Abre un Pull Request

## 📝 Changelog

### v2.0.0 - Docker VPS Edition
- ✅ **Soporte completo para Docker**
- ✅ **Despliegue automatizado en VPS**
- ✅ **Integración SteamCMD**
- ✅ **Soporte Kubernetes y Docker Swarm**
- ✅ **Health checks y monitoreo**
- ✅ **Sistema de backups automáticos**
- ✅ **Configuración via variables de entorno**
- ✅ **Seguridad hardening**
- ✅ **Scripts de automatización**
- ✅ **Documentación completa**

## 🆘 Soporte

### Problemas Comunes

**Error: "Game files not found"**
```bash
# Verificar credenciales de Steam
docker logs nitrox-server | grep -i steam

# Verificar volúmenes
docker volume ls | grep nitrox
```

**Error: "Port already in use"**
```bash
# Verificar puertos en uso
netstat -tulpn | grep 11000

# Cambiar puerto en docker-compose.yml
ports:
  - "11001:11000/udp"  # Usar puerto diferente
```

**Performance Issues**
```bash
# Verificar recursos
docker stats nitrox-server

# Ajustar límites de memoria
deploy:
  resources:
    limits:
      memory: 8G
```

### Enlaces Útiles
- 📖 [Documentación Completa](https://github.com/SkuuIll/NITROX2.0/wiki)
- 🐛 [Reportar Bugs](https://github.com/SkuuIll/NITROX2.0/issues)
- 💬 [Discord Community](https://discord.gg/nitrox)
- 🎮 [Guía de Instalación](https://github.com/SkuuIll/NITROX2.0/blob/master/docs/INSTALLATION.md)

## 📄 Licencia

Este proyecto está licenciado bajo la Licencia GPL-3.0 - ver el archivo [LICENSE.txt](LICENSE.txt) para más detalles.

## 🙏 Agradecimientos

- **Equipo original de Nitrox** por crear este increíble mod
- **Comunidad de Subnautica** por el apoyo continuo
- **Contribuidores** que han mejorado el proyecto
- **Unknown Worlds Entertainment** por crear Subnautica

---

<div align="center">

**🌊 ¡Sumérgete en la aventura multijugador de Subnautica! 🌊**

[⬆️ Volver al inicio](#-nitrox-20---docker-vps-edition)

</div>