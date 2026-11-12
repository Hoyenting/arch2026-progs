# Development setup

The submission repository is https://github.com/Hoyenting/arch2026-progs.
It is a full clone of the instructor repository, with `main` as the default
branch and `upstream` pointing to `sysprog21/arch2026-progs`.
The original Homework 1 repository remains separate.

## Apple Silicon environment

Before running make or committing from a new terminal, run:

```sh
export PATH="$HOME/.local/opt/xpack-riscv-none-elf-gcc-15.2.0-1/bin:/opt/homebrew/bin:$HOME/.local/bin:$PATH"
```

This selects the following installed tools:

- xPack RISC-V GCC 15.2.0-1, downloaded from its official GitHub release.
  The archive was checked against the published SHA-256 checksum.
- Homebrew Bash 5.3.20, Cppcheck 2.22.0, Aspell and the device tree compiler.
- clang-format 20.1.8, installed with uv, with a `clang-format-20` alias.

The Homebrew `riscv64-elf-` toolchain was tried first. Its linker defaults
to ELF64 and fails the framework's RV32 link probe. Use xPack instead;
there is no need to change the instructor's build rules.

## Build and checks

```sh
make
make history
make repo
make sanitize
make test
```

The initial source files are the instructor's stubs. Building them does not
mean that the assignment tests pass. Correctness and performance results
must be measured after each implementation is added.

The framework installs its own Git hooks and enables GitHub Actions.
Commits must pass those hooks and carry their generated Change-Id.
Keep commits focused on actual changes and do not bypass verification.
Use rebase for upstream updates, followed by the documented chain repair.

## Implementation order

Read each contract header before changing its implementation. Start with
simple, explainable C code, then write the corresponding RV32I assembly.
Only add optimizations needed to meet the instruction and size budgets.
Record measurements rather than claiming unmeasured improvements.

Rubik will be ported from the Homework 1 code as a callable solver, with
input validation, shortest solutions and bounded output. The Ripes input,
printing and environment calls are replaced by the function contract.
The other programs are binary GCD, BFloat16 and fixed-point arithmetic.
