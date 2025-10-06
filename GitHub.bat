@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

REM ============================================================
REM Publicar carpeta actual a PSIMAFG/Entrega_ML_Corregida (GitHub)
REM - Omite (ignora) el archivo: Untitled.ipynb
REM - Hace commit/push a main
REM - Oculta este y todos los .bat de la carpeta
REM ============================================================

cd /d "%~dp0"

set "REPO_URL=https://github.com/PSIMAFG/Entrega_ML_Corregida.git"
set "IGNORE_THIS=Untitled.ipynb"

REM --- 1) Verificar Git instalado ---
where git >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Git no esta instalado o no esta en PATH.
  echo Descarga: https://git-scm.com/download/win
  goto :END
)

REM --- 2) Inicializar repo si es necesario y crear/forzar rama main ---
git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  REM Git nuevo soporta -b; si falla, hace init y luego crea main
  git init -b main >nul 2>&1
  if errorlevel 1 (
    git init || (echo [ERROR] No se pudo inicializar el repositorio. & goto :END)
    git checkout -b main || (echo [ERROR] No se pudo crear la rama main. & goto :END)
  )
) else (
  REM Si ya es repo, aseguramos estar en main
  git rev-parse --abbrev-ref HEAD | findstr /i "^main$" >nul || git checkout -B main
)

REM --- 3) Configuracion basica de usuario si falta ---
for /f "usebackq delims=" %%A in (`git config --get user.name 2^>nul`) do set "GUN=%%A"
for /f "usebackq delims=" %%A in (`git config --get user.email 2^>nul`) do set "GEM=%%A"
if "%GUN%"=="" (
  set /p GUN="git user.name (para los commits): "
  if not "%GUN%"=="" git config user.name "%GUN%"
)
if "%GEM%"=="" (
  set /p GEM="git user.email (para los commits): "
  if not "%GEM%"=="" git config user.email "%GEM%"
)

REM --- 4) Asegurar .gitignore con Untitled.ipynb ---
if not exist ".gitignore" (
  echo %IGNORE_THIS%>.gitignore
) else (
  findstr /x /c:"%IGNORE_THIS%" ".gitignore" >nul 2>&1
  if errorlevel 1 (
    echo %IGNORE_THIS%>>.gitignore
  )
)

REM Si ya estaba trackeado, quitarlo del index (mantener el archivo en disco)
git rm --cached --ignore-unmatch "%IGNORE_THIS%" >nul 2>&1

REM --- 5) Configurar remoto origin al repo dado ---
git remote | findstr /i "^origin$" >nul
if errorlevel 1 (
  git remote add origin "%REPO_URL%" || (echo [ERROR] No se pudo agregar el remoto origin. & goto :END)
) else (
  git remote set-url origin "%REPO_URL%" || (echo [ERROR] No se pudo actualizar la URL del remoto origin. & goto :END)
)

REM --- 6) Agregar y commitear cambios (si los hay) ---
git add -A
for /f %%C in ('git status --porcelain ^| find /c /v ""') do set "CHANGES=%%C"
if "%CHANGES%"=="0" (
  echo [INFO] No hay cambios nuevos que commitear.
) else (
  git commit -m "Sync: publicar carpeta (ignorar Untitled.ipynb)" || (echo [ERROR] No se pudo crear el commit. & goto :HIDE_BATS)
)

REM --- 7) Push a main (manejo simple de conflictos) ---
git push -u origin main
if errorlevel 1 (
  echo [ADVERTENCIA] Push fallo. Intentando 'git pull --rebase origin main'...
  git pull --rebase origin main
  if errorlevel 1 (
    echo [ERROR] No se pudo rebasar contra origin/main. Resuelve conflictos y vuelve a ejecutar este .bat.
    goto :HIDE_BATS
  )
  git push -u origin main || (echo [ERROR] El push aun fallo. Revisa permisos/estado del repo. & goto :HIDE_BATS)
)

echo.
echo ✅ Publicado correctamente en: %REPO_URL%
echo (El archivo "%IGNORE_THIS%" queda omitido mediante .gitignore)
echo.

:HIDE_BATS
REM --- 8) Ocultar todos los .bat de la carpeta (incluye este) ---
attrib +h "*.bat" >nul 2>&1
echo [INFO] Archivos .bat ocultados en esta carpeta.

:END
echo.
endlocal
