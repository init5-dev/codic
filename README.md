# CODIC - COpy Directory Into Clipboard

![Version](https://img.shields.io/badge/version-2.4.0-blue)
![Build Status](https://img.shields.io/badge/tests-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

**CODIC** is a command-line interface (CLI) tool written in Python that consolidates code from multiple files within a directory into a single block of text. It was designed to streamline the process of copying and pasting entire project contexts into Large Language Models (LLMs) like ChatGPT, Claude, or Gemini.

## The Problem It Solves

When working with LLMs to debug code, generate documentation, or refactor, you often need to provide the context of several files. Doing this manually (open file, copy, paste, open another file...) is slow and error-prone. CODIC automates this process with a single, powerful command.

## Key Features

-   **Clipboard by Default:** Designed for maximum convenience in interactive terminals.
-   **Recursive Processing:** Navigate through subdirectories with the `-r` flag.
-   **Powerful Filtering:**
    -   Include only certain file types (`--filetype`).
    -   Exclude specific directories (`--exclude-dir`), like `.git` or `node_modules`.
    -   Exclude specific files by name (`--exclude-file`).
    -   Filter filenames using **regular expressions** (`--regex-filter`).
-   **Flexible Output:**
    -   Copies to the clipboard (default behavior in interactive terminals).
    -   Prints to standard output (`stdout`) for use with pipes (`|`) or redirects (`>`).
    -   Saves directly to a file (`-o`).
-   **Smart & Testable:** Automatically detects if it's running in an interactive terminal or a script to adjust its output behavior.
-   **Simple Installer:** Comes with an `install.sh` script for easy, one-step installation on Linux systems.

## Installation (Linux)

The installation script handles system dependencies, compiles the tool into a single executable using PyInstaller, and installs it to your system's `PATH` so you can call it from anywhere.

1.  Clone or download this repository.
2.  Open a terminal in the project's root directory.
3.  Make the installer executable:
    ```bash
    chmod +x install.sh
    ```
4.  Run the installer (sudo is required to move the final file):
    ```bash
    sudo ./install.sh
    ```
5.  **Important:** Open a new terminal window or run `hash -r` for your shell to recognize the new command.

## Usage

The basic command structure is:

```bash
codic [DIRECTORY] [OPTIONS]
```

### Examples

**1. Copy all code from a project to the clipboard (excluding `.git` and `node_modules`):**
```bash
codic ./my-project -r --exclude-dir .git node_modules
```

**2. Copy only `.py` and `.md` files recursively:**
```bash
codic ./my-project -r --filetype .py .md
```

**3. Save all TypeScript config files (`tsconfig.*.json`) to a text file:**```bash
codic . -r --regex-filter "^tsconfig.*\.json$" -o ts_configs.txt```

**4. Print only the files in the root directory (non-recursively) to the console:**
```bash
codic . --print
```

### All Arguments

```
usage: codic [-h] [-r] [--filetype EXT [EXT ...]]
             [--exclude-dir DIRNAME [DIRNAME ...]]
             [--exclude-file FILENAME [FILENAME ...]]
             [--regex-filter PATTERN] [-c | -p | -o FILEPATH] [-q]
             [--version]
             directory

Consolidates files from a directory. By default, copies to the clipboard in
interactive terminals and prints to stdout otherwise.

positional arguments:
  directory             Path to the directory to process.

options:
  -h, --help            show this help message and exit
  -r, --recursive       Process files in all subdirectories.
  --filetype EXT [EXT ...]
                        Include only files with these extensions.
  --exclude-dir DIRNAME [DIRNAME ...]
                        Exclude directories by name.
  --exclude-file FILENAME [FILENAME ...]
                        Exclude files by name.
  --regex-filter PATTERN
                        Include only files whose names match the regex.
  -c, --copy            Force copy to clipboard.
  -p, --print           Force print to standard output (stdout).
  -o FILEPATH, --output FILEPATH
                        Save the result to a file.
  -q, --quiet           Quiet mode; suppresses status messages to stderr.
  --version             show program's version number and exit
```

## Testing

The project includes a comprehensive test harness to ensure reliability. To run it:

1.  Make sure you have installed the tool using `install.sh`.
2.  Make the test runner executable:
    ```bash
    chmod +x test_runner.sh
    ```
3.  Run the tests:
    ```bash
    ./test_runner.sh
    ```

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.
```