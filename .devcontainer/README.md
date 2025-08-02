# DevContainer Configuration Guide

This document provides comprehensive guidance for configuring and working with development containers in DevPod. DevPod is a multi-AI workspace development environment that leverages VS Code dev containers for consistent, reproducible development experiences.

## Overview

DevPod implements a sophisticated container configuration system designed around three core principles:

1. **Multi-Environment Support**: Flexible container configurations for different development needs
2. **Multi-AI Integration**: Seamless integration with Claude Code and Gemini Code Assist
3. **Persistent Data Strategy**: Intelligent data persistence across container rebuilds and template updates

## Integration Guidelines

Follow this documentation to integrate with dev containers while maintaining organized file structure. The system prioritizes:

- **Persistence Strategy**: User data survives container rebuilds and template updates
- **Upstream Compatibility**: Configuration remains compatible with future DevPod updates  
- **Modular Design**: Keep dev containers general-purpose, not exclusively AI-focused
- **Sustainability**: Maintainable and scalable container configurations

AI-specific requirements are documented in their respective directories, ensuring the dev container configuration remains broadly applicable.

## Essential Commands

### Container Development
```bash
# Open in Dev Container (VS Code)
# Ctrl+Shift+P -> "Dev Containers: Reopen in Container"

# Rebuild container after configuration changes  
# Ctrl+Shift+P -> "Dev Containers: Rebuild Container"

# Test Docker Compose configurations manually
docker-compose -f .devcontainer/ubuntu.docker-compose.yml build --no-cache
docker-compose -f .devcontainer/python-pg.docker-compose.yml up

# Build specific Dockerfile for testing
docker build -f .devcontainer/ubuntu.Dockerfile -t devpod-ubuntu .
docker build -f .devcontainer/python-pg.Dockerfile -t devpod-python-pg .
```

### Container Management
```bash
# View running containers
docker ps

# Access container shell directly
docker exec -it <container-name> /bin/zsh

# Clean up unused containers and images
docker system prune -f
```

## Architecture Overview

### Multi-Environment Container Structure

DevPod provides three distinct container configuration approaches:

#### 1. Docker Compose Environments (`dockerComposeFile`)
Multi-service development environments with orchestrated services:

- **`ubuntu.docker-compose.yml`**: Base Ubuntu environment with custom image
- **`python-pg.docker-compose.yml`**: Python development with PostgreSQL database
- **`ubuntu-base.docker-compose.yml`**: Minimal Ubuntu setup for lightweight development
- **Custom compositions**: User-defined environments in `.devcontainer/custom/`

#### 2. Custom Dockerfile Builds (`dockerFile`)
Single-container environments with custom builds:

- **`ubuntu.Dockerfile`**: Ubuntu Noble with Python and development tools
- **`python-pg.Dockerfile`**: Python-optimized environment with PostgreSQL client
- **`ubuntu-base.Dockerfile`**: Minimal Ubuntu base configuration

#### 3. Public Container Images (`image`)
Pre-built Microsoft dev container images for fastest startup:
- `mcr.microsoft.com/devcontainers/python:3.11` - Python environment
- `mcr.microsoft.com/devcontainers/ubuntu:22.04` - Ubuntu environment
- `mcr.microsoft.com/devcontainers/javascript-node:18` - Node.js environment

### Multi-AI Workspace Integration

DevPod integrates multiple AI coding assistants through a sophisticated mounting and configuration system:

#### AI Extensions
- **Claude Code** (`anthropic.claude-code`): Advanced AI pair programming
- **Gemini Code Assist** (`Google.geminicodeassist`): Google's AI development assistant

#### AI Configuration Structure
```
.ai/                          # System-wide configurations (upstream/version controlled)
├── claude/                   # Claude AI system defaults (recognized by AI as User-Level)
└── gemini/                   # Gemini AI system defaults (recognized by AI as User-Level)

workspace-ai/                 # Workspace-level AI configurations (your customizations)
├── claude/                   # Claude AI workspace settings (recognized by AI as Project-Level)
└── gemini/                   # Gemini AI workspace settings (recognized by AI as Project-Level)

workspace/                    # Your actual project repositories
└── your-repo/                # Individual project with potential repo-level AI configs
    ├── .claude/              # Repo-specific Claude settings (local Project-Level)
    └── .gemini/              # Repo-specific Gemini settings (local Project-Level)
```

#### AI Bind Mount Strategy
DevPod implements a two-level AI configuration system:

1. **System-Wide Defaults** (Shipped upstream, recognized by AI as User-Level):
   ```json
   "source=${localWorkspaceFolder}/.ai/claude/,target=/home/user/.claude/,type=bind"
   "source=${localWorkspaceFolder}/.ai/gemini/,target=/home/user/.gemini/,type=bind"
   ```

