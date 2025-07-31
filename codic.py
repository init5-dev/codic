#!/usr/bin/env python3

'''
COpy Directory Into Clipboard (CODIC) Utility
A tool to consolidate files from a directory into a single text. Ideal for providing context to AI tools with Google AI Studio.
'''

import os
import sys
import argparse
import pyperclip
import re

__version__ = "2.4.0" # <--- MODIFICADO: Nueva versión con la corrección

# ... (Las funciones read_files_in_directory y read_file_content no cambian) ...
def read_files_in_directory(directory_path, recursive, filetypes, exclude_dirs, exclude_files, regex_pattern):
    output = []
    base_path = os.path.abspath(directory_path)
    exclude_dirs = set(exclude_dirs) if exclude_dirs else set()
    exclude_files = set(exclude_files) if exclude_files else set()
    for root, dirs, files in os.walk(base_path, topdown=True):
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        if not recursive and root != base_path:
            dirs[:] = []
            continue
        for file in files:
            if file in exclude_files: continue
            if filetypes and not any(file.endswith(ft) for ft in filetypes): continue
            if regex_pattern and not regex_pattern.search(file): continue
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, base_path)
            content = read_file_content(file_path)
            output.append(f"// {rel_path}\n\n{content}\n\n")
    return ''.join(output)

def read_file_content(file_path):
    try:
        with open(file_path, 'r', encoding='utf-8') as f: return f.read()
    except UnicodeDecodeError:
        try:
            with open(file_path, 'r', encoding='latin-1') as f: return f.read()
        except Exception as e: return f"// Error al leer el archivo {os.path.basename(file_path)}: {str(e)}"
    except Exception as e: return f"// Error al leer el archivo {os.path.basename(file_path)}: {str(e)}"


def main():
    """
    Función principal que analiza los argumentos y ejecuta la lógica del script.
    """
    parser = argparse.ArgumentParser(
        description='Consolida archivos de un directorio. Por defecto, copia al portapapeles en terminales interactivas e imprime a stdout en otros casos.',
        formatter_class=argparse.RawTextHelpFormatter
    )
    
    parser.add_argument('directory', help='Ruta del directorio a procesar.')
    
    # --- Argumentos de Control de Archivos ---
    parser.add_argument('-r', '--recursive', action='store_true', help='Procesa los archivos en todos los subdirectorios.')
    parser.add_argument('--filetype', nargs='+', metavar='EXT', help='Incluir solo archivos con estas extensiones.')
    parser.add_argument('--exclude-dir', nargs='+', metavar='DIRNAME', help='Excluir directorios por nombre.')
    parser.add_argument('--exclude-file', nargs='+', metavar='FILENAME', help='Excluir archivos por nombre.')
    parser.add_argument('--regex-filter', metavar='PATTERN', help='Incluir solo archivos cuyo nombre coincida con la regex.')

    # --- MODIFICADO: Grupo de salida mutuamente exclusivo y completo ---
    output_group = parser.add_mutually_exclusive_group()
    output_group.add_argument(
        '-c', '--copy', 
        action='store_true', 
        help='Forzar la copia al portapapeles.'
    )
    # --- LA LÍNEA QUE FALTABA ---
    output_group.add_argument(
        '-p', '--print', 
        action='store_true', 
        help='Forzar la impresión a la salida estándar (stdout).'
    )
    # --- MODIFICADO: -o ahora es parte del grupo ---
    output_group.add_argument(
        '-o', '--output', 
        metavar='FILEPATH', 
        help='Guardar el resultado en un archivo.'
    )
    
    parser.add_argument('-q', '--quiet', action='store_true', help='Modo silencioso, no imprime mensajes de estado a stderr.')
    parser.add_argument('--version', action='version', version=f'%(prog)s {__version__}')
    
    args = parser.parse_args()
    
    if not os.path.isdir(args.directory):
        print(f"Error: '{args.directory}' no es un directorio válido.", file=sys.stderr)
        sys.exit(1)

    regex_pattern = None
    if args.regex_filter:
        try:
            regex_pattern = re.compile(args.regex_filter)
        except re.error as e:
            print(f"Error: Expresión regular inválida: '{args.regex_filter}'\nDetalle: {e}", file=sys.stderr)
            sys.exit(1)
    
    try:
        result = read_files_in_directory(
            args.directory, args.recursive, args.filetype, 
            args.exclude_dir, args.exclude_file, regex_pattern
        )
        
        if not result:
            if not args.quiet:
                print("No se encontraron archivos que coincidan con los criterios especificados.", file=sys.stderr)
            return

        # La lógica de salida ya era correcta, solo le faltaba el argumento para activarla
        if args.output:
            with open(args.output, 'w', encoding='utf-8') as f: f.write(result)
            if not args.quiet: print(f"Contenido guardado en '{args.output}'.", file=sys.stderr)
        elif args.copy:
            pyperclip.copy(result)
            if not args.quiet: print("Contenido copiado al portapapeles (forzado).", file=sys.stderr)
        elif args.print:
            print(result.strip())
        elif sys.stdout.isatty():
            pyperclip.copy(result)
            if not args.quiet: print("Contenido copiado al portapapeles (modo interactivo).", file=sys.stderr)
        else:
            print(result.strip())

    except Exception as e:
        print(f"Ocurrió un error inesperado: {str(e)}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()