@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ============================================
::  Cloud Disk — Windows 本地构建 + 打包脚本
::  用法: build-local.bat [选项] [服务器IP]
::
::  在本地 Windows 上构建前端和后端，打包上传到服务器
:: ============================================

title Cloud Disk — 本地构建打包

set "PROJECT_DIR=%~dp0.."
for %%i in ("%PROJECT_DIR%") do set "PROJECT_DIR=%%~fi"

set "FRONTEND_DIR=%PROJECT_DIR%\disk-frontend"
set "BACKEND_DIR=%PROJECT_DIR%\disk-backend\backend"
set "PACKAGE_NAME=deploy-package.zip"
set "PACKAGE_PATH=%PROJECT_DIR%\%PACKAGE_NAME%"
set "BUILD_DIR=%PROJECT_DIR%\deploy-package"

set SERVER_IP=
set SERVER_PATH=/opt/cloud-disk
set SKIP_FRONTEND=0
set SKIP_BACKEND=0
set AUTO_UPLOAD=0

:: ---- 参数解析 ----
:parse_args
if "%~1"=="" goto :start
if "%~1"=="--skip-frontend" (
    set SKIP_FRONTEND=1
    shift
    goto :parse_args
)
if "%~1"=="--skip-backend" (
    set SKIP_BACKEND=1
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
:: 非选项参数 → 服务器 IP
if "%SERVER_IP%"=="" (
    set SERVER_IP=%~1
    set AUTO_UPLOAD=1
)
shift
goto :parse_args

:show_help
echo.
echo 用法: build-local.bat [选项] [服务器IP]
echo.
echo 选项:
echo   --skip-frontend  只构建后端，跳过前端
echo   --skip-backend   只构建前端，跳过后端
echo   -h, --help       显示帮助
echo.
echo 示例:
echo   build-local.bat                    # 本地构建全部
echo   build-local.bat 12.34.56.78       # 构建并自动上传
echo   build-local.bat --skip-backend    # 只构建前端
goto :eof

:start
echo.
echo ╔══════════════════════════════════════════╗
echo ║     Cloud Disk — 本地构建打包            ║
echo ╚══════════════════════════════════════════╝
echo.

:: ---- 清理旧打包目录 ----
if exist "%BUILD_DIR%" rmdir /s /q "%BUILD_DIR%"
if exist "%PACKAGE_PATH%" del /q "%PACKAGE_PATH%"
mkdir "%BUILD_DIR%"

:: ============================================
:: 1. 构建后端
:: ============================================
if %SKIP_BACKEND% EQU 1 goto :skip_backend

echo ── 构建后端 ──
echo.

where java >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [✗] 未检测到 JDK！请安装 JDK 17+
    pause
    exit /b 1
)
where mvn >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [✗] 未检测到 Maven！请安装 Maven
    pause
    exit /b 1
)

for /f "tokens=3" %%a in ('java -version 2^>^&1 ^| findstr /i "version"') do set JAVA_VER=%%a
set JAVA_VER=%JAVA_VER:"=%
echo   [✓] JDK: %JAVA_VER%

for /f "tokens=3" %%a in ('mvn -v 2^>^&1 ^| findstr /i "Apache"') do set MVN_VER=%%a
echo   [✓] Maven: %MVN_VER%

pushd "%BACKEND_DIR%"

echo   正在编译后端 (首次需下载依赖)...
call mvn clean package -DskipTests -q
if %ERRORLEVEL% NEQ 0 (
    echo   [✗] 后端 Maven 构建失败！
    popd
    pause
    exit /b 1
)

set JAR_FILE=
for %%f in (target\*.jar) do (
    echo %%f | findstr /v "sources" >nul
    if !ERRORLEVEL! EQU 0 (
        set JAR_FILE=%CD%\%%f
        goto :jar_found
    )
)
echo   [✗] 未找到 JAR 文件！
popd
pause
exit /b 1

:jar_found
copy "!JAR_FILE!" "%BUILD_DIR%\backend.jar" >nul
echo   [✓] 后端构建完成 → backend.jar

popd

:skip_backend

:: ============================================
:: 2. 构建前端
:: ============================================
if %SKIP_FRONTEND% EQU 1 goto :skip_frontend

echo.
echo ── 构建前端 ──
echo.

where node >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [✗] 未检测到 Node.js！请安装 Node.js 18+
    pause
    exit /b 1
)
where npm >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo   [✗] 未检测到 npm！
    pause
    exit /b 1
)

for /f %%a in ('node -v') do set NODE_VER=%%a
echo   [✓] Node.js: %NODE_VER%
for /f %%a in ('npm -v') do set NPM_VER=%%a
echo   [✓] npm: %NPM_VER%

pushd "%FRONTEND_DIR%"

