# Report: Environment Information Application, Native Compilation and Cross-Compilation

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

The `scripts/analyze-build-native-host.sh` script was developed to analyze the compiled HOST executable.

It is executed with:

```bash
./scripts/analyze-build-native-host.sh
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

## 3. Cross-Compilation on HOST and Execution on TARGET

### 3.1. Cross-Compilation Setup

The application was cross-compiled on the x86_64 HOST system for the
AArch64 TARGET system: a Raspberry Pi 5 running 64-bit Raspberry Pi OS Lite.

The native build script was adapted into:

```text
scripts/build-cross-host.sh
```

The cross-compilation script explicitly selects:

```bash
CC="aarch64-linux-gnu-gcc"
```

This prevents an inherited `CC` environment variable from accidentally
selecting the native HOST compiler.

The source file and compiler flags remain the same as in the native build.
The compiler and output executable path are changed.

| Parameter | Value |
|---|---|
| Build system | HOST, x86_64 |
| Execution system | TARGET, AArch64 |
| Cross compiler | `aarch64-linux-gnu-gcc` |
| Cross GCC version | `16.1.0` |
| Compiler target | `aarch64-linux-gnu` |
| Cross binutils version | `2.47` |
| glibc supplied with the cross toolchain | `2.44` |
| Source file | `src/env-info.c` |
| Output executable | `builds/env-info-cross-host` |

The build script is executed on HOST with:

```bash
bash scripts/build-cross-host.sh
```

The equivalent compiler invocation is:

```bash
aarch64-linux-gnu-gcc -std=c11 \
    -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 \
    -O2 -g \
    src/env-info.c \
    -o builds/env-info-cross-host
