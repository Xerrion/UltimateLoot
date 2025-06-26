# UltimateLoot Copilot Instructions
This document provides guidelines and standards for contributing to the UltimateLoot addon project. It covers code generation

## AI Development Rules and Guidelines

### Code Generation Standards

1. **WoW 3.3.5a Compatibility**: Only suggest APIs and features available in Wrath of the Lich King
2. **Ace3 Framework Usage**: Utilize AceAddon-3.0, AceGUI-3.0, AceDB-3.0, and other Ace3 libraries
3. **Engine Pattern**: Always access shared functionality through the `E` (Engine) singleton
4. **Modular Architecture**: Create self-contained modules that register with the Engine
5. **Event-Driven Design**: Use the custom event system for inter-module communication

### Commit Message Standards

Follow conventional commits format:
- `feat(scope): description` - New features
- `fix(scope): description` - Bug fixes  
- `chore(scope): description` - Maintenance
- `style(scope): description` - UI improvements
- `refactor(scope): description` - Code restructuring
- `docs(scope): description` - Documentation updates

### File Modification Rules

1. **Read Before Edit**: Always examine current file contents before making changes
2. **Preserve Formatting**: Maintain existing indentation and spacing patterns
3. **Contextual Changes**: Provide sufficient context when replacing code sections
4. **Incremental Updates**: Make small, focused changes rather than large rewrites
5. **Validation**: Check for syntax errors and logical consistency after edits

### Localization Requirements

1. **Mandatory L10n**: All user-visible text must use localization keys
2. **Dual Language Support**: Add entries to both `enUS.lua` and `deDE.lua`
3. **Key Naming**: Use descriptive UPPERCASE_UNDERSCORE format
4. **Fallback Handling**: Provide fallback text using `L["KEY"] or "Default text"`
5. **Logical Grouping**: Organize related strings with descriptive comments

### UI Development Guidelines

1. **AceGUI Widgets**: Use AceGUI-3.0 components for all interface elements
2. **Error Resilience**: Wrap UI operations in pcall for graceful error handling
3. **Responsive Design**: Use relative sizing and proper layout managers
4. **State Persistence**: Maintain window positions and user preferences
5. **User Experience**: Provide clear feedback and intuitive interactions

### Module Development Patterns

1. **Registration**: Use `E:NewModule("ModuleName")` for new modules
2. **Lifecycle Methods**: Implement OnInitialize, OnEnable, OnDisable as needed
3. **Event Handling**: Register for appropriate WoW and custom events
4. **Data Management**: Use AceDB-3.0 through the profile system
5. **Clean Architecture**: Separate concerns and minimize coupling

### Testing and Quality Assurance

1. **Functional Testing**: Verify all features work in-game before committing
2. **Debug Integration**: Use `E:DebugPrint()` for development logging
3. **Edge Case Handling**: Test with various configurations and inputs
4. **Performance Monitoring**: Avoid expensive operations in event handlers
5. **Memory Management**: Clean up resources properly

### Git Workflow Integration

1. **Branch Strategy**: Create feature branches from `main` for all development
2. **Pull Request Process**: All changes must go through PR review
3. **Release Management**: Use `release/vX.Y.Z` branches for version preparation
4. **Version Consistency**: Update `UltimateLoot.toc` version for releases
5. **Change Documentation**: Maintain detailed CHANGELOG.md entries

### Error Handling Standards

1. **Defensive Programming**: Validate inputs and handle edge cases
2. **Graceful Degradation**: Continue functioning when non-critical components fail
3. **User Communication**: Provide clear, actionable error messages
4. **Debug Information**: Log sufficient detail for troubleshooting
5. **Recovery Mechanisms**: Implement fallbacks for critical functionality

### Performance Optimization

1. **Efficient Algorithms**: Choose appropriate data structures and algorithms
2. **Memory Conservation**: Minimize allocations in frequently called code
3. **Caching Strategy**: Cache expensive computations when beneficial
4. **Event Efficiency**: Minimize processing in high-frequency event handlers
5. **Resource Cleanup**: Properly dispose of timers, events, and UI elements

### Code Documentation

1. **Function Documentation**: Document all public interfaces with parameter descriptions
2. **Algorithm Explanation**: Comment complex logic and calculations
3. **Configuration Documentation**: Explain settings and their effects
4. **Usage Examples**: Provide clear examples for new features
5. **Architecture Notes**: Document design decisions and patterns