2. **Workspace-Level Customizations** (Your environment settings, recognized by AI as Project-Level):
   ```json
   "source=${localWorkspaceFolder}/workspace-ai/claude/,target=/mnt/workspace/.claude/,type=bind"
   "source=${localWorkspaceFolder}/workspace-ai/gemini/,target=/mnt/workspace/.gemini/,type=bind"
   ```

> **Note**: Repository-level configs (like `.claude/` or `.gemini/` in individual repos) are outside DevPod's mount system but can be recognized by AI assistants when invoked from within specific repository directories.

### Persistence Strategy

DevPod uses a hybrid persistence approach combining **bind mounts + gitignore patterns + named volumes**:

#### Persistent Directories (Gitignored, Survive Updates)
- **`.ai/{assistant}/`**: System-wide AI defaults (version controlled via upstream)
- **`workspace-ai/{assistant}/`**: Workspace-level AI configurations (your environment customizations)
- **`.ssh/`**: SSH keys for repository access
- **`workspace/`**: Your actual project repositories and development files
- **`.devcontainer/custom/`**: User's custom container configurations

#### Version Controlled (Shared, Updated with Template)
- **`.devcontainer/devcontainer.json.template`**: Template configuration
- **`.devcontainer/*.docker-compose.yml`**: Pre-built environment definitions
- **`.devcontainer/*.Dockerfile`**: Container build specifications
- **`.devcontainer/README.md`**: This documentation

#### Named Volumes
- **`devpod-home`**: Persistent home directory (`/home/user/`) for user data and AI configurations

### Container Lifecycle Management

DevPod implements a three-phase container setup process for proper initialization:

#### 1. `onCreateCommand` (Container Creation)
Runs immediately after container creation to set up the environment:
```json
"onCreateCommand": {
  "npm-fix": "mkdir -p /tmp/npm/.npm-global && sudo chown -R user:user /usr/local /tmp/npm/.npm-global && npm config set prefix /tmp/npm/.npm-global && export PATH=/tmp/npm/.npm-global/bin:$PATH"
}
```

#### 2. `postCreateCommand` (Post-Creation Setup)
Installs AI coding assistants and dependencies:
```json
"postCreateCommand": {
  "npm-install-claude": "npm install -g @anthropic-ai/claude-code",
  "npm-install-gemini": "npm install -g @google/gemini-cli"
}
```

#### 3. Environment Variables (`remoteEnv`)
Configures the container environment for optimal AI integration:
```json
"remoteEnv": {
  "PATH": "/tmp/npm/.npm-global/bin:${containerEnv:PATH}"
}
```

These hooks ensure proper permissions, tool installation, and environment configuration without manual intervention.

## Configuration Examples

### Template Configuration Overview

The `devcontainer.json.template` provides a comprehensive setup with:

#### Container Features
- **Claude Code Integration**: `ghcr.io/anthropics/devcontainer-features/claude-code:1.0`
- **Enhanced Shell**: `ghcr.io/devcontainers/features/common-utils:2` with Zsh and Oh My Zsh

#### Port Forwarding (AI Compatibility)
```json
"forwardPorts": [
  // 11434,  // Continue/AI extension compatibility
  // 1234,   // LM Studio/AI compatibility  
  // 5272,   // Microsoft AI Toolkit extension
  // 54112   // CodeGPT/AI extension
]
```

### Environment Selection Examples

#### Multi-Service Development (PostgreSQL + Python)
```json
{
  "name": "Python + PostgreSQL",
  "dockerComposeFile": "python-pg.docker-compose.yml",
  "service": "app",
  "workspaceFolder": "/mnt/workspace"
}
```

#### Single Container Ubuntu Environment
```json
{
  "name": "Ubuntu Development",
  "dockerComposeFile": "ubuntu.docker-compose.yml", 
  "service": "app",
  "workspaceFolder": "/mnt/workspace"
}
```

#### Custom Dockerfile Build
```json
{
  "name": "Custom Python Build",
  "dockerFile": "python-pg.Dockerfile",
  "context": ".",
  "workspaceFolder": "/mnt/workspace"
}
```

#### Public Image (Fastest Startup)
```json
{
  "name": "Microsoft Python",
  "image": "mcr.microsoft.com/devcontainers/python:3.11",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}"
}
```

## Development Workflows

### Initial Setup
1. Copy `devcontainer.json.template` to `devcontainer.json`
2. Modify configuration for your specific needs
3. Open project in VS Code
4. Use "Dev Containers: Reopen in Container"

### Environment Switching
1. Edit `devcontainer.json` to change container configuration
2. Rebuild container: "Dev Containers: Rebuild Container"
3. Wait for container initialization and AI tool setup

