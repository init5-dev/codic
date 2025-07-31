#!/bin/bash

# ==============================================================================
# Arnés de Pruebas Automatizado para 'codic'
#
# Este script crea un entorno de prueba, ejecuta una batería de tests
# cubriendo todos los argumentos y combinaciones, y reporta los resultados.
# Se limpia automáticamente al finalizar.
# ==============================================================================

# --- Configuración de Seguridad y Robustez ---
set -eo pipefail

# --- Configuración General ---
TEST_DIR="codic_test_project"
EXECUTABLE="codic"
OUTPUT_FILE="test_output.txt"

# --- Colores para la Salida ---
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_BLUE='\033[0;34m'
C_NC='\033[0m'

# --- Contadores de Pruebas ---
PASS_COUNT=0
FAIL_COUNT=0
TOTAL_TESTS=0

# ==============================================================================
# --- Funciones Auxiliares ---
# ==============================================================================

setup() {
    echo -e "${C_BLUE}--- CONFIGURANDO ENTORNO DE PRUEBAS ---${C_NC}"
    cleanup
    mkdir -p "$TEST_DIR"/{src,docs,.git,node_modules/lib,empty_dir}
    echo "main python file" > "$TEST_DIR/main.py"
    echo "readme file" > "$TEST_DIR/README.md"
    echo "javascript component" > "$TEST_DIR/src/component.jsx"
    echo "python utility" > "$TEST_DIR/src/utils.py"
    echo "documentation guide" > "$TEST_DIR/docs/guide.md"
    echo "secret config" > "$TEST_DIR/config.json"
    echo "git config" > "$TEST_DIR/.git/config"
    echo "lock file" > "$TEST_DIR/package-lock.json"
    echo "typescript config" > "$TEST_DIR/tsconfig.json"
    echo "typescript build config" > "$TEST_DIR/tsconfig.build.json"
    echo "library code" > "$TEST_DIR/node_modules/lib/index.js"
    echo -e "${C_GREEN}Entorno creado en './$TEST_DIR'.${C_NC}\n"
}

cleanup() {
    rm -rf "$TEST_DIR"
    rm -f "$OUTPUT_FILE"
}

trap cleanup EXIT

run_test() {
    local description="$1"
    local command="$2"
    local check_type="$3"
    local check_arg="$4"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "${C_YELLOW}TEST ${TOTAL_TESTS}: ${description}${C_NC}"

    local output=""
    local exit_code=0
    
    output=$(eval "$command" 2>&1) || exit_code=$?
    
    local pass=false
    local fail_reason=""

    case "$check_type" in
        contains)
            if [[ "$output" == *"$check_arg"* ]]; then pass=true; fi
            fail_reason="La salida no contenía el texto esperado: '$check_arg'"
            ;;
        not_contains)
            if [[ "$output" != *"$check_arg"* ]]; then pass=true; fi
            fail_reason="La salida contenía un texto no esperado: '$check_arg'"
            ;;
        succeeds)
            if [[ $exit_code -eq 0 ]]; then pass=true; fi
            fail_reason="El comando falló (código de salida: $exit_code) pero se esperaba que tuviera éxito."
            ;;
        fails)
            if [[ $exit_code -ne 0 ]]; then pass=true; fi
            fail_reason="El comando tuvo éxito pero se esperaba que fallara."
            ;;
        file_exists)
            if [ -f "$check_arg" ]; then pass=true; fi
            fail_reason="El archivo esperado '$check_arg' no fue encontrado."
            ;;
        # --- MODIFICADO: Nuevo check para verificar salida vacía ---
        is_empty)
            if [[ -z "$output" ]]; then pass=true; fi
            fail_reason="La salida no estaba vacía, pero se esperaba que lo estuviera."
            ;;
        *)
            echo -e "  ${C_RED}ERROR DE TEST: Tipo de check desconocido '$check_type'.${C_NC}"
            FAIL_COUNT=$((FAIL_COUNT + 1))
            return
            ;;
    esac

    if $pass; then
        echo -e "  ${C_GREEN}PASÓ${C_NC}"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "  ${C_RED}FALLÓ${C_NC}"
        echo "    - Razón: $fail_reason"
        echo "    - Comando ejecutado: $command"
        echo "    - Salida obtenida:"
        echo "$output" | sed 's/^/      /'
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
}

