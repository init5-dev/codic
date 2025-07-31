#!/bin/bash

# install.sh - Instalador mejorado para codic
# Este script crea un entorno virtual, compila el script con PyInstaller
# y lo instala en el PATH del sistema para un uso global.

# --- Configuración ---
PYTHON_SCRIPT="codic.py"
REQUIREMENTS_FILE="requirements.txt"
EXECUTABLE_NAME="codic"
VENV_DIR="build_env" # Directorio para el entorno virtual temporal

# --- Inicio del Script ---

# 0. Verificar si estamos en Linux
if [[ "$(uname)" != "Linux" ]]; then
    echo "Error: Este script está diseñado solo para sistemas Linux."
    exit 1
fi

# Verificar que los archivos necesarios existen
if [ ! -f "$PYTHON_SCRIPT" ] || [ ! -f "$REQUIREMENTS_FILE" ]; then
    echo "Error: Asegúrate de que '$PYTHON_SCRIPT' y '$REQUIREMENTS_FILE' existan en el directorio actual."
    exit 1
fi

# 1. Instalar dependencias del sistema (si no existen)
echo "Paso 1: Verificando dependencias del sistema (python3, pip, venv)..."
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y python3 python3-pip python3-venv
echo "Dependencias del sistema verificadas."
echo

# 2. Crear y activar un entorno virtual para la compilación
echo "Paso 2: Creando un entorno virtual temporal en './$VENV_DIR'..."
rm -rf "$VENV_DIR" # Limpiar entorno previo si existe
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
echo "Entorno virtual activado."
echo

# 3. Instalar dependencias de Python desde requirements.txt
echo "Paso 3: Instalando dependencias de Python (pyperclip, pyinstaller)..."
pip install -r "$REQUIREMENTS_FILE"
echo "Dependencias de Python instaladas."
echo

# 4. Compilar el script de Python a un solo ejecutable
echo "Paso 4: Compilando '$PYTHON_SCRIPT' con PyInstaller..."
pyinstaller --onefile --name "$EXECUTABLE_NAME" "$PYTHON_SCRIPT"
echo "Compilación finalizada."
echo

# Desactivar el entorno virtual
deactivate

# 5. Instalar el ejecutable en /usr/local/bin
echo "Paso 5: Instalando el ejecutable en /usr/local/bin..."
if [ -f "dist/$EXECUTABLE_NAME" ]; then
    sudo mv "dist/$EXECUTABLE_NAME" "/usr/local/bin/"
    sudo chmod +x "/usr/local/bin/$EXECUTABLE_NAME"
    echo "El ejecutable ha sido movido y ahora es accesible globalmente."
else
    echo "Error: No se encontró el archivo compilado en 'dist/'. La instalación ha fallado."
    # Limpiar antes de salir
    rm -rf build/ dist/ __pycache__/ "$EXECUTABLE_NAME.spec" "$VENV_DIR"
    exit 1
fi
echo

# 6. Limpiar archivos temporales y de compilación
echo "Paso 6: Limpiando archivos temporales..."
rm -rf build/ dist/ __pycache__/ "$EXECUTABLE_NAME.spec" "$VENV_DIR"
echo "Limpieza completada."
echo

# --- Mensaje Final ---
echo "¡Instalación completada con éxito!"
echo "Ahora puedes usar el comando '$EXECUTABLE_NAME' desde cualquier lugar en tu terminal."
echo "Ejemplo de uso: $EXECUTABLE_NAME /ruta/a/tu/directorio -r --filetype .py"
