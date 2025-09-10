# Copilot Instructions for ForceInputs SourceMod Plugin

## Repository Overview

This repository contains the **ForceInputs** SourceMod plugin, which provides administrators with the ability to force inputs on entities in Source engine games. The plugin essentially provides `ent_fire` functionality through admin commands.

### Key Features
- `sm_forceinput` - Force inputs on entities by classname/targetname/HammerID
- `sm_forceinputplayer` - Force inputs on player entities
- Support for special targets (`!self`, `!target`, HammerID with `#`)
- Wildcard matching for entity names
- Comprehensive logging and error handling

## Technical Environment

- **Language**: SourcePawn
- **Platform**: SourceMod 1.11.0+ (targeting 1.12+ for future compatibility)
- **Build System**: SourceKnight 0.2
- **Compiler**: SourcePawn Compiler (spcomp) via SourceKnight
- **CI/CD**: GitHub Actions with `maxime1907/action-sourceknight@v1`

## Project Structure

```
addons/sourcemod/scripting/
└── ForceInputs.sp          # Main plugin source file

.github/workflows/
└── ci.yml                  # CI/CD pipeline

sourceknight.yaml           # Build configuration
```

## Development Setup

### Prerequisites
1. **SourceKnight**: Install via `pip install sourceknight`
2. **SourceMod Dependencies**: Automatically downloaded by SourceKnight (v1.11.0-git6934)

### Local Development
```bash
# Build the plugin
sourceknight build

# Output will be in: addons/sourcemod/plugins/ForceInputs.smx
```

### Build Configuration
The `sourceknight.yaml` defines:
- Project name: ForceInputs
- SourceMod dependency version: 1.11.0-git6934
- Output directory: `/addons/sourcemod/plugins`
- Build target: ForceInputs

## Code Style & Standards

### SourcePawn Specific
- **Pragmas**: Always include `#pragma semicolon 1` and `#pragma newdecls required`
- **Indentation**: Use tabs (4 spaces equivalent)
- **Naming Conventions**:
  - Functions: PascalCase (`Command_ForceInput`)
  - Local variables: camelCase (`sArguments`, `TargetCount`)
  - Global variables: Prefix with `g_` (not used in this plugin)
  - Constants: UPPER_CASE (`MAXPLAYERS`)

### Code Quality
- **Error Handling**: Check all API return values
- **Memory Management**: Use `CloseHandle()` for traces and handles
- **Logging**: Use `LogAction()` for admin actions
- **Translations**: Load with `LoadTranslations()` in `OnPluginStart()`
- **Input Validation**: Validate all command arguments and entity references

## Plugin Architecture

### Entry Points
- `OnPluginStart()` - Initialize plugin, register commands, load translations
- `OnPluginEnd()` - Cleanup (if needed, currently not implemented)

### Commands
1. **sm_forceinput** (`ADMFLAG_ROOT`)
   - Usage: `sm_forceinput <classname/targetname> <input> [parameter]`
   - Special targets: `!self`, `!target`, `#<HammerID>`
   - Supports wildcard matching with `*`

2. **sm_forceinputplayer** (`ADMFLAG_ROOT`)
   - Usage: `sm_forceinputplayer <target> <input> [parameter]`
   - Uses SourceMod target processing

### Security Considerations
- Both commands require `ADMFLAG_ROOT` permission
- Console safety checks for `!self` and `!target` arguments
- Entity validation before input execution
- Comprehensive logging of all actions

## Common Development Tasks

### Adding New Commands
1. Register in `OnPluginStart()` with `RegAdminCmd()`
2. Implement command handler with proper argument validation
3. Add logging with `LogAction()`
4. Update plugin version in `myinfo` structure

### Modifying Entity Logic
- Always validate entities with `IsValidEntity()`
- Use `AcceptEntityInput()` for entity manipulation
- Set parameters with `SetVariantString()` before input execution
- Handle special entity references (`!self`, `!target`, HammerID)

### Error Handling Patterns
```sourcepawn
// Command argument validation
if(GetCmdArgs() < 2)
{
    ReplyToCommand(client, "[SM] Usage: ...");
    return Plugin_Handled;
}

// Entity validation
if(!IsValidEntity(entity))
    continue; // or return Plugin_Handled

// Handle cleanup
CloseHandle(hTrace);
```

## Testing & Validation

### Build Testing
```bash
# Local build test
sourceknight build

# Check for compilation errors
# Output should be: addons/sourcemod/plugins/ForceInputs.smx
```

### Manual Testing Checklist
1. **Command Registration**: Verify commands appear in `sm help`
2. **Permission Check**: Test with non-admin users
3. **Entity Targeting**: Test all target types (`!self`, `!target`, classname, targetname, HammerID)
4. **Parameter Handling**: Test with and without optional parameters
5. **Console Safety**: Test `!self` and `!target` from server console
6. **Logging**: Verify actions are logged properly

### CI/CD Pipeline
The GitHub Actions workflow:
1. Builds the plugin using SourceKnight
2. Creates release packages on version tags
3. Uploads artifacts for download

## Version Management

- **Current Version**: 2.1.3 (in plugin info)
- **Versioning**: Semantic versioning (MAJOR.MINOR.PATCH)
- **Release Process**: 
  1. Update version in `myinfo` structure
  2. Commit changes
  3. Create git tag
  4. CI automatically creates release

## Troubleshooting

### Common Issues
1. **Build Failures**: Ensure SourceKnight is properly installed
2. **Entity Not Found**: Verify entity exists and is valid
3. **Permission Denied**: Check admin flags and command permissions
4. **Console Restrictions**: Remember `!self` and `!target` don't work from console

### Debug Techniques
- Use `ReplyToCommand()` for user feedback
- Check entity properties with `GetEntPropString()`
- Validate entity indices and references
- Use trace rays for `!target` functionality

## Performance Considerations

- **Entity Enumeration**: `FindEntityByClassname()` loops can be expensive
- **String Comparisons**: Cache classnames and targetnames when possible
- **Trace Rays**: Used only when necessary (`!target` command)
- **Memory Management**: Always close handles and traces

## Security & Safety

- **Admin Only**: Both commands require root admin privileges
- **Entity Validation**: All entity references are validated
- **Console Protection**: Special arguments blocked from console
- **Input Sanitization**: All user inputs are properly handled
- **Audit Logging**: All actions are logged with full context

## Dependencies

- **SourceMod Include**: `#include <sourcemod>` (core functionality)
- **SDK Tools**: `#include <sdktools>` (entity manipulation, traces)
- **Translations**: `common.phrases` (standard SourceMod phrases)

## Best Practices for Modifications

1. **Minimal Changes**: Make surgical modifications to existing functionality
2. **Testing**: Always test changes on a development server
3. **Compatibility**: Maintain compatibility with SourceMod 1.11+
4. **Documentation**: Update comments for complex logic changes
5. **Error Handling**: Add proper error checking for new code paths
6. **Performance**: Consider impact on server performance
7. **Security**: Maintain admin permission requirements

## File Locations

- **Source Code**: `addons/sourcemod/scripting/ForceInputs.sp`
- **Compiled Plugin**: `addons/sourcemod/plugins/ForceInputs.smx` (after build)
- **Build Config**: `sourceknight.yaml`
- **CI Configuration**: `.github/workflows/ci.yml`

This plugin follows SourceMod best practices and provides a solid foundation for entity manipulation functionality in Source engine games.