# ==============================================================================
# --- EJECUCIÓN DE LA BATERÍA DE PRUEBAS ---
# ==============================================================================

if ! command -v $EXECUTABLE &> /dev/null; then
    echo -e "${C_RED}Error: El comando '$EXECUTABLE' no se encuentra en tu PATH.${C_NC}"
    echo "Por favor, ejecuta './install.sh' primero para instalarlo."
    exit 1
fi

setup

echo -e "${C_BLUE}--- INICIANDO BATERÍA DE PRUEBAS ---${C_NC}"

# --- Pruebas de Funcionalidad Básica ---
run_test "Básico no recursivo" "$EXECUTABLE $TEST_DIR --print" "contains" "// main.py"
run_test "Básico no recursivo (no debe incluir subdirectorios)" "$EXECUTABLE $TEST_DIR --print" "not_contains" "// src/utils.py"
run_test "Recursivo" "$EXECUTABLE $TEST_DIR -r --print" "contains" "// src/utils.py"
run_test "Salida a archivo (-o)" "$EXECUTABLE $TEST_DIR -r -o $OUTPUT_FILE" "succeeds"
run_test "Verificación de archivo de salida" "cat $OUTPUT_FILE" "contains" "// docs/guide.md"

# --- Pruebas de Filtros y Exclusiones ---
run_test "Filtro por tipo de archivo (--filetype)" "$EXECUTABLE '$TEST_DIR' -r -p --filetype .py" "not_contains" "// README.md"
run_test "Excluir directorios (--exclude-dir)" "$EXECUTABLE '$TEST_DIR' -r -p --exclude-dir .git node_modules" "not_contains" "// .git/config"
run_test "Excluir archivos (--exclude-file)" "$EXECUTABLE '$TEST_DIR' -r -p --exclude-file package-lock.json" "not_contains" "// package-lock.json"
run_test "Filtro por Regex (--regex-filter)" "$EXECUTABLE '$TEST_DIR' -r -p --regex-filter '^tsconfig.*json$'" "contains" "// tsconfig.build.json"
run_test "Filtro por Regex (no debe incluir otros archivos)" "$EXECUTABLE '$TEST_DIR' -r -p --regex-filter '^tsconfig.*json$'" "not_contains" "// main.py"

# --- Pruebas de Combinación de Argumentos ---
run_test "Combinación: --filetype y --exclude-dir" "$EXECUTABLE '$TEST_DIR' -r -p --filetype .py --exclude-dir src" "not_contains" "// src/utils.py"
run_test "Combinación: --regex-filter y --exclude-file" "$EXECUTABLE '$TEST_DIR' -r -p --regex-filter '^tsconfig.*' --exclude-file tsconfig.build.json" "not_contains" "// tsconfig.build.json"

# --- Pruebas de Casos Límite y Errores ---
# --- MODIFICADO: Estos tests ahora verifican que la salida esté vacía en modo -q ---
run_test "Sin resultados en modo silencioso (debe ser silencioso)" "$EXECUTABLE $TEST_DIR -q --filetype .nonexistent" "is_empty"
run_test "Directorio vacío en modo silencioso (debe ser silencioso)" "$EXECUTABLE $TEST_DIR/empty_dir -r -q" "is_empty"

run_test "Comando debe fallar (directorio inválido)" "$EXECUTABLE /nonexistent/path -q" "fails"
run_test "Argumento --version" "$EXECUTABLE --version" "contains" "codic"

# ==============================================================================
# --- Resumen Final ---
# ==============================================================================
echo -e "\n${C_BLUE}--- RESUMEN DE PRUEBAS ---${C_NC}"
echo -e "Total de pruebas ejecutadas: ${C_YELLOW}${TOTAL_TESTS}${C_NC}"
echo -e "  Pruebas superadas: ${C_GREEN}${PASS_COUNT}${C_NC}"
echo -e "  Pruebas fallidas: ${C_RED}${FAIL_COUNT}${C_NC}"
echo ""

if [ "$FAIL_COUNT" -eq 0 ]; then
    echo -e "${C_GREEN}¡Todas las pruebas pasaron con éxito! ✨${C_NC}"
    exit 0
else
    echo -e "${C_RED}Algunas pruebas fallaron. Revisa los logs de arriba.${C_NC}"
    exit 1
fi