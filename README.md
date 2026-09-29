# TASK-04.-Cross-compilation

Native compilation, cross-compilation and static
linking using C application that reports its runtime environment.

**[Full report](Report.md) · [Application source](src/env-info.c) · [Scripts](scripts/) · [Recorded results](logs/)**

---

## Overview

The project compares three build configurations, each using both dynamic
and static linking:

| Configuration | Compilation system | Execution system |
|---|---|---|
| Native HOST | x86_64 HOST | x86_64 HOST |
| Cross | x86_64 HOST | AArch64 TARGET |
| Native TARGET | AArch64 TARGET | AArch64 TARGET |

The same C source is used for all six executables.

The assignment covers:

- reporting runtime system information;
- writing and appending messages to files;
- building applications on different systems;
- transferring cross-compiled executables to Raspberry Pi;
- inspecting ELF - Executable and Linkable Format - files;
- comparing dynamic and static linking.

Implementation details, measurements and observations are documented
in [Report.md](Report.md).

## Application

The application in [src/env-info.c](src/env-info.c) prints:

- hostname;
- current local time;
- operating system name;
- kernel release and version;
- hardware architecture.

Without a filename, it prints the message to the console:

```bash
./builds/env-info-native-host
```

With a filename, it also writes the same message to that file:

```bash
./builds/env-info-native-host logs/example-output.txt
```

If the file already exists and can be opened for reading, the application
prints a warning to `stderr` and appends the message, preserving the
existing contents.

The application returns `0` on success and `1` when it detects an error.

> The existing-file warning use `fopen(..., "r")` check.
> A file that permits writing but denies reading may receive an appended
> message without the warning.

System information comes from `uname()`. It identifies the running kernel
and architecture, rather than the distribution name or exact hardware model.

## Recorded Test Environment

| Parameter | HOST | TARGET |
|---|---|---|
| Device | Legion-Slim7 | Raspberry Pi 5, 1 GB RAM |
| Operating system | EndeavourOS, Arch-based | Raspberry Pi OS Lite, Debian 13 Trixie |
| Architecture | x86_64 | AArch64 / arm64 |
| Hostname | `Legion-Slim7` | `ajax-rpi5` |
| Kernel | `7.2.7-arch1-1` | `6.18.50+rpt-rpi-2712` |
| Native GCC | `16.2.1` | `14.2.0` |

Cross-compilation on HOST uses:

```text
aarch64-linux-gnu-gcc 16.1.0
```

Required tools include Bash, Git, GCC, GNU Binutils, `file`, `ldd`
and standard GNU command-line utilities.

Cross builds require the AArch64 cross compiler and its target libraries.
Static builds additionally require the corresponding static library archives.

## Repository Layout

```text
.
├── src/
│   └── env-info.c       # C application
├── scripts/            # Build and executable-analysis scripts
├── builds/             # Recorded x86_64 and AArch64 executables
├── logs/               # Analysis output and functional-test results
├── Report.md           # Detailed assignment report
└── README.md           # Project overview and usage
```

| Location | Contents |
|---|---|
| [src/env-info.c](src/env-info.c) | Application implementation |
| [scripts/](scripts/) | Six build scripts and six analysis scripts |
| [builds/](builds/) | Dynamic and static executables |
| [logs/](logs/) | Recorded analysis and application output |
| [Report.md](Report.md) | Environment details, comparisons, and conclusions |

**The executables and logs are intentionally tracked in Git.**
They preserve the results used in the report and demonstrate execution
on both systems.

## Build and Analysis Scripts

| Variant | Build on | Run and analyze on | Build script | Analysis script |
|---|---|---|---|---|
| Native HOST dynamic | HOST | HOST | [Build](scripts/build-native-host.sh) | [Analyze](scripts/analyze-build-native-host.sh) |
| Native HOST static | HOST | HOST | [Build](scripts/build-native-host-static.sh) | [Analyze](scripts/analyze-build-native-host-static.sh) |
| Cross dynamic | HOST | TARGET | [Build](scripts/build-cross-host.sh) | [Analyze](scripts/analyze-build-cross-target.sh) |
| Cross static | HOST | TARGET | [Build](scripts/build-cross-host-static.sh) | [Analyze](scripts/analyze-build-cross-target-static.sh) |
| Native TARGET dynamic | TARGET | TARGET | [Build](scripts/build-native-target.sh) | [Analyze](scripts/analyze-build-native-target.sh) |
| Native TARGET static | TARGET | TARGET | [Build](scripts/build-native-target-static.sh) | [Analyze](scripts/analyze-build-native-target-static.sh) |

