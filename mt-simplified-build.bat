@echo off
echo Building MQL files with Docker...
cd %~dp0
docker compose build
docker compose run --rm mt_builder bash -c "build_mt4 && build_mt5"
echo Build complete!
pause