# MT Trading Framework - Folder Structure Rationale

This document explains the purpose and rationale behind each folder in the MT Trading Framework structure.

## Top-Level Directories

### `MTFramework/` (Base Directory)
**Purpose**: Serves as the container for the entire framework.  
**Rationale**: Creates a dedicated, isolated space for all trading-related activities, separate from other projects and systems.

### `BrokerPackages/`
**Purpose**: Stores broker-specific installer files.  
**Rationale**: Centralizes and preserves installation files, eliminating the need to re-download them for future installations or reinstallations. This improves reliability and speeds up setup when working offline.

### `MT4/`
**Purpose**: Contains all MetaTrader 4 terminal installations.  
**Rationale**: Isolates production MT4 installations in a dedicated location, making it easy to find and manage them. Separating MT4 from MT5 prevents confusion between platform versions.

### `MT5/`
**Purpose**: Contains all MetaTrader 5 terminal installations.  
**Rationale**: Isolates production MT5 installations, similar to the MT4 directory. The separation reflects the significant differences between MT4 and MT5 in terms of architecture and capabilities.

### `Dev/`
**Purpose**: Contains isolated development environments.  
**Rationale**: Enables the development of multiple strategies in complete isolation, preventing cross-contamination of code and dependencies. Each subfolder represents a separate project or strategy with its own complete environment.

### `Test/`
**Purpose**: Contains dedicated testing environments.  
**Rationale**: Provides controlled environments for testing that are separate from both development and production. This allows for rigorous testing with specific conditions without affecting live trading or ongoing development.

### `src/` (Global)
**Purpose**: Contains global source code shared across projects.  
**Rationale**: Centralizes common code components used by multiple strategies, promoting code reuse and consistency. This reduces duplication and makes it easier to maintain core functionality.

### `build/` (Global)
**Purpose**: Contains compiled files ready for deployment.  
**Rationale**: Provides a central location for all production-ready code, simplifying deployment processes. The separation from development builds ensures only verified, tested code reaches this directory.

### `scripts/`
**Purpose**: Contains automation scripts for building and deployment.  
**Rationale**: Centralizes operational tools that manage the framework itself, keeping them separate from trading code. This separation of concerns improves maintainability.

## Development Environment Subdirectories

### `Dev/MyStrategy/`
**Purpose**: An isolated environment for a specific trading strategy.  
**Rationale**: Complete isolation ensures that each strategy can be developed, tested, and maintained independently, with its own dependencies and configuration.

### `Dev/MyStrategy/src/`
**Purpose**: Contains source code for this specific strategy.  
**Rationale**: Keeps all source files organized in one location, making the development process more coherent and structured.

### `Dev/MyStrategy/src/strategies/`
**Purpose**: Contains the main strategy expert advisors.  
**Rationale**: Separates the core trading logic from supporting elements like indicators and libraries, creating a clear hierarchy of components.

### `Dev/MyStrategy/src/indicators/`
**Purpose**: Contains custom indicators specific to this strategy.  
**Rationale**: Organizes technical analysis tools separately from trading logic, reflecting their different purposes and making them easier to maintain.

### `Dev/MyStrategy/src/include/`
**Purpose**: Contains include files and headers.  
**Rationale**: Centralizes common definitions, constants, and utilities, promoting code reuse within the strategy while keeping the code modular.

### `Dev/MyStrategy/src/libraries/`
**Purpose**: Contains reusable code libraries.  
**Rationale**: Isolates more complex, reusable functionality that might be shared across multiple strategy components, improving maintainability.

### `Dev/MyStrategy/src/scripts/`
**Purpose**: Contains utility scripts for this strategy.  
**Rationale**: Keeps auxiliary tools separate from the main trading logic, reflecting their different uses (often for one-time operations rather than continuous trading).

### `Dev/MyStrategy/src/tests/`
**Purpose**: Contains testing code specific to this strategy.  
**Rationale**: Keeps tests close to the code they verify while still maintaining separation, encouraging thorough testing while preserving a clean structure.

### `Dev/MyStrategy/build/`
**Purpose**: Contains compiled files for this strategy.  
**Rationale**: Separates source code from compiled artifacts, preventing potential confusion and making it clear which files should be edited vs. which are generated.

### `Dev/MyStrategy/build/mt4/`
**Purpose**: Contains MT4-specific compiled files.  
**Rationale**: Separates MT4 builds from MT5 builds, reflecting their different formats and preventing any potential conflicts or confusion.

### `Dev/MyStrategy/build/mt5/`
**Purpose**: Contains MT5-specific compiled files.  
**Rationale**: Same rationale as for the MT4 build directory - keeps platform-specific compiled files separate.

## Production Directories

### `MT4/BrokerName/`
**Purpose**: Contains a specific broker's MT4 terminal.  
**Rationale**: Separates different brokers' terminals to accommodate variations in server connections, symbols, and other broker-specific settings.

### `MT4/BrokerName/MQL4/Experts/`
**Purpose**: Contains production-ready expert advisors for MT4.  
**Rationale**: This is MT4's standard location for compiled strategies, enabling direct deployment and execution from the platform.

### `MT5/BrokerName/MQL5/Experts/`
**Purpose**: Contains production-ready expert advisors for MT5.  
**Rationale**: This is MT5's standard location for compiled strategies, enabling direct deployment and execution from the platform.

## Build Output Directories

### `build/mt4/`
**Purpose**: Contains globally available MT4 compiled files.  
**Rationale**: Centralizes all production-ready MT4 code, making it easy to deploy across multiple terminals or share with others.

### `build/mt5/`
**Purpose**: Contains globally available MT5 compiled files.  
**Rationale**: Centralizes all production-ready MT5 code, similar to the MT4 build directory.

## Special Considerations

### Redundancy vs. Isolation

There is an intentional level of redundancy in the directory structure, particularly between development environments and the global directories. This redundancy is by design:

1. **Isolation**: Each development environment is completely self-contained, allowing different strategies to evolve independently without interference.

2. **Versioning**: The structure supports maintaining different versions of common components across different strategies when needed.

3. **Coordination**: The synchronization mechanism provides a way to keep files in sync when appropriate, without forcing unnecessary coupling.

### MetaTrader Structure Integration

The framework respects MetaTrader's native directory structure while providing additional organization:

1. **Native Compatibility**: The framework maintains compatibility with MetaTrader's expected file locations.

2. **Enhanced Organization**: The framework adds additional structure for better development practices.

3. **Bridged Gap**: The synchronization system connects the framework's enhanced structure with MetaTrader's requirements.

This design creates a balanced approach that leverages the strengths of both the MetaTrader platform and modern development practices.