All builds use:

```text
-std=c11 -Wall -Wextra -Wpedantic -Wshadow -Wformat=2 -O2 -g
```

Static builds additionally use:

```text
-static
```

The analysis scripts run `readelf`, `ldd`, `size`, and `strings`,
together with `file` and `stat`.

## Build and Run

Run the following commands from the project root on the indicated system.

Build scripts write to `builds/`. Analysis scripts display their output
and save it to the corresponding file in `logs/`. Repeating these operations
updates the associated artifacts.

### Native HOST

Run on the x86_64 HOST:

```bash
./scripts/build-native-host.sh
./builds/env-info-native-host
./scripts/analyze-build-native-host.sh
```

For static linking:

```bash
./scripts/build-native-host-static.sh
./builds/env-info-native-host-static
./scripts/analyze-build-native-host-static.sh
```

### Native TARGET

Run directly on Raspberry Pi:

```bash
./scripts/build-native-target.sh
./builds/env-info-native-target
./scripts/analyze-build-native-target.sh
```

For static linking:

```bash
./scripts/build-native-target-static.sh
./builds/env-info-native-target-static
./scripts/analyze-build-native-target-static.sh
```

### Cross-Compilation

Build both variants on HOST:

```bash
./scripts/build-cross-host.sh
./scripts/build-cross-host-static.sh
```

Transfer the resulting files to `builds/` in the TARGET project checkout:

```text
builds/env-info-cross-host
builds/env-info-cross-host-static
```

The committed versions are also included when the repository is cloned
or updated on TARGET.

Run and analyze them on Raspberry Pi:

```bash
./builds/env-info-cross-host
./scripts/analyze-build-cross-target.sh

./builds/env-info-cross-host-static
./scripts/analyze-build-cross-target-static.sh
```

The `cross-host` filename identifies where the executable was built.
Its execution architecture is AArch64.

> Run native TARGET builds and all AArch64 executables on Raspberry Pi.
> Static linking does not make an executable independent of its processor
> architecture.

## Recorded Results

The following values are complete executable file sizes in bytes,
including debugging information and other metadata.

| Configuration | Dynamic executable | Static executable | Analysis logs |
|---|---:|---:|---|
| Native HOST | [21,960](builds/env-info-native-host) | [1,063,832](builds/env-info-native-host-static) | [Dynamic](logs/native-host-analysis.txt) · [Static](logs/native-host-static-analysis.txt) |
| Cross | [76,648](builds/env-info-cross-host) | [993,296](builds/env-info-cross-host-static) | [Dynamic](logs/cross-target-analysis.txt) · [Static](logs/cross-target-static-analysis.txt) |
| Native TARGET | [76,416](builds/env-info-native-target) | [854,280](builds/env-info-native-target-static) | [Dynamic](logs/native-target-analysis.txt) · [Static](logs/native-target-static-analysis.txt) |

The recorded dynamic executables require `libc.so.6` and an
architecture-specific dynamic loader.

The static executables have no `INTERP` segment or `NEEDED` entries.
For these files, `ldd` reports:

```text
not a dynamic executable
```

The static analysis scripts handle this result and continue with the
remaining analysis.

### Functional-Test Evidence

| Configuration | Dynamic file output | Static file output | Dynamic append test |
|---|---|---|---|
| Native HOST | [Output](logs/native-host-create-file.txt) | [Output](logs/native-host-static-create-file.txt) | [Append result](logs/native-host-append-file.txt) |
| Cross on TARGET | [Output](logs/cross-target-create-file.txt) | [Output](logs/cross-target-static-create-file.txt) | [Append result](logs/cross-target-append-file.txt) |
| Native TARGET | [Output](logs/native-target-create-file.txt) | [Output](logs/native-target-static-create-file.txt) | [Append result](logs/native-target-append-file.txt) |

File-output results are stored for all six configurations. Separate
append-test outputs and warning captures were not saved for the static
builds.

See [Report.md](Report.md) for the detailed verification scope,
section-size comparisons and cross-development observations.

## Conclusion

The same C application was built and executed on x86_64 and AArch64,
including cross-compilation on HOST followed by execution on Raspberry Pi.
Static linking removed the recorded shared-library dependencies while
increasing executable size. The results demonstrate the importance of
matching the target architecture and runtime requirements, and of
distinguishing executable file size from code size and runtime memory usage.