### AI Integration Setup
1. Ensure `.ai/claude/` and `.ai/gemini/` directories exist (provided by upstream)
2. Configure AI assistants according to their documentation
3. Use `workspace-ai/` for workspace-level customizations
4. Create repo-specific configs in `workspace/your-repo/.claude/` or `workspace/your-repo/.gemini/` as needed

### Custom Environment Creation
1. Create custom configuration files in `.devcontainer/custom/`
2. Reference in `devcontainer.json`:
   ```json
   "dockerComposeFile": "custom/my-stack.docker-compose.yml"
   ```
3. Rebuild container to apply changes

## Best Practices

### Container Configuration
- **Use Docker Compose** for multi-service development (databases, caches, etc.)
- **Use Dockerfiles** for single-service environments with custom tools
- **Use public images** for standard development stacks with fastest startup
- **Keep containers lightweight** by avoiding unnecessary packages

### AI Integration
- **Three-level configuration hierarchy**: System defaults (`.ai/`), workspace customizations (`workspace-ai/`), and repo-specific configs (`workspace/repo/.ai/`)
- **Use gitignore patterns** to keep AI credentials secure
- **Test AI functionality** after container rebuilds
- **Document workspace-specific AI configurations** in workspace-ai directories
- **Keep repo-level configs** minimal and project-specific

### Data Persistence
- **Use bind mounts** for development files that need host access
- **Use named volumes** for container-internal data that should persist
- **Follow gitignore patterns** to prevent credential leakage
- **Backup important configurations** before major changes

### Performance Optimization
- **Enable Docker layer caching** for faster rebuilds
- **Use .dockerignore** to exclude unnecessary files from build context
- **Pre-pull base images** to reduce initial setup time
- **Optimize Dockerfile** by ordering instructions from least to most frequently changing

## Troubleshooting

### Common Container Issues

#### Container Won't Start
```bash
# Check Docker service status
sudo systemctl status docker

# View container logs
docker-compose -f .devcontainer/ubuntu.docker-compose.yml logs

# Remove and rebuild container
docker-compose -f .devcontainer/ubuntu.docker-compose.yml down
docker-compose -f .devcontainer/ubuntu.docker-compose.yml up --build
```

#### Permission Issues
```bash
# Fix file ownership in container
sudo chown -R user:user /home/user/
sudo chown -R user:user /mnt/workspace/

# Check mount permissions
ls -la /home/user/.claude/
ls -la /mnt/workspace/.claude/
```

#### AI Extensions Not Working
1. Verify extensions are installed in VS Code
2. Check AI configuration directories exist and are mounted
3. Restart container if necessary
4. Check extension logs in VS Code Developer Console

#### Port Forwarding Issues
```bash
# Check if ports are in use
netstat -tulpn | grep :11434
netstat -tulpn | grep :1234

# Test port accessibility
curl http://localhost:11434/health
```

### Environment-Specific Issues

#### PostgreSQL Connection Problems
```bash
# Check PostgreSQL service status
docker-compose -f .devcontainer/python-pg.docker-compose.yml exec db pg_isready

# Connect to database manually
docker-compose -f .devcontainer/python-pg.docker-compose.yml exec db psql -U postgres
```

#### Python Package Installation Issues
```bash
# Update pip in container
pip install --upgrade pip

# Install packages with user permissions
pip install --user package-name

# Check Python path configuration
python -c "import sys; print(sys.path)"
```

## File Structure Reference

```
DevPod/
├── .devcontainer/
│   ├── devcontainer.json.template          # Template configuration (version controlled)
│   ├── ubuntu.docker-compose.yml           # Ubuntu environment
│   ├── ubuntu-base.docker-compose.yml      # Minimal Ubuntu environment
│   ├── python-pg.docker-compose.yml        # Python + PostgreSQL stack
│   ├── ubuntu.Dockerfile                   # Ubuntu container build
│   ├── ubuntu-base.Dockerfile              # Minimal Ubuntu build
│   ├── python-pg.Dockerfile                # Python + PostgreSQL build
│   ├── custom/                             # User custom environments (gitignored)
│   └── README.md                           # This documentation
├── .ai/                                    # AI system-wide defaults (version controlled via upstream)
│   ├── claude/                             # Claude AI system configuration
│   └── gemini/                             # Gemini AI system configuration
├── workspace-ai/                           # AI workspace-level config (your customizations)
│   ├── claude/                             # Claude AI workspace settings
│   └── gemini/                             # Gemini AI workspace settings
├── .ssh/                                   # SSH keys (gitignored, persistent)
├── workspace/                              # User projects (gitignored, persistent)
├── README.md                               # Project documentation
└── git.md                                  # Common git commands & SSH key management guide
```

This two-level architecture ensures:
- **System defaults** are maintained via upstream updates
- **Workspace customizations** persist across container rebuilds
- **Seamless environment** with proper configuration hierarchy recognition