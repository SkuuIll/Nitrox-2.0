# Technology Stack

## Build System
- **MSBuild** with custom Directory.Build.props and targets
- **Visual Studio 2022** (minimum version 17.0)
- **.NET Multi-targeting**: .NET Framework 4.7.2 and .NET 9.0
- **C# 13** language features enabled

## Core Technologies
- **C#** - Primary programming language
- **Unity Engine** - Game engine integration (Subnautica uses Unity)
- **Harmony** - Runtime code patching and modification
- **Autofac** - Dependency injection container
- **LiteNetLib** - Networking library for client-server communication
- **protobuf-net** - Binary serialization
- **Serilog** - Structured logging

## UI Framework
- **Avalonia UI** - Cross-platform desktop application framework (Launcher)
- **MVVM Pattern** - Using CommunityToolkit.Mvvm

## Testing
- **MSTest** - Unit testing framework
- **FluentAssertions** - Assertion library
- **NSubstitute** - Mocking framework
- **Bogus** - Test data generation

## Key Dependencies
- **BepInEx** - Unity modding framework
- **Newtonsoft.Json** - JSON serialization
- **Mono.Nat** - NAT traversal for networking
- **DiscordGameSDK** - Discord integration

## Common Commands

### Building
```bash
# Build entire solution
dotnet build Nitrox.sln

# Build specific project
dotnet build NitroxServer/NitroxServer.csproj

# Build for release
dotnet build -c Release
```

### Testing
```bash
# Run all tests
dotnet test Nitrox.Test/Nitrox.Test.csproj

# Run tests with coverage
dotnet test --collect:"XPlat Code Coverage"
```

### Development
```bash
# Restore packages
dotnet restore

# Clean build artifacts
dotnet clean
```

## Project Configuration
- **AllowUnsafeBlocks**: Enabled for performance-critical code
- **Nullable**: Annotations enabled for better null safety
- **ImplicitUsings**: Disabled - explicit using statements required
- **LangVersion**: C# 13
- **DebugType**: Embedded for better debugging experience