if not exist "node_modules" (
    echo   正在安装前端依赖...
    call npm install
    if !ERRORLEVEL! NEQ 0 (
        echo   [✗] npm install 失败！
        popd
        pause
        exit /b 1
    )
    echo   [✓] 依赖安装完成
) else (
    echo   [✓] node_modules 已存在，跳过 npm install
)

if exist "dist" rmdir /s /q "dist"

echo   正在构建前端...
set NODE_OPTIONS=--max-old-space-size=2048
call npx vite build
if !ERRORLEVEL! NEQ 0 (
    echo   [✗] 前端构建失败！
    popd
    pause
    exit /b 1
)

if not exist "dist\index.html" (
    echo   [✗] 前端构建失败: 未生成 dist\index.html
    popd
    pause
    exit /b 1
)
echo   [✓] 前端构建完成

mkdir "%BUILD_DIR%\frontend-dist" 2>nul
xcopy /e /y "dist\*" "%BUILD_DIR%\frontend-dist\" >nul
echo   [✓] 前端已复制到打包目录

popd

:skip_frontend

:: ============================================
:: 3. 打包
:: ============================================
echo.
echo ── 打包 ──

pushd "%BUILD_DIR%"
:: Windows 10 1803+ 内置 tar，使用 zip 兼容性更好
powershell -NoProfile -Command ^
    "Compress-Archive -Path '%BUILD_DIR%\*' -DestinationPath '%PACKAGE_PATH%' -Force"
if %ERRORLEVEL% NEQ 0 (
    echo   [✗] 打包失败！
    popd
    pause
    exit /b 1
)
popd

echo   [✓] 已打包: %PACKAGE_PATH%

:: 显示文件大小
for %%f in ("%PACKAGE_PATH%") do set SIZE=%%~zf
set /a SIZE_KB=%SIZE%/1024
echo   文件大小: %SIZE_KB% KB

rmdir /s /q "%BUILD_DIR%"

:: ============================================
:: 4. 上传
:: ============================================
echo.
echo ╔══════════════════════════════════════════╗
echo ║         构建完成！                        ║
echo ╚══════════════════════════════════════════╝
echo.

if %AUTO_UPLOAD% EQU 1 goto :do_upload

echo   ┌──── 上传到服务器 ──────────────────────┐
echo   │                                        │
echo   │  手动上传 (需要 scp):                │
echo   │  scp %PACKAGE_PATH% 你的服务器:%SERVER_PATH%/
echo   │
echo   │  或自动上传 (指定IP):
echo   │  build-local.bat 你的服务器IP
echo   │
echo   │  上传后在服务器解压:
echo   │  cd %SERVER_PATH%                     │
echo   │  tar -xzf deploy-package.tar.gz                     │
echo   │      (若上传的是 zip，用 unzip deploy-package.zip)   │
echo   │
echo   │  然后运行部署:
echo   │  bash deploy/deploy.sh --use-local-build
echo   │                                        │
echo   └────────────────────────────────────────┘
goto :done

:do_upload
echo   正在上传到 %SERVER_IP% ...

:: 确保服务器上有目标目录
ssh %SERVER_IP% "mkdir -p %SERVER_PATH%/deploy-upload"
if %ERRORLEVEL% NEQ 0 (
    echo   [!] 无法连接到服务器，请检查 SSH 配置
    echo.
    echo   手动上传:
    echo   scp %PACKAGE_PATH% 你的服务器:%SERVER_PATH%/
    goto :done
)

:: 上传 zip 包
scp -r "%PACKAGE_PATH%" "%SERVER_IP%:%SERVER_PATH%/deploy-upload/"
if %ERRORLEVEL% NEQ 0 (
    echo   [✗] 上传失败！
    goto :done
)

:: 服务器端解压 (服务器需要 unzip)
ssh %SERVER_IP% "cd %SERVER_PATH%/deploy-upload && unzip -o %PACKAGE_NAME% && rm -f %PACKAGE_NAME%"
if %ERRORLEVEL% NEQ 0 (
    echo   [!] 上传成功但服务器解压失败
    echo   请手动在服务器上执行:
    echo     ssh %SERVER_IP% ^"cd %SERVER_PATH%/deploy-upload ^&^& unzip %PACKAGE_NAME%^"
    goto :done
)
echo   [✓] 已上传并解压到 %SERVER_IP%:%SERVER_PATH%/deploy-upload/

echo.
echo   文件清单:
ssh %SERVER_IP% "find %SERVER_PATH%/deploy-upload/ -type f -printf '%%p (%%s bytes)\\n' 2>/dev/null || ls -lh %SERVER_PATH%/deploy-upload/"
echo.
echo   在服务器上运行:
echo     bash deploy/deploy.sh --use-local-build

:done
echo.
echo   按任意键退出...
pause >nul
