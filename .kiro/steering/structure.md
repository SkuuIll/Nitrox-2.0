# Project Structure

## Solution Organization
The Nitrox solution follows a modular architecture with clear separation of concerns across multiple projects.

## Core Projects

### NitroxModel
**Purpose**: Shared data models and core abstractions  
**Target**: .NET Framework 4.7.2 + .NET 9.0 (multi-targeting)  
**Dependencies**: Core libraries (Autofac, LiteNetLib, Serilog, protobuf-net)  
**Contains**: Data structures, networking models, serialization, game logic abstractions

### NitroxModel-Subnautica
**Purpose**: Subnautica-specific data models and extensions  
**Target**: .NET Framework 4.7.2 + .NET 9.0  
**Dependencies**: NitroxModel  
**Contains**: Game-specific packets, data structures, helper classes

### NitroxClient
**Purpose**: Client-side mod that integrates with Subnautica  
**Target**: .NET Framework 4.7.2 + .NET 9.0  
**Dependencies**: NitroxModel, NitroxModel-Subnautica  
**Contains**: Game logic, communication, debuggers, Unity MonoBehaviours

### NitroxServer
**Purpose**: Core server functionality (game-agnostic)  
**Target**: .NET 9.0 only  
**Dependencies**: NitroxModel  
**Contains**: Server logic, communication, console commands, serialization

### NitroxServer-Subnautica
**Purpose**: Subnautica-specific server implementation  
**Target**: .NET 9.0 only  
**Dependencies**: NitroxServer, NitroxModel-Subnautica  
**Contains**: Game-specific server logic, main program entry point

### NitroxPatcher
**Purpose**: Runtime code modification using Harmony  
**Target**: .NET Framework 4.7.2 + .NET 9.0  
**Dependencies**: NitroxModel  
**Contains**: Harmony patches, pattern matching, transpiler helpers

### Nitrox.Launcher
**Purpose**: Cross-platform desktop application for mod management  
**Target**: .NET 9.0 only  
**Dependencies**: NitroxModel, NitroxServer, Avalonia UI  
**Contains**: MVVM views/viewmodels, launcher logic, UI assets

### Nitrox.Test
**Purpose**: Unit and integration tests  
**Target**: .NET 9.0 only  
**Dependencies**: All other projects  
**Contains**: Test classes, helpers, mocks, test data

## Special Projects

### Nitrox.Assets.Subnautica
**Type**: Shared project (.shproj)  
**Purpose**: Shared assets and resources for Subnautica integration  
**Contains**: Asset bundles, language files, DLLs, resources

### NitroxUnity
**Purpose**: Unity project for asset creation and testing  
**Contains**: Unity-specific assets, project settings, packages

## Folder Conventions

### Standard Project Layout
```
ProjectName/
├── ProjectName.csproj
├── GlobalUsings.cs (if applicable)
├── [Namespace folders following project structure]
├── Properties/ (assembly info, resources)
└── Assets/ (for UI projects)
```

### Common Folder Patterns
- **Communication/**: Network-related classes
- **GameLogic/**: Game-specific business logic  
- **Serialization/**: Data persistence and serialization
- **Helper/**: Utility and extension classes
- **Properties/**: Assembly metadata and resources
- **ViewModels/**: MVVM view models (Launcher)
- **Views/**: UI views and controls (Launcher)

## Build Configuration
- **Directory.Build.props**: Global MSBuild properties and package references
- **Directory.Build.targets**: Custom build targets and tasks
- **Nitrox.Shared.props/targets**: Nitrox-specific build configuration
- **.editorconfig**: Code style and formatting rules

## Dependency Flow
```
Launcher → Server → Model
Client → Model-Subnautica → Model
Patcher → Model
Test → All Projects
Assets.Subnautica → (Shared across projects)
```

## Naming Conventions
- **Projects**: PascalCase with "Nitrox" prefix
- **Namespaces**: Match folder structure, PascalCase
- **Files**: PascalCase for classes, camelCase for private fields
- **Constants**: ALL_UPPER_CASE with underscores