```

The compiler runs on HOST but generates machine code for TARGET.
No changes to the application source code were required for this build.

### 3.2. Deployment and Execution on TARGET

The cross-compiled executable was made available on the Raspberry Pi.
The TARGET analysis log identifies its location as:

```text
/home/art207-rpi5/Projects/TASK-04.-Cross-compilation/builds/env-info-cross-host
```

The filename retains the `cross-host` suffix because the executable was
built on HOST. Its execution architecture is AArch64.

The TARGET runtime information recorded in the application output is:

| Parameter | Value |
|---|---|
| Hostname | `ajax-rpi5` |
| Operating system | `Linux` |
| Kernel release | `6.18.50+rpt-rpi-2712` |
| Hardware architecture | `aarch64` |

The file `logs/cross-target-create-file.txt` contains:

```text
=== ENVIRONMENT INFORMATION ===
Hostname: ajax-rpi5
Time: Tue Sep 29 20:01:30 2026
OS: Linux
Kernel release: 6.18.50+rpt-rpi-2712
Kernel version: #1 SMP PREEMPT Debian 1:6.18.50-1+rpt1 (2026-09-11)
Hardware platform: aarch64
```

The recorded hostname, kernel information, and architecture belong to
TARGET rather than HOST. This demonstrates that the application obtains
environment information at runtime.

The append-test file, `logs/cross-target-append-file.txt`, contains:

```text
Hello Raspbery Pi5
=== ENVIRONMENT INFORMATION ===
Hostname: ajax-rpi5
Time: Tue Sep 29 20:03:14 2026
OS: Linux
Kernel release: 6.18.50+rpt-rpi-2712
Kernel version: #1 SMP PREEMPT Debian 1:6.18.50-1+rpt1 (2026-09-11)
Hardware platform: aarch64
```

The initial text remains before the application message, consistent with
the use of append mode.

| Check | Recorded result |
|---|---|
| Application execution on TARGET | Output contains TARGET hostname, kernel, and architecture |
| File-output test | Environment information is present in `logs/cross-target-create-file.txt` |
| Append test | Existing text is preserved before the message in `logs/cross-target-append-file.txt` |
| Dynamic library resolution | TARGET `ldd` output resolves the required libc without reporting missing dependencies |

### 3.3. Executable Analysis on TARGET

The script used for this stage is:

```text
scripts/analyze-build-cross-target.sh
```

It is executed on TARGET from the project root:

```bash
./scripts/analyze-build-cross-target.sh
```

The script analyzes `builds/env-info-cross-host` using `readelf`, `ldd`,
`size`, and `strings`. It also runs `file` and `stat`.

The complete analysis output is stored in:

```text
logs/cross-target-analysis.txt
```

Running `ldd` on TARGET checks library resolution in the environment
where the AArch64 executable is intended to run.

#### ELF Format and Architecture

The `file` and `readelf -hW` results identify the executable as:

| Property | Value |
|---|---|
| Format | ELF — Executable and Linkable Format |
| Class | `ELF64` |
| Byte order | Little-endian |
| Machine | `AArch64` |
| Type | `DYN`, PIE — Position Independent Executable |
| Linking | Dynamic |
| Debug information | Present |
| Symbol table | Preserved, `not stripped` |

These results confirm that the cross compiler generated an AArch64
executable rather than an x86_64 HOST executable.

#### Dynamic Loader and Libraries

The `readelf -lW` output contains an `INTERP` segment requesting:

```text
/lib/ld-linux-aarch64.so.1
```

The `readelf -dW` output lists the following direct shared-library
dependency:

```text
NEEDED: libc.so.6
```

On TARGET, `ldd` resolves this dependency as:

```text
libc.so.6 => /lib/aarch64-linux-gnu/libc.so.6
```

The recorded output contains no missing-library or symbol-version errors.

The `readelf -VW` output lists these required glibc symbol versions:

```text
GLIBC_2.17
GLIBC_2.34
```

Although the cross toolchain contains glibc 2.44, this particular
executable does not request a `GLIBC_2.44` symbol version.

The recorded library resolution and application output demonstrate
compatibility with the TARGET environment for the tested operations.
They do not establish compatibility for every application built with
the same toolchain.

The installed TARGET glibc version is not explicitly recorded in these
logs. Required symbol versions should not be interpreted as the installed
library version.

#### Printable Strings

The `strings -a` output contains:

- the environment-information header and field templates;
- the existing-file warning;
- usage and error messages;
- library function names;
- the compiler identification `GCC: (GNU) 16.1.0`;
- source and header paths associated with the HOST build environment.

For example, debugging information includes:

```text
/home/art207/Projects/TASK-04.-Cross-compilation/src/env-info.c
/usr/aarch64-linux-gnu/include
```

These paths describe the compilation environment and are consistent
with the use of `-g`. They are not runtime paths that must exist on
the Raspberry Pi for normal application execution.

### 3.4. Comparison with the Native HOST Build

Both executables were built from the same application source using
the same explicit warning, optimization, and debugging flags.

However, the target architectures, compiler versions, and toolchain
defaults differ.

| Property | Native HOST build | Cross build executed on TARGET |
|---|---|---|
| Build machine | HOST | HOST |
| Execution machine | HOST | TARGET |
| Compiler | `gcc` | `aarch64-linux-gnu-gcc` |
| GCC version | `16.2.1` | `16.1.0` |
| ELF architecture | x86-64 | AArch64 |
| ELF class | ELF64 | ELF64 |
| Byte order | Little-endian | Little-endian |
| Executable type | PIE | PIE |
| Linking | Dynamic | Dynamic |
| Direct libc dependency | `libc.so.6` | `libc.so.6` |
| Debug information | Present | Present |
| Runtime hostname | `Legion-Slim7` | `ajax-rpi5` |
| Runtime kernel | `7.2.7-arch1-1` | `6.18.50+rpt-rpi-2712` |

The dynamic loader paths differ:

```text
HOST:   /lib64/ld-linux-x86-64.so.2
TARGET: /lib/ld-linux-aarch64.so.1
```

The required glibc symbol versions also differ:

```text
HOST:   GLIBC_2.2.5, GLIBC_2.4, GLIBC_2.34
TARGET: GLIBC_2.17, GLIBC_2.34
```

The shared-library filename `libc.so.6` is the same, but each environment
provides a library built for its own architecture.

#### Size Comparison

| Metric | Native HOST build | Cross build |
|---|---:|---:|
| `text`, bytes | 3353 | 3247 |
| `data`, bytes | 656 | 704 |
| `bss`, bytes | 48 | 8 |
| Total `dec`, bytes | 4057 | 3959 |
| Complete file size, bytes | 21960 | 76648 |

The cross-built file is 54,688 bytes larger, while its total reported
by `size` is 98 bytes smaller.

This difference is largely explained by the ELF file layout rather than
an increase in application code.

The program headers show different `LOAD` segment alignment values:

```text
HOST:   0x1000  = 4096 bytes
TARGET: 0x10000 = 65536 bytes
```

In the AArch64 executable, the first `LOAD` segment ends at file offset
`0x0f60`, while the second starts at `0xfdb8`. The gap between them is:

```text
0xfdb8 - 0x0f60 = 61016 bytes
```

Inspection of the local cross-built executable confirmed that this gap
contains zero bytes.

The alignment value is an ELF segment property. It does not establish
the actual memory page size used by the running TARGET kernel.

Both files also contain debugging information, symbol tables, and other
metadata. Consequently, the complete file size is different from the
sum reported by `size`.

Neither measurement represents the total runtime memory consumption of
the application. The measurements also do not establish which executable
runs faster.

Because the architectures and compiler versions differ, the observed
code and data differences cannot be attributed to a single factor.

### 3.5. Cross-Development Observations

The recorded results demonstrate the following:

1. Selecting `aarch64-linux-gnu-gcc` generated machine code for the
   Raspberry Pi while compilation remained on the x86_64 HOST.

2. The application reported TARGET runtime information even though
   it was compiled on HOST.

3. Correct architecture alone is not sufficient for a dynamically
   linked executable. The required loader, libraries, and symbol
   versions must also be available on TARGET.

4. In this test, the required libraries were resolved and the application
   produced the expected TARGET information and file-output results.

5. Executable file size depends on linker layout and metadata as well
   as code and data. The larger AArch64 file does not imply proportionally
   greater application memory usage.

The file-existence check retains the limitation described in Section 1:
an existing file that cannot be opened for reading may not produce
the warning before an otherwise permitted append operation.

### 3.6. Recorded Artifacts

The cross-compilation and TARGET analysis scripts are stored in:

```text
scripts/build-cross-host.sh
scripts/analyze-build-cross-target.sh
```

The executable and TARGET results are also tracked in the repository:

```text
builds/env-info-cross-host
logs/cross-target-analysis.txt
logs/cross-target-create-file.txt
logs/cross-target-append-file.txt
```

The TARGET logs were added in commit:

```text
43ee489
```

These results provide the comparison baseline for native compilation
directly on TARGET and for the subsequent static-linking stage.

## 4. Native Compilation and Analysis on TARGET

### 4.1. Native Development Environment

The application was compiled directly on the Raspberry Pi 5 using the
native development tools available on TARGET.

Unlike the previous cross-compilation stage, both compilation and
execution took place on the AArch64 TARGET system.

The compiler identification recorded in the executable is:

```text
GCC: (Debian 14.2.0-19) 14.2.0
```

The recorded TARGET environment is:

| Parameter | Value |
|---|---|
| Device | Raspberry Pi 5 |
| Hostname | `ajax-rpi5` |
| Operating system | Linux |
| Kernel release | `6.18.50+rpt-rpi-2712` |
| Architecture | `aarch64` |
| Native compiler | `gcc` |
| Native GCC version | `14.2.0`, Debian package identification `14.2.0-19` |

The resulting executable and analysis output demonstrate that the
compiler, development headers and libraries, and required analysis
utilities were available on TARGET.

### 4.2. Script Adaptation and HOST Recheck

Two TARGET-specific scripts were prepared from the existing native
HOST scripts:

```text
scripts/build-native-target.sh
scripts/analyze-build-native-target.sh
```

The scripts do not differ significantly from their HOST counterparts.
The compilation and analysis operations remain unchanged.

The operational differences are limited to file paths:

| Setting | Native HOST script | Native TARGET script |
|---|---|---|
| Build output | `builds/env-info-native-host` | `builds/env-info-native-target` |
| Analyzed executable | `builds/env-info-native-host` | `builds/env-info-native-target` |
| Analysis log | `logs/native-host-analysis.txt` | `logs/native-target-analysis.txt` |

The displayed headings and diagnostic messages were also adjusted to
refer to TARGET.

Both build scripts use the same compiler-selection expression:

```bash
CC="${CC:-gcc}"
```

Both use the same source file, compiler flags, directory handling,
compiler availability check, and compilation command structure.

Similarly, both analysis scripts perform the same checks and invoke
the same utilities.

No changes to the C source code or build logic were required to make
native compilation work on TARGET. The original HOST scripts remained
unchanged.

Therefore, repeating the unchanged HOST workflow was not necessary
for this stage. The conditional HOST recheck in task 4(d*) was considered
inapplicable because no compatibility-related script modifications
were required; separate TARGET copies only adjusted paths and messages.

The native TARGET executable was built and tested on the Raspberry Pi.

### 4.3. Native Build on TARGET

The build script is executed from the project root on TARGET:

```bash
./scripts/build-native-target.sh
```

With the default compiler selection, the equivalent compilation
command is:

```bash
gcc -std=c11 \
    -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 \
    -O2 -g \
    src/env-info.c \
    -o builds/env-info-native-target
