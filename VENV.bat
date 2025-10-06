@echo off
REM ============================================================
REM  Crear/usar venv en la carpeta actual y abrir Jupyter Lab
REM  Uso: doble click en este .bat dentro de tu proyecto
REM ============================================================

setlocal enableextensions

REM --- Ir a la carpeta donde está el .bat ---
cd /d "%~dp0"

REM --- Configuración ---
set "ENV_DIR=.venv"
set "KERNEL_NAME=venv-ml-gpu"
set "KERNEL_LABEL=Python (venv-ml-gpu)"

REM --- Verificar Python en PATH ---
where python >nul 2>nul
if errorlevel 1 (
    echo [ERROR] No se encontro 'python' en el PATH.
    echo Instala Python 3.10+ desde python.org y marca "Add Python to PATH".
    pause
    exit /b 1
)

REM --- Verificar si el venv ya existe (python.exe dentro de .venv) ---
if exist "%ENV_DIR%\Scripts\python.exe" (
    echo [INFO] Se detecto entorno existente: %ENV_DIR%
    call "%ENV_DIR%\Scripts\activate"
    if errorlevel 1 (
        echo [ERROR] No se pudo activar el entorno virtual existente.
        pause
        exit /b 1
    )
    echo [INFO] Abriendo Jupyter Lab...
    start "" cmd /c jupyter lab
    exit /b 0
)

REM --- Crear venv (no existia) ---
echo [INFO] Creando entorno virtual en %ENV_DIR% ...
python -m venv "%ENV_DIR%"
if errorlevel 1 (
    echo [ERROR] Fallo al crear el entorno virtual.
    pause
    exit /b 1
)

REM --- Activar venv ---
call "%ENV_DIR%\Scripts\activate"
if errorlevel 1 (
    echo [ERROR] No se pudo activar el entorno virtual recien creado.
    pause
    exit /b 1
)

REM --- Actualizar instaladores base ---
echo [INFO] Actualizando pip/setuptools/wheel...
python -m pip install --upgrade pip setuptools wheel

REM --- Generar requirements.txt basico (ajusta si lo deseas) ---
echo [INFO] Generando requirements.txt ...
(
echo numpy
echo pandas
echo scipy
echo scikit-learn
echo imbalanced-learn
echo matplotlib
echo seaborn
echo joblib
echo tqdm
echo pyarrow
echo openpyxl
echo xlrd
echo xgboost
echo catboost
echo lightgbm
echo jupyter
echo jupyterlab
echo ipykernel
) > requirements.txt

REM --- Instalar librerias ---
echo [INFO] Instalando librerias desde requirements.txt ...
pip install -r requirements.txt
if errorlevel 1 (
    echo [WARN] Hubo errores instalando algunos paquetes. Reintentando paquete por paquete...
    for /f "usebackq delims=" %%L in ("requirements.txt") do (
        echo.
        echo [INFO] Instalando: %%L
        pip install "%%L"
    )
)

REM --- Registrar kernel de Jupyter ---
echo [INFO] Registrando kernel: %KERNEL_NAME%
python -m ipykernel install --user --name "%KERNEL_NAME%" --display-name "%KERNEL_LABEL%"

REM --- Abrir Jupyter Lab ---
echo [INFO] Abriendo Jupyter Lab...
start "" cmd /c jupyter lab

echo [INFO] Listo. Se puede cerrar esta ventana.
exit /b 0
