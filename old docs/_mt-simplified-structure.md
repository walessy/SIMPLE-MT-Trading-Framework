# MT Trading Framework - Directory Structure

After running the setup script, your framework will have the following structure:

```
MTFramework/                       # Base directory
├── MTSetup.ps1                    # Main setup script
├── README.md                      # Main documentation
├── QUICKSTART.md                  # Getting started guide
├── .gitignore                     # Git ignore file
├── Dockerfile                     # Docker configuration
├── docker-compose.yml             # Docker Compose configuration
├── build.bat                      # Main build script
|
├── scripts/                       # Build scripts
│   ├── build_mt4.sh               # MT4 build script
│   └── build_mt5.sh               # MT5 build script
|
├── BrokerPackages/                # Broker installer files
│   └── *.exe                      # Downloaded broker installers
|
├── MT4/                           # MT4 installations
│   └── AfterPrime/                # Example broker installation
│       ├── terminal.exe           # MT4 terminal executable
│       └── ...                    # Other MT4 files
|
├── MT5/                           # MT5 installations
│   └── AfterPrime/                # Example broker installation
│       ├── terminal64.exe         # MT5 terminal executable
│       └── ...                    # Other MT5 files
|
├── src/                           # Global source code
│   ├── strategies/                # Trading strategies
│   │   ├── SampleStrategy.mq4     # Sample MT4 strategy
│   │   └── SampleStrategy.mq5     # Sample MT5 strategy
│   ├── include/                   # Include files
│   │   └── Utils.mqh              # Utility include file
│   └── indicators/                # Custom indicators
|
├── build/                         # Global build outputs
│   ├── mt4/                       # MT4 compiled files
│   │   ├── *.ex4                  # Compiled MT4 strategies
│   │   └── include/               # Copied include files
│   └── mt5/                       # MT5 compiled files
│       ├── *.ex5                  # Compiled MT5 strategies
│       └── include/               # Copied include files
|
└── Dev/                           # Development environments
    └── MyStrategy/                # Example dev environment
        ├── build.bat              # Environment-specific build script
        ├── config.json            # Environment configuration
        ├── src/                   # Environment source code
        │   ├── strategies/        # Trading strategies
        │   │   ├── SampleStrategy.mq4
        │   │   └── SampleStrategy.mq5
        │   ├── indicators/        # Custom indicators
        │   ├── include/           # Include files
        │   │   └── Utils.mqh
        │   ├── libraries/         # MQL libraries
        │   └── tests/             # Tests
        └── build/                 # Environment build output
            ├── mt4/               # MT4 compiled files
            └── mt5/               # MT5 compiled files
```

## Key Components

1. **Base Files:** Setup script, documentation, Docker configuration
2. **Scripts:** Build scripts for MT4 and MT5
3. **Broker Installations:** MT4 and MT5 terminals
4. **Source Code:** Global strategies, indicators, and include files
5. **Build Outputs:** Compiled MT4 and MT5 files
6. **Development Environments:** Isolated environments for different projects