# AI Integration Guide for DevPod

This document provides comprehensive technical guidance for integrating AI code assistants within DevPod's multi-AI workspace system using a streamlined workspace-ai customization approach.

> **📋 Terminology Note**: DevPod implements a two-level configuration system that maps to AI assistant standards as follows:
> - **DevPod "System-Wide"** → AI recognizes as **"User Level"** (upstream defaults)
> - **DevPod "Workspace-Level"** → AI recognizes as **"Project Level"** (environment customizations)  
> 
> Repository-level configs are outside DevPod's scope but can be recognized by AI assistants based on their working directory context.
> 
> This design provides seamless AI integration while maintaining organized, version-controlled development environments.

## Overview

DevPod supports multiple AI assistants through a sophisticated two-level configuration system that enables upstream defaults and workspace customizations. The system currently supports:

- **Claude Code** (Anthropic's AI assistant)
- **Gemini Code Assist** (Google's AI assistant)

## Architecture: Two-Level Configuration System

### Level 1: System-Wide Defaults (Upstream/Version Controlled)
**Location**: `.ai/{assistant}/`  
**Mount Target**: `/home/user/.{assistant}/` (Recognized by AI as "User Level")  
**Purpose**: DevPod-shipped configurations, maintained via upstream updates  
**Control**: Managed by DevPod team, customizable via your fork's git configuration  

### Level 2: Workspace-Level Customizations (Your Environment)
**Location**: `workspace-ai/{assistant}/`  
**Mount Target**: `/mnt/workspace/.{assistant}/` (Recognized by AI as "Project Level")  
**Purpose**: Your development environment customizations across all projects  
**Control**: Fully managed by you, version controlled with your DevPod repository  

> **💡 Note on Repository-Level Configs**: While not part of DevPod's configuration system, AI assistants can recognize repository-specific configs (like `.claude/` or `.gemini/` directories) when invoked from within individual repository directories in `workspace/`. This behavior depends on the AI assistant's working directory context and is handled outside DevPod's scope.

This two-level architecture ensures:
- **System defaults** ship with DevPod and stay current via upstream updates
- **Workspace customizations** persist across container rebuilds and projects
- **Seamless environment** with proper configuration hierarchy
- **Best practices adoption** through thoughtful configuration organization

## Container Integration Strategy

### Bind Mount Configuration

The devcontainer implements strategic bind mounts as defined in `devcontainer.json`:

```json
"mounts": [
  // Authentication & core config persistence
  "source=devpod-home,target=/home/user/,type=volume",
  
  // System-level AI configurations (upstream)
  "source=${localWorkspaceFolder}/.ai/claude/,target=/home/user/.claude/,type=bind",
  "source=${localWorkspaceFolder}/.ai/gemini/,target=/home/user/.gemini/,type=bind",
  
  // Project-level AI configurations (user customization)
  "source=${localWorkspaceFolder}/workspace-ai/claude/,target=/mnt/workspace/.claude/,type=bind",
  "source=${localWorkspaceFolder}/workspace-ai/gemini/,target=/mnt/workspace/.gemini/,type=bind"
]
```

### Mount Point Strategy

1. **Named Volume for Authentication**: `devpod-home` volume persists authentication tokens and core configurations in the container's home directory
2. **System-Level Bind Mounts**: `.ai/{assistant}/` directories provide upstream defaults (AI recognizes as User Level)
3. **Workspace-Level Bind Mounts**: `workspace-ai/{assistant}/` directories enable environment customization (AI recognizes as Project Level)

## Setup Instructions

### Prerequisites

Ensure your devcontainer configuration follows the **[.devcontainer/README.md](../.devcontainer/README.md)** integration guidelines.

### 1. Claude Code Setup

#### System-Wide Defaults (Level 1)
The system-level configuration directories (`.ai/claude/`, `.ai/gemini/`) are **shipped with DevPod** and maintained upstream. These contain:

- `agents/` - AI assistant profiles and configurations
- `commands/` - Structured AI workflows  
- `mcp/` - Model Context Protocol integrations
- `CLAUDE.md` or `GEMINI.md` - System-level memory/context files

These are version-controlled and updated with DevPod releases. AI assistants recognize these as "User Level" configurations.

#### Workspace-Level Customizations (Level 2)
```bash
# Create workspace-specific Claude directory
mkdir -p workspace-ai/claude/

# Add workspace-level configurations that will appear in /mnt/workspace/.claude/
# AI assistants recognize these as "Project Level" customizations
echo "Workspace-specific context and preferences" > workspace-ai/claude/CLAUDE.md
```


#### VS Code Extension Integration
The Claude Code extension is automatically installed via devcontainer configuration:
```json
"extensions": [
  "anthropic.claude-code"
]
```

### 2. Gemini Code Assist Setup

#### System-Wide Defaults (Level 1)
The system-level Gemini configuration (`.ai/gemini/`) is **shipped with DevPod** and contains:

- `GEMINI.md` - System-level memory/context file
- Additional Gemini-specific configurations as needed

These are maintained upstream and updated with DevPod releases. AI assistants recognize these as "User Level" configurations.

#### Workspace-Level Customizations (Level 2)
```bash
# Create workspace-specific Gemini directory
mkdir -p workspace-ai/gemini/

# Add workspace-level configurations that will appear in /mnt/workspace/.gemini/
# AI assistants recognize these as "Project Level" customizations
echo "Workspace-specific context and preferences" > workspace-ai/gemini/GEMINI.md
```


#### VS Code Extension Integration
```json
"extensions": [
  "Google.geminicodeassist"
]
```

### 3. MCP (Model Context Protocol) Setup

DevPod ships with MCP server templates as `.template` files. Copy and remove `.template` extension to use:

```bash
# Copy MCP templates to activate them (example)
cp ~/.claude/mcp/context7/config.json.template ~/.claude/mcp/context7/config.json

# Use DevPod alias to reload MCP servers with config.json files
reload-dp-claude-mcp
```

#### Manual MCP Reload Command

```bash
# Reload only MCP servers that have config.json files (preserves other custom MCPs)
for dir in ~/.claude/mcp/*/; do
  [ -d "$dir" ] && [ -f "$dir/config.json" ] && {
    claude mcp remove "$(basename "$dir")" -s user 2>/dev/null
    claude mcp add-json "$(basename "$dir")" "$(cat "$dir/config.json")" -s user
  }
done 2>/dev/null
claude mcp list
```

> **Note**: This only reloads MCPs that have `config.json` files, preserving any custom MCP servers you may have configured outside the DevPod framework.

### 4. CLI Tools Installation

AI CLI tools are automatically installed via postCreateCommand hooks:
```json
"postCreateCommand": {
  "npm-install-claude": "npm install -g @anthropic-ai/claude-code",
  "npm-install-gemini": "npm install -g @google/gemini-cli"
}
```

## Authentication & Persistence

### Authentication Strategy
- **Primary Storage**: Named volume `devpod-home` mounted to `/home/user/`
- **Persistence**: Authentication tokens and core configurations survive container rebuilds
- **Security**: Authentication data is not bound to host filesystem for security

### Configuration Hierarchy
1. **Container Home** (`/home/user/`): Core authentication and user-level settings (persistent volume)
2. **System-Wide** (`/home/user/.{assistant}/`): DevPod defaults and shared configurations (AI: User Level)
3. **Workspace-Level** (`/mnt/workspace/.{assistant}/`): Your environment customizations (AI: Project Level)

> **Note**: Repository-level configs can exist within individual project directories in `workspace/` but are outside DevPod's configuration system. AI assistants may recognize these based on their working directory context.

## Version Control Best Practices

### Current .gitignore Configuration

DevPod uses a strategic gitignore approach as configured in the project:

```gitignore
# AI ASSISTANT CONFIGURATION
.ai/claude/*
!.ai/claude/.gitkeep
!.ai/claude/agents
!.ai/claude/commands
!.ai/claude/mcp
!.ai/claude/CLAUDE.md

.ai/gemini/*
!.ai/gemini/.gitkeep
!.ai/gemini/GEMINI.md
```

This approach:
- **Ignores everything** in AI assistant directories by default
- **Explicitly tracks** only essential upstream directories and files
- **Prevents unwanted files** from being committed (cache, auth tokens, etc.)
- **Maintains version control** for system-level configurations

### Version Control Strategy
- **Include**: Shared documentation, upstream configurations
- **Exclude**: Authentication tokens, user-specific settings, temporary files
- **Optional**: Project-specific customizations (depending on team sharing preferences)

## Workspace-AI Integration

The `workspace-ai/` directory contains your workspace-level AI customizations that will appear inside the container as:

- `workspace-ai/claude/` → `/mnt/workspace/.claude/` (workspace-level Claude config, recognized by AI as Project Level)
- `workspace-ai/gemini/` → `/mnt/workspace/.gemini/` (workspace-level Gemini config, recognized by AI as Project Level)

This allows AI assistants to recognize your workspace-specific contexts, memory files, and configurations while keeping system-wide defaults intact.

> **Repository-Level Context**: Individual project repositories in `workspace/` can have their own `.claude/` or `.gemini/` directories. These will be recognized by AI assistants when invoked from within those specific repository directories, but are outside DevPod's mount configuration.

## Advanced Configuration

### Custom Extensions Integration
Add additional AI-related extensions in devcontainer.json:
```json
"extensions": [
  "anthropic.claude-code",
  "Google.geminicodeassist",
  "ms-toolsai.jupyter",           // For AI-assisted data science
  "GitHub.copilot"                // Additional AI assistant
]
```

### Port Forwarding for AI Tools
Configure port forwarding for AI compatibility:
```json
"forwardPorts": [
  11434,  // Continue/AI extension compatibility
  1234,   // LM Studio/AI compatibility
  5272,   // Microsoft AI Toolkit extension
  54112   // CodeGPT/AI extension
]
```

### Environment Variables
**⚠️ Security Warning**: Never include API keys or secrets directly in `devcontainer.json` as they will be committed to the repository.

**Best Practice**: Use `.env` files with bind mounts (documented in `.devcontainer/README.md`):
```bash
# Create .env file (gitignored)
echo "ANTHROPIC_API_KEY=your_key_here" > .env

# Bind mount .env file in devcontainer.json
"mounts": [
  "source=${localWorkspaceFolder}/.env,target=/mnt/workspace/.env,type=bind"
]
```

## File Structure Reference

```
DevPod/
├── .ai/                                   # System-wide AI defaults (upstream/version controlled)
│   ├── README.md                          # This documentation
│   ├── claude/                            # Claude system configurations (AI: User Level)
│   │   ├── agents/                        # AI assistant profiles (upstream)
│   │   ├── commands/                      # Structured AI workflows (upstream)
│   │   ├── mcp/                           # Model Context Protocol
│   │   └── CLAUDE.md                      # System-level memory/context
│   └── gemini/                            # Gemini system configurations (AI: User Level)
│       └── GEMINI.md                      # System-level memory/context
├── workspace-ai/                          # Workspace-level AI customizations (your environment)
│   ├── claude/                            # → mounted to /mnt/workspace/.claude/ (AI: Project Level)
│   │   └── CLAUDE.md                      # Workspace-level memory/context
│   └── gemini/                            # → mounted to /mnt/workspace/.gemini/ (AI: Project Level)
│       └── GEMINI.md                      # Workspace-level memory/context
├── .devcontainer/
│   └── README.md                          # Container setup documentation
└── workspace/                             # Your actual project repositories
    └── your-project/                      # Individual project repository
        ├── .claude/                       # Optional: Repository-specific configs (outside DevPod scope)
        │   └── CLAUDE.md                  # Project-specific memory/context (context-dependent)
        └── .gemini/                       # Optional: Repository-specific configs (outside DevPod scope)
            └── GEMINI.md                  # Project-specific memory/context (context-dependent)
```

## Troubleshooting

### Common Issues

#### Permission Issues
**Symptom**: AI tools cannot access configuration files
**Solution**: 
```bash
# Rebuild container to reset permissions
# Command: "Dev Containers: Rebuild Container"

# Or manually fix npm permissions (handled by npm-fix)
mkdir -p /tmp/npm/.npm-global
sudo chown -R user:user /usr/local /tmp/npm/.npm-global
npm config set prefix /tmp/npm/.npm-global
```

#### Mount Point Issues
**Symptom**: AI configurations not appearing in container
**Solution**:
1. Verify directory structure exists on host:
   ```bash
   ls -la .ai/claude/
   ls -la workspace-ai/claude/
   ```
2. Check devcontainer.json mount configuration
3. Rebuild container if mounts were added/modified

#### Authentication Problems
**Symptom**: AI assistants not authenticated after container rebuild
**Solution**:
- Authentication persists in named volume `devpod-home`
- If issues persist, re-authenticate within the container
- Check if authentication tokens are properly mounted

#### Extension Installation Failures
**Symptom**: AI extensions not installed or not working
**Solution**:
1. Verify extension IDs in devcontainer.json:
   - `anthropic.claude-code`
   - `Google.geminicodeassist`
2. Check postCreateCommand execution logs
3. Manually install if needed: `npm install -g @anthropic-ai/claude-code`

#### Configuration Conflicts
**Symptom**: Unexpected AI behavior due to configuration conflicts
**Solution**:
1. Check configuration precedence within DevPod's two-level system:
   - Workspace level (`/mnt/workspace/.{assistant}/`) - your environment-wide settings
   - System level (`/home/user/.{assistant}/`) - upstream defaults
2. Review configuration files across both DevPod levels
3. Use appropriate level for your customization scope:
   - `workspace-ai/` for environment-wide preferences
   - Repository-level configs (if needed) can be created within individual repos but are outside DevPod's scope

### Debugging Commands

```bash
# Check mount points
mount | grep -E "(claude|gemini)"

# Verify AI CLI installations
which claude
which gemini

# Check VS Code extensions
code --list-extensions | grep -E "(claude|gemini)"

# Test AI tool access across DevPod's two levels
ls -la ~/.claude/                      # System-wide defaults (AI: User Level)
ls -la ~/.gemini/                      # System-wide defaults (AI: User Level)
ls -la /mnt/workspace/.claude/         # Workspace-level configs (AI: Project Level)
ls -la /mnt/workspace/.gemini/         # Workspace-level configs (AI: Project Level)

# Repository-level configs (outside DevPod scope, if they exist)
ls -la /mnt/workspace/your-repo/.claude/   # Project-specific configs (context-dependent)
ls -la /mnt/workspace/your-repo/.gemini/   # Project-specific configs (context-dependent)
```

### Getting Help

1. **DevPod Issues**: Check the main repository issues
2. **Claude Code**: [Anthropic's Claude Code Documentation](https://github.com/anthropics/claude-code)
3. **Gemini Code Assist**: Google's Gemini documentation
4. **DevContainer Issues**: Microsoft's Dev Containers documentation

## Adding New AI Assistants
To add support for additional AI assistants:

1. Create system directory: `.ai/{new-assistant}/`
2. Add mount configuration in devcontainer.json
3. Include VS Code extension in extensions list
4. Add CLI installation in postCreateCommand
5. Document setup in assistant-specific README

This multi-AI workspace system ensures scalable, maintainable AI integration while preserving user customization and enabling seamless collaboration.