```

The output executable is:

```text
builds/env-info-native-target
```

The explicit warning, optimization, and debugging flags are the same
as those used for the native HOST build and the cross build.

Using the native `gcc` on TARGET produces AArch64 machine code.
The application source does not require architecture-specific changes.

### 4.4. Functional Testing on TARGET

The file-output test produced `logs/native-target-create-file.txt`
with the following content:

```text
=== ENVIRONMENT INFORMATION ===
Hostname: ajax-rpi5
Time: Tue Sep 29 21:04:46 2026
OS: Linux
Kernel release: 6.18.50+rpt-rpi-2712
Kernel version: #1 SMP PREEMPT Debian 1:6.18.50-1+rpt1 (2026-09-11)
Hardware platform: aarch64
```

The output identifies the Raspberry Pi runtime environment.

The append-test file, `logs/native-target-append-file.txt`, contains
the initial line:

```text
Hello native Raspberry Pi5
```

The environment-information message follows this line and records
the execution time:

```text
Tue Sep 29 21:06:40 2026
```

The original text remains present before the application message,
consistent with the use of append mode.

| Check | Recorded result |
|---|---|
| Execution of the native TARGET application | Output identifies `ajax-rpi5` and `aarch64` |
| File-output test | Environment information is stored in `logs/native-target-create-file.txt` |
| Append test | Existing text is preserved in `logs/native-target-append-file.txt` |
| Runtime environment reporting | Hostname and kernel information belong to TARGET |

### 4.5. Analysis of the Native TARGET Executable

The analysis script is executed on TARGET:

```bash
bash scripts/analyze-build-native-target.sh
```

It analyzes:

```text
builds/env-info-native-target
```

The complete output is stored in:

```text
logs/native-target-analysis.txt
```

The script uses `readelf`, `ldd`, `size`, and `strings`, together with
`file` and `stat`.

#### ELF Format and Linking

The recorded executable properties are:

| Property | Value |
|---|---|
| Format | ELF — Executable and Linkable Format |
| Class | `ELF64` |
| Byte order | Little-endian |
| Machine | `AArch64` |
| Type | `DYN`, PIE — Position Independent Executable |
| Linking | Dynamic |
| Debug information | Present |
| Symbol table | Preserved, `not stripped` |

The `INTERP` segment requests the dynamic loader:

```text
/lib/ld-linux-aarch64.so.1
```

The dynamic section contains the direct dependency:

```text
NEEDED: libc.so.6
```

The TARGET `ldd` output resolves it as:

```text
libc.so.6 => /lib/aarch64-linux-gnu/libc.so.6
```

No missing-library or symbol-version errors appear in the recorded
analysis output.

The required glibc symbol versions are:

```text
GLIBC_2.17
GLIBC_2.34
```

These are requirements of the executable, not an identification of
the glibc version installed on TARGET.

#### Code, Data, and File Size

The `size` output is:

```text
text    data    bss    dec    hex
3255    704     8      3967   f7f
```

The complete file size reported by `stat` is:

```text
76416 bytes
```

The complete file includes ELF headers, symbol tables, debugging
information, padding, and other metadata. Therefore, it is larger
than the sum reported by `size`.

#### Printable Strings and Build Information

The `strings -a` output contains:

- the environment-information header and field templates;
- usage, warning, and error messages;
- library function names;
- the GCC identification string;
- debugging information associated with the TARGET build environment.

The recorded source path is:

```text
/home/art207-rpi5/Projects/TASK-04.-Cross-compilation/src/env-info.c
```

Header paths include:

```text
/usr/include/aarch64-linux-gnu/bits
/usr/include
```

Together with the Debian GCC identification, these paths are consistent
with native compilation on TARGET.

They differ from the HOST paths and cross-toolchain include paths
recorded in the cross-built executable.

### 4.6. Comparison with the Cross-Compiled Executable

Both executables run on the same AArch64 TARGET system, but they were
built in different environments.

| Property | Cross build | Native TARGET build |
|---|---|---|
| Compilation system | HOST, x86_64 | TARGET, AArch64 |
| Execution system | TARGET | TARGET |
| Compiler | `aarch64-linux-gnu-gcc` | `gcc` |
| GCC version | `16.1.0` | `14.2.0` |
| Output architecture | AArch64 | AArch64 |
| Executable type | ELF64 PIE | ELF64 PIE |
| Linking | Dynamic | Dynamic |
| Dynamic loader | `/lib/ld-linux-aarch64.so.1` | `/lib/ld-linux-aarch64.so.1` |
| Direct shared-library dependency | `libc.so.6` | `libc.so.6` |
| Required glibc symbol versions | `GLIBC_2.17`, `GLIBC_2.34` | `GLIBC_2.17`, `GLIBC_2.34` |
| Debug information | Present | Present |

The size comparison is:

| Metric | Cross build | Native TARGET build |
|---|---:|---:|
| `text`, bytes | 3247 | 3255 |
| `data`, bytes | 704 | 704 |
| `bss`, bytes | 8 | 8 |
| Total `dec`, bytes | 3959 | 3967 |
| Complete file size, bytes | 76648 | 76416 |

The native TARGET executable is 232 bytes smaller as a complete file,
although its `text` category and `dec` total are 8 bytes larger.

Additional inspection of the stored executables shows:

| ELF section | Cross build | Native TARGET build |
|---|---:|---:|
| `.text` | 868 bytes | 868 bytes |
| `.eh_frame` | 248 bytes | 256 bytes |

The `text` category reported by `size` is not limited to the `.text`
section. Consequently, its 8-byte increase should not be described
as an 8-byte increase in machine instructions.

The executables also differ in metadata and section layout. For
example, the cross-built file contains an `.ARM.attributes` section,
while the native TARGET file does not.

These differences show why a slightly larger allocated-section total
can coexist with a smaller complete file.

The explicit build flags are the same, but compiler versions and
toolchain defaults differ. The observed size differences do not
establish a performance advantage for either build.

Both executables produced the expected TARGET environment information
and preserved existing file contents in the recorded append tests.

### 4.7. Recorded Artifacts and Outcome

The TARGET-specific scripts were added in commit:

```text
cb6a79a
```

The native TARGET executable and its test results were added in commit:

```text
6ff11be
```

The recorded artifacts are:

```text
scripts/build-native-target.sh
scripts/analyze-build-native-target.sh
builds/env-info-native-target
logs/native-target-analysis.txt
logs/native-target-create-file.txt
logs/native-target-append-file.txt
```

Native compilation directly on TARGET produced a dynamically linked
AArch64 executable from the same C source used in the previous stages.

The existing build and analysis logic was reusable without
compatibility-related changes. Only output paths, input paths,
report paths, and descriptive messages were adjusted for the
TARGET-specific copies.