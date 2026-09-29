# Report: Environment Information Application and Native Build on the HOST System

## 1. C Application Development

### 1.1. Purpose and Implementation

The `src/env-info.c` application was developed to print a formatted message containing information about the runtime environment:

- hostname;
- current local time;
- operating system name;
- kernel release and version;
- hardware architecture.

The `print_env_info()` function accepts a `FILE *` stream and is used to print the same formatted environment information both to the console and to a file.

The system information and current time are obtained only once during each program execution. Therefore, the message printed to the console and the message written to a file during the same run contain identical values.

The `uname()` function provides the operating system name, kernel information, hostname, and hardware architecture identifier. It does not determine the Linux distribution name or the exact hardware device model.

### 1.2. Command-Line Arguments and File Handling

The application supports two execution modes:

```bash
./builds/env-info-native-host
./builds/env-info-native-host output.txt
```

When no additional argument is provided, the environment information is printed only to the console.

If a filename is provided as a command-line argument, the same message is also written to that file.

This behavior provides the following results:

- if the file does not exist, it is created;
- if the file already exists, new information is appended to the end;
- the existing file contents are preserved.

Before writing, the program attempts to open the specified file in read mode. If the operation succeeds, a warning is printed to `stderr`:

This check assumes that an existing output file can be opened for reading.
If a file allows writing but denies reading, the application may append the message without displaying the existing-file warning.

```text
Warning: file '...' already exists. Information will be appended.
```

### 1.3. Error Handling

The application checks the following operations:

- the number of command-line arguments;
- the result of `uname()`;
- the results of `time()` and `ctime()`;
- console output and `fflush(stdout)`;
- opening the output file;
- writing the formatted message;
- closing the output file.

The program returns:

```text
0  - successful execution
1  - detected error
```

The result of `fclose()` is also checked because an error in buffered output may occur when buffered data is finally written to the underlying file.

---

## 2. Compilation, Testing, and Analysis on the HOST System

### 2.1. HOST Environment

| Parameter | Value |
|---|---|
| Hostname | `Legion-Slim7` |
| Distribution | EndeavourOS, Arch-based |
| Architecture | `x86_64` |
| Kernel | `7.2.7-arch1-1` |
| GCC | `16.2.1 20260810` |
| GNU Binutils | `2.47` |
| glibc | `2.44` |

### 2.2. Native Compilation

The `scripts/build-native-host.sh` build script was developed for native compilation on the HOST system.

The script determines the project root directory relative to its own location, verifies that the compiler is available, creates the `builds/` directory, and performs compilation.

The build script is executed with:

```bash
bash scripts/build-native-host.sh
```

The equivalent compilation command executed from the project root is:

```bash
gcc -std=c11 \
    -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 \
    -O2 -g \
    src/env-info.c \
    -o builds/env-info-native-host
```

The compiler options have the following purposes:

| Option | Purpose |
|---|---|
| `-std=c11` | Select the C11 language standard |
| `-Wall -Wextra -Wpedantic` | Enable common and additional compiler diagnostics |
| `-Wshadow` | Warn when one variable shadows another |
| `-Wformat=2` | Enable additional format-string checks |
| `-O2` | Enable optimization |
| `-g` | Include debugging information |
| `-o` | Specify the output file path |

The resulting executable is:

```text
builds/env-info-native-host
```

### 2.3. Functional Testing

The application was first tested without command-line arguments.

It successfully printed HOST environment information to the console and terminated with exit code:

```text
0
```

The following output was recorded in `logs/native-host-create-file.txt`:

```text
=== ENVIRONMENT INFORMATION ===
Hostname: Legion-Slim7
Time: Tue Sep 29 14:48:35 2026
OS: Linux
Kernel release: 7.2.7-arch1-1
Kernel version: #1 SMP PREEMPT_DYNAMIC Mon, 21 Sep 2026 18:51:14 +0000
Hardware platform: x86_64
```

The file `logs/native-host-append-file.txt` initially contained:

```text
Hello World
```

After the application was executed with this file as the output argument, the environment information was appended after the existing line.

The preservation of the original `Hello World` text confirms that append mode was used correctly.

| Test | Result and Evidence |
|---|---|
| Execution without arguments | Environment information printed to the console; exit code `0` |
| Writing information to a new file | Output stored in `logs/native-host-create-file.txt` |
| Appending to an existing file | `Hello World` remains before the appended information in `logs/native-host-append-file.txt` |
| Passing two file arguments | Usage message printed; exit code `1` |

The command used to test excessive command-line arguments was:

```bash
./builds/env-info-native-host first.log second.log
```

The result was:

```text
Usage: ./builds/env-info-native-host [file]
```

### 2.4. Executable File Analysis

The `scripts/analyze-build.sh` script was developed to analyze the compiled HOST executable.

It is executed with:

```bash
./scripts/analyze-build.sh
```

The script analyzes:

```text
builds/env-info-native-host
```

The analysis results are displayed in the terminal and also saved to:

```text
logs/native-host-analysis.txt
```

All utilities required by the assignment were used:

- `readelf`;
- `ldd`;
- `size`;
- `strings`.

In addition, `file` was used to identify the executable file type, while `stat` was used to obtain the complete file size in bytes.

The `readelf`, `size`, and `strings` utilities are part of GNU Binutils.

On the HOST system, the `ldd` utility is provided by glibc.

#### File Format and Architecture

According to the output of `file` and `readelf -hW`, the executable has the following properties:

| Property | Value |
|---|---|
| Format | ELF — Executable and Linkable Format |
| Class | `ELF64` |
| Byte order | Little-endian |
| Architecture | `Advanced Micro Devices X86-64` |
| Type | `DYN`, PIE — Position Independent Executable |
| Linking | Dynamic |
| Debug information | Present |
| Symbol table | Preserved, `not stripped` |

#### Dynamic Loader and Libraries

According to `readelf -lW`, the executable contains an `INTERP` segment specifying the dynamic loader path:

```text
/lib64/ld-linux-x86-64.so.2
```

The dynamic section reported by `readelf -dW` contains the following direct dependency:

```text
NEEDED: libc.so.6
```

According to `ldd`, this library is resolved on the HOST system as:

```text
libc.so.6 => /usr/lib/libc.so.6
```

No missing libraries were reported in the saved analysis output.

The `readelf -VW` command reports dependencies on the following symbol versions:

```text
GLIBC_2.2.5
GLIBC_2.4
GLIBC_2.34
```

These values represent the glibc symbol versions required by the executable.

They do not represent the version of glibc currently installed on the HOST system.

The HOST system itself uses:

```text
glibc 2.44
```

#### Code, Data, and File Size

The `size` utility produced the following result:

```text
text    data    bss    dec    hex
3353    656     48     4057   fd9
```

| Metric | Size, bytes |
|---|---:|
| `text` | 3353 |
| `data` | 656 |
| `bss` | 48 |
| Total `dec` | 4057 |
| Complete file size reported by `stat` | 21960 |

#### Printable Strings

Using:

```bash
strings -a builds/env-info-native-host
```

the following strings were identified inside the executable:

- the `=== ENVIRONMENT INFORMATION ===` header;
- the `Hostname`, `Time`, `OS`, `Kernel`, and `Hardware platform` field templates;
- the warning message for an existing file;
- usage and error messages;
- names of library functions;
- the compiler version string `GCC: (GNU) 16.2.1 20260810`.

The output also contains the string:

```text
Time: %sOS: %s
```

This corresponds to the implementation of the format string in the source code.

The line break between the time value and the `OS` field during execution is provided by the string returned by `ctime()`.

Values such as the actual hostname, current time, and kernel version are obtained dynamically at runtime and are therefore not stored as fixed environment-specific strings inside the executable.

---

## 3. Results of the Completed Stages

C application was implemented to display information about the runtime environment and optionally write the same formatted message to a file using append mode.

Native compilation and executable analysis scripts were developed.

The resulting HOST executable is a dynamically linked ELF64 PIE file for the `x86_64` architecture.

Its execution was successfully tested, including console output, file creation, appending to an existing file, and command-line argument validation.

The executable was analyzed using:

```text
readelf
ldd
size
strings
```

The analysis identified the executable architecture, ELF type, linking method, dynamic loader path, library dependencies, required glibc symbol versions, and the sizes of the executable code, data sections, and complete ELF file.

The simplified file-existence check based on opening the file in read mode remains a known implementation limitation.

The obtained HOST results provide a baseline for the next stages of the assignment:

- cross-compilation for the TARGET system;
- native compilation directly on the TARGET system;
- static linking;
- comparison of executables produced in different development environments.