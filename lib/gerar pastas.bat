@echo off
chcp 65001 >nul
echo.
echo ═══════════════════════════════════════════════
echo   Criando estrutura do projeto skills_arena
echo ═══════════════════════════════════════════════
echo.

set ROOT=H:\Linguagens\Flutter\Projetos working\skills_arena\lib

REM ── Core ──────────────────────────────────────────
mkdir "%ROOT%\core\constants" 2>nul
mkdir "%ROOT%\core\errors" 2>nul
mkdir "%ROOT%\core\theme" 2>nul
mkdir "%ROOT%\core\utils" 2>nul

REM ── Data ──────────────────────────────────────────
mkdir "%ROOT%\data\models" 2>nul
mkdir "%ROOT%\data\repositories" 2>nul
mkdir "%ROOT%\data\datasources" 2>nul

REM ── Domain ────────────────────────────────────────
mkdir "%ROOT%\domain\entities" 2>nul
mkdir "%ROOT%\domain\repositories" 2>nul
mkdir "%ROOT%\domain\usecases" 2>nul

REM ── Services ──────────────────────────────────────
mkdir "%ROOT%\services" 2>nul

REM ── Config ────────────────────────────────────────
mkdir "%ROOT%\config" 2>nul

REM ── Presentation ──────────────────────────────────
mkdir "%ROOT%\presentation\providers" 2>nul
mkdir "%ROOT%\presentation\widgets\auth" 2>nul
mkdir "%ROOT%\presentation\widgets\common" 2>nul
mkdir "%ROOT%\presentation\screens\auth" 2>nul
mkdir "%ROOT%\presentation\screens\shell" 2>nul
mkdir "%ROOT%\presentation\screens\home" 2>nul
mkdir "%ROOT%\presentation\screens\explore" 2>nul
mkdir "%ROOT%\presentation\screens\chat" 2>nul
mkdir "%ROOT%\presentation\screens\profile" 2>nul

REM ── Assets ────────────────────────────────────────
mkdir "H:\Linguagens\Flutter\Projetos working\skills_arena\assets\images" 2>nul
mkdir "H:\Linguagens\Flutter\Projetos working\skills_arena\assets\icons" 2>nul
mkdir "H:\Linguagens\Flutter\Projetos working\skills_arena\assets\fonts" 2>nul

echo [OK] Pastas criadas!
echo.

REM ══════════════════════════════════════════════════
REM  Criando arquivos vazios
REM ══════════════════════════════════════════════════

REM ── Core ──────────────────────────────────────────
type nul > "%ROOT%\core\constants\app_constants.dart"
type nul > "%ROOT%\core\errors\app_failure.dart"
type nul > "%ROOT%\core\theme\app_theme.dart"

REM ── Data ──────────────────────────────────────────
type nul > "%ROOT%\data\models\user_model.dart"
type nul > "%ROOT%\data\repositories\auth_repository.dart"

REM ── Services ──────────────────────────────────────
type nul > "%ROOT%\services\storage_service.dart"

REM ── Config ────────────────────────────────────────
type nul > "%ROOT%\config\firebase_options.dart"

REM ── Providers ─────────────────────────────────────
type nul > "%ROOT%\presentation\providers\router_provider.dart"

REM ── Widgets ───────────────────────────────────────
type nul > "%ROOT%\presentation\widgets\auth\google_sign_in_button.dart"

REM ── Screens Auth ──────────────────────────────────
type nul > "%ROOT%\presentation\screens\auth\login_screen.dart"
type nul > "%ROOT%\presentation\screens\auth\register_screen.dart"
type nul > "%ROOT%\presentation\screens\auth\forgot_password_screen.dart"

REM ── Shell (NavigationBar) ─────────────────────────
type nul > "%ROOT%\presentation\screens\shell\main_shell.dart"

REM ── Screens principais ────────────────────────────
type nul > "%ROOT%\presentation\screens\home\home_screen.dart"
type nul > "%ROOT%\presentation\screens\explore\explore_screen.dart"
type nul > "%ROOT%\presentation\screens\chat\chat_screen.dart"
type nul > "%ROOT%\presentation\screens\profile\profile_screen.dart"

echo [OK] Arquivos criados!
echo.
echo ═══════════════════════════════════════════════
echo   Estrutura pronta! Cole o código em cada um.
echo ═══════════════════════════════════════════════
echo.

REM Abre o Explorer na pasta lib para facilitar
explorer "%ROOT%"

pause