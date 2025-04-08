# Docker's Role in the MetaTrader Trading Framework

## Overview

Docker is not used to create the test environment itself. Instead, Docker serves as a build environment for compiling MQL4/MQL5 code in both development and test environments.

## How It Works

### Environment Creation
- Both development and test environments are created as separate directory structures on your local system
- The test environment is a regular folder structure parallel to your development environment, not a Docker container
- Both environments maintain their own source code, build outputs, and configuration files

### Docker's Role
Docker provides a consistent compilation environment for your MQL4/MQL5 code, with the following components:
- Wine (to run Windows MetaEditor on Linux)
- MetaEditor for both MT4 and MT5
- Build scripts that can compile your trading strategies

### Compilation Process
When you run the build script for either environment:
1. Docker spins up a container with the compilation tools
2. It mounts your local directory structure into the container
3. It runs the appropriate build scripts to compile your code
4. The compiled files (.ex4/.ex5) are saved back to your local filesystem

## Development vs. Test Environments

The key difference between development and test environments is that they are separate directories with separate configurations, not that one uses Docker and the other doesn't. Both can use Docker for compilation if advanced mode is selected.

## Basic Mode vs. Advanced Mode

- **Advanced Mode**: Uses Docker for compilation in both development and test environments
- **Basic Mode**: Docker isn't used at all - instead, the scripts copy your MQL files to the MetaTrader installation directories where you compile them manually using MetaTrader's built-in tools

## Summary

Docker serves as a compilation tool used by both environments, not a technology used to create or isolate the test environment itself. It provides a consistent, cross-platform build environment that doesn't require installing MetaEditor directly on your development machine.
