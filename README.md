# Utility Scripts

Portable Bourne shell, awk, and Python scripts for installing, building, and
administering software on GNU/Linux, macOS, the BSD systems, illumos, and
Windows (MinGW). Most scripts are small, single-purpose commands built on a
shared portability framework: one script identifies the running platform, and
per-platform data files translate generic package categories into the package
names that each platform's package manager expects.

## Installation

Clone the repository and install the scripts into `~/bin`:

```sh
git clone https://github.com/mgmorey/utility-scripts.git ~/git/utility-scripts
cd ~/git/utility-scripts
./install-scripts
```

`install-scripts` creates symbolic links in `~/bin` for every script, and
installs the shell libraries and data files alongside them. It copies files
instead of linking them on Cygwin and MinGW. The following options select the
installation method, and an optional directory argument replaces `~/bin` as
the target:

| Option | Method |
|---|---|
| `-c` | Copy files. |
| `-i` | Install files with `install(1)`. |
| `-s` | Create symbolic links (the default). |

The other installation scripts are:

| Script | Description |
|---|---|
| `create-symbolic-links` | Links `~/Documents` subdirectories (`bin`, `build`, `git`, `logs`, `src`) into the home directory |
| `install-files` | Installs files by copying, installing, or linking; used by the other installation scripts |
| `install-root-scripts` | Installs `run-python` and `get-python-interpreter` system-wide, in `/usr/local/bin` (or `/usr/sbin` on RHEL, Oracle Linux, and CentOS); run as root from the repository |
| `install-scripts` | Installs the scripts, libraries, and data files into `~/bin` |
| `install-startup-files` | Installs the [startup-files](https://github.com/mgmorey/startup-files) templates and the [emacs-config](https://github.com/mgmorey/emacs-config) repository on a newly installed host |

## Conventions

The scripts share the following conventions:

- **Shell dialect.** Scripts are written for the POSIX shell and start with
  `#!/bin/sh -eu`, so that any failed command or unset parameter stops the
  script. A few scripts require Bash, and five Python programs run through
  `run-python`, which locates a suitable interpreter.
- **Location independence.** Each script locates its sibling scripts,
  libraries, and data files through its own directory, so the scripts work
  both from the repository and from `~/bin`.
- **Usage.** Most scripts accept `-h` and print a usage summary.
- **Parameter scripts.** Scripts named `set-*-parameters` print shell
  commands instead of changing the environment directly. Evaluate their
  output in the calling shell, for example `eval "$(set-parameters)"`.
- **Platform detection.** `get-os-release -x` prints the platform identity as
  shell assignments (`ID`, `ID_LIKE`, `VERSION_ID`, `kernel_name`, and
  `os_family`), which scripts evaluate before choosing platform-specific
  behavior.
- **Package data.** `get-os-configuration` selects the data file for the
  running platform, such as `rhel-9.8.ini` or `macos-15.7.ini`. Each section of
  a data file names a package category, such as `[docker]` or `[curl]`, and
  lists the platform's package names for it. `get-packages CATEGORY` prints
  the package names, and `install-packages` installs them.
- **Privileges.** Scripts that install system packages must run as root.
  Many of them, when run through `sudo`, install their dependencies as root
  and then perform the remaining steps, such as downloading and building
  source code, as the invoking user. The `run_unpriv` function in
  `common-functions.sh` implements this, so build trees remain owned by the
  user.

## General-Purpose Utilities

These scripts have no dependency on a subject area or platform.

### Text Filters

| Script | Description |
|---|---|
| `numeric-list.awk` | Print numbers as a comma-separated list |
| `numeric-range-list.awk` | Print numbers as a comma-separated list of ranges |
| `print-table` | Print a table with lines truncated to `WIDTH` columns |
| `quote-lines` | Filter to quote each line of input |
| `remove-duplicate-lines` | Filter to remove duplicate lines |
| `to-lower` | Translate upper-case letters to lower-case |
| `to-upper` | Translate lower-case letters to upper-case |

### Path and Shell Utilities

| Script | Description |
|---|---|
| `chown-real-user` | Change ownership of files to the invoking (`sudo`) user |
| `compare-versions` | Compare two dotted version strings |
| `get-realpath` | Print resolved, absolute path names (following links) |
| `get-sudo-user-home` | Get home directory of `sudo` user or user |
| `join-directories` | Filter to join directory names into path |
| `make-makefile` | Generate make dependency rules |
| `normalize-path` | Filter to normalize directories in path |
| `remove-from-path` | Remove directories from path parameter |
| `remove-option` | Remove an option from an option list |
| `split-posix-path` | Filter to split POSIX directory path |
| `which-version` | Print full pathname and version of command |
| `which-version.awk` | Parse data file `which-version.txt` |

### Version Control

| Script | Description |
|---|---|
| `git-credential-helper` | Configure Git credential helper |
| `git-log-years` | Print the years in which a file was changed |
| `git-pull-recursive` | Pull every Git repository under `~/git` or `~/Documents/git` |
| `install-git-credential-helper` | Install Git credential helper packages |

## Portability Framework

These scripts form the layer on which the subject-area scripts are built.

### Platform Detection

| Script | Platform | Description |
|---|---|---|
| `get-desktop-name` |  | Print name of desktop environment |
| `get-hypervisor-vendor` |  | Print name of hypervisor vendor |
| `get-os-configuration` |  | Get operating system configuration |
| `get-os-release` |  | Print OS distribution and release information |
| `get-redhat-version` | RHEL | Parse `/etc/redhat-release` for version |

### Environment Parameters

| Script | Platform | Description |
|---|---|---|
| `export-parameters` |  | Print shell commands to export parameters |
| `generate-env` |  | Print parameters for an environment file |
| `generate-proxy-parameters` |  | Generate a list of proxy parameters |
| `get-path-parameters` |  | Output path parameter names and values |
| `set-askpass-parameters` |  | Print shell commands to set askpass parameters |
| `set-bsd-parameters` | BSD | Print shell commands to set BSD parameters |
| `set-display-parameters` |  | Print shell commands to set display parameters |
| `set-macos-parameters` | macOS | Print shell commands to set macOS parameters |
| `set-oss-parameters` |  | Print shell commands to set OSS parameters |
| `set-parameters` |  | Print shell commands to set parameters |
| `set-profile-parameters` |  | Print shell commands to set profile parameters |
| `set-proxy-parameters` |  | Print shell commands to set proxy parameters |
| `set-tls-parameters` |  | Print shell commands to set TLS parameters |

### Package Management

| Script | Platform | Description |
|---|---|---|
| `brew` |  | Run Homebrew with Artifactory settings scoped to this process |
| `brew-list-keg-only` |  | Print list of Homebrew packages which are keg-only |
| `edit-software-properties` | Debian | Invoke software properties dialog |
| `get-configuration` |  | Get configuration (wrapper for Python script) |
| `get-configuration.py` |  | Print application configuration parameters |
| `get-development-pattern` |  | Get essential build/development pattern |
| `get-install-command` |  | Get package manager install command |
| `get-installed-packages` |  | Get a list of installed packages |
| `get-package-filenames` |  | Print filenames associated with package |
| `get-package-install-options` |  | Get package installation options |
| `get-package-managers` |  | Get names of package manager utilities |
| `get-package-uninstall-options` |  | Get package uninstallation options |
| `get-packages` |  | Get package names |
| `get-pattern-install-command` |  | Get pattern installation command |
| `get-uninstall-command` |  | Get package manager uninstall command |
| `get-uninstalled-packages` |  | Filter installed packages from list |
| `install-epel` | RHEL | Install Extra Packages for Enterprise Linux |
| `install-homebrew` |  | Install the Homebrew package manager |
| `install-metapackages` |  | Install packages for given metapackages |
| `install-opencsw` | Solaris/illumos | Install OpenCSW package manager `pkgutil` |
| `install-package-managers` |  | Install non-native package managers |
| `install-packages` |  | Install packages |
| `install-pkgsrc` |  | Install pkgsrc portable package build system |
| `set-publisher-sfe` | Solaris/illumos | Add publisher SFE on OpenIndiana |
| `set-publisher-solarisstudio` | Solaris/illumos | Add publisher SolarisStudio on Oracle Solaris |
| `uninstall-packages` |  | Uninstall packages |
| `upgrade-pkgsrc-for-illumos` | Solaris/illumos | Upgrade pkgsrc portable package build system |

## Subject Areas

### Build Toolchains

#### Source Builds

Each script downloads a source release and configures it for installation,
typically under `/opt`, where `set-oss-parameters` adds it to the search
paths.

| Script | Description |
|---|---|
| `configure-binutils` | Download and configure GNU Binutils |
| `configure-cppcheck` | Download and configure Cppcheck |
| `configure-ctags` | Download and configure Universal Ctags |
| `configure-curl` | Download and configure cURL |
| `configure-dejagnu` | Download and configure GNU DejaGnu |
| `configure-dmalloc` | Download and configure Dmalloc |
| `configure-doxygen` | Download and configure Doxygen |
| `configure-emacs` | Download and configure GNU Emacs |
| `configure-gawk` | Download and configure the GNU Awk utility |
| `configure-gdb` | Download and configure the GNU Debugger |
| `configure-giflib` | Download and configure giflib |
| `configure-git` | Download and configure Git |
| `configure-glibc` | Download and configure the GNU C library |
| `configure-gmp` | Download and configure the GNU MP Bignum library |
| `configure-gnuplot` | Download and configure Gnuplot |
| `configure-gnutls` | Download and configure the GNU TLS library |
| `configure-libidn2` | Download and configure the GNU IDN Library |
| `configure-libpsl` | Download and configure the Public Suffix List Library |
| `configure-libtasn1` | Download and configure the GNU ASN.1 Library |
| `configure-libtool` | Download and configure GNU Libtool |
| `configure-libunistring` | Download and configure the GNU Unistring Library |
| `configure-make` | Download and configure GNU Make |
| `configure-mpc` | Download and configure the GNU MPC library |
| `configure-mpfr` | Download and configure the GNU MPFR library |
| `configure-nasm` | Download and configure NASM |
| `configure-nettle` | Download and configure Nettle |
| `configure-openssl` | Download and configure OpenSSL |
| `configure-p11-kit` | Download and configure P11-Kit |
| `configure-qemu` | Download and configure QEMU |
| `configure-readline` | Download and configure GNU Readline |
| `configure-texinfo` | Download and configure GNU Texinfo |
| `configure-unbound` | Download and configure Unbound |
| `configure-xerces` | Download and configure Xerces |

#### Build Dependencies

| Script | Platform | Description |
|---|---|---|
| `create-link-for-libgcc` |  | Create symbolic link for libgcc |
| `get-emacs-build-packages` |  | Get list of Emacs build dependencies |
| `get-emacs-nox-build-packages` |  | Get list of Emacs build dependencies without X11 |
| `get-emacs-x11-build-packages` |  | Get list of Emacs build dependencies with X11 |
| `get-gcc-build-packages` |  | Get list of GCC build dependencies |
| `get-git-build-packages` |  | Get list of Git build dependencies |
| `get-nushell-build-packages` |  | Get list of Nushell build packages |
| `install-build-deps` |  | Install build dependencies |
| `install-emacs-build-deps` |  | Install GNU Emacs build dependencies |
| `install-emacs-nox-build-deps` |  | Install GNU Emacs build dependencies without X11 |
| `install-emacs-x11-build-deps` |  | Install GNU Emacs build dependencies with X11 |
| `install-git-build-deps` |  | Install Git build dependencies |
| `install-macos-sdk-headers` | macOS | Install macOS SDK headers for macOS 10.14 |
| `install-nushell-build-deps` |  | Install Nushell build dependencies |
| `install-solarisstudio` | Solaris/illumos | Install Oracle Developer Studio |

#### Compiler Detection

| Script | Description |
|---|---|
| `get-cc-flavor` | Print the vendor flavor of a C compiler |
| `get-clang-flavor` | Print the vendor flavor of a Clang compiler |
| `get-compiler-version` | Print the full version of a compiler |
| `get-llvm-flavor` | Print the vendor flavor of an LLVM tool |
| `get-llvm-version` | Print the LLVM version of a tool |
| `is-clang` | Test whether a compiler is Clang |
| `is-gcc` | Test whether a compiler is GCC |

### Language Environments

#### Common Lisp

| Script | Description |
|---|---|
| `configure-sbcl` | Download and configure Steel Bank Common Lisp |
| `install-quicklisp` | Install Quicklisp for SBCL |
| `install-sbcl` | Install SBCL |

#### Crystal

| Script | Description |
|---|---|
| `get-crystal-build-packages` | Get list of Crystal build packages |
| `get-crystal-compiler-packages` | Get list of Crystal compiler packages |
| `get-crystal-runtime-packages` | Get list of Crystal runtime packages |
| `install-crystal` | Install Crystal programming language |

#### Node.js

| Script | Description |
|---|---|
| `get-nodejs-packages` | Get Node.js package names |
| `install-angular-cli` | Install Angular CLI |
| `install-nodejs` | Install Node.js |

#### Python

| Script | Platform | Description |
|---|---|---|
| `check-python` |  | Report a Python interpreter and test its version |
| `clean-up-app-caches` |  | Clean Python caches |
| `clean-up-pipenv` |  | Remove the Pipenv virtual environment of the current project |
| `clean-up-python` |  | Clean up downloaded Python packages |
| `clean-up-virtualenv` |  | Remove Python virtual environments |
| `configure-python` |  | Download and configure the Python interpreter |
| `get-python-development-packages` |  | Get list of Python development packages |
| `get-python-interpreter` |  | Get name of Python interpreter |
| `get-python3-packages` |  | Get list of Python 3 packages |
| `install-pip` |  | Install pip |
| `install-pipenv` |  | Install Python Environment Manager |
| `install-pyenv` |  | Install Python Version Manager |
| `install-pyenv-on-macos` | macOS | Install pyenv on macOS with SDK settings |
| `install-python-build-deps` |  | Install Python build dependencies |
| `install-python-development-tools` |  | Install Python development tools |
| `install-python-development-utilities` |  | Install Python development utilities |
| `install-python3` |  | Install Python 3 |
| `install-virtualenv` |  | Install Python virtualenv |
| `pip-install` |  | Install PyPI packages with pip |
| `pipenv-lock` |  | Generate package requirement lists using Pipenv |
| `refresh-virtualenv` |  | Install virtual environment dependencies |
| `run-python` |  | Run Python script |
| `test-python-version` |  | Test Python interpreter version string |
| `uninstall-pipware` |  | Uninstall Python packages installed with pip |
| `upgrade-pyenv` |  | Upgrade pyenv via `git pull` |

#### Rust

| Script | Description |
|---|---|
| `install-rustup` | Install rustup from rust-lang.org |

### Containers and Orchestration

| Script | Description |
|---|---|
| `build-images` | Build OCI container images |
| `clean-up-all-docker` | Clean up all Docker artifacts |
| `clean-up-docker` | Clean up dangling Docker artifacts |
| `configure-docker-proxy` | Configure Docker proxy settings |
| `create-docker-bridge` | Create Docker bridge network |
| `create-docker-volume-devices` | Create Docker volume devices |
| `docker-exec-bash` | Run Bash in a container |
| `generate-docker-compose` | Print configuration file `docker-compose.yaml` |
| `get-all-capabilities` | Get list of all Linux capabilities |
| `get-docker-ce-dependencies` | List Docker CE dependency package names |
| `get-docker-ce-packages` | List Docker CE package names |
| `get-docker-group` | Get group ID associated with Docker |
| `get-docker-packages` | Get Docker package names |
| `get-installed-docker-packages` | Get installed Docker package names |
| `get-kubernetes-dependencies` | List Kubernetes dependency package names |
| `get-kubernetes-packages` | List Kubernetes package names |
| `grep-docker-package` | Filter for Docker package names |
| `install-docker` | Install Docker OS-level virtualization system |
| `install-docker-ce` | Install Docker CE OS-level virtualization system |
| `install-docker-compose` | Install Docker Compose from GitHub |
| `install-docker-compose-command-completion` | Install Docker Compose command completion |
| `install-docker-credential-secretservice` | Install Docker credential secretservice |
| `install-hadolint` | Install Hadolint |
| `install-kind` | Install kind (Kubernetes in Docker) |
| `install-kubernetes` | Install Kubernetes container orchestration system |
| `install-minikube` | Install Minikube |
| `remove-dangling-docker-images` | Clean up Docker images |
| `remove-docker-volume-devices` | Remove Docker volume devices |
| `reset-podman-containers` | Delete all rootless Podman container storage |
| `run-image` | Run container image |
| `uninstall-docker` | Uninstall Docker OS-level virtualization system |
| `uninstall-kubernetes` | Uninstall Kubernetes container orchestration system |

### Databases and ODBC

| Script | Description |
|---|---|
| `create-oracle-databases` | Create Oracle databases |
| `docker-exec-ibm-db2-client` | Run IBM Db2 client in container |
| `docker-exec-oracle-client` | Run Oracle client in container |
| `docker-exec-sap-hana-client` | Run SAP HANA client in container |
| `docker-run-database-client` | Invoke SQL DBMS command line client |
| `docker-run-database-server` | Run SQL DBMS server |
| `docker-run-ibm-db2-server` | Run IBM Db2 server in container |
| `docker-run-oracle-server` | Run Oracle server in container |
| `docker-run-sap-hana-server` | Run SAP HANA server in container |
| `get-db2-capabilities` | Get list of IBM Db2 Linux capabilities |
| `get-installed-mysql-package` | Get installed database package name |
| `get-mysql-errors` | Get MySQL server log contents |
| `get-mysql-packages` | Get list of MySQL packages |
| `get-mysql-root-password` | Extract MySQL root password from logs |
| `get-odbc-drivers` | Describe installed ODBC drivers |
| `get-oracle-client-packages` | Get list of Oracle client packages |
| `get-pgadmin4-packages` | Get list of pgAdmin 4 packages |
| `get-postgresql-packages` | Get list of PostgreSQL packages |
| `grep-mysql-package` | Search for MySQL database package names |
| `import-into-sap-hana` | Import data into SAP HANA server |
| `install-mssql-odbc` | Install Microsoft SQL Server ODBC packages |
| `install-mysql` | Install MySQL database packages |
| `install-mysql-odbc` | Install MySQL ODBC packages |
| `install-odbc` | Install ODBC driver manager |
| `install-odbc-development-tools` | Install ODBC development tools |
| `install-oracle-client` | Install Oracle client packages |
| `install-oracle-odbc` | Install Oracle ODBC packages |
| `install-pgadmin4` | Install PostgreSQL administration tool |
| `install-pgdg` | Install PostgreSQL repository |
| `install-postgresql` | Install PostgreSQL database packages |
| `install-postgresql-odbc` | Install PostgreSQL ODBC packages |
| `install-presto-client` | Install Presto client packages |
| `install-presto-server` | Install Presto server packages |
| `install-sqlite` | Install SQLite |
| `run-sql` | Invoke SQL DBMS command line client |
| `start-oracle-databases` | Start Oracle databases |
| `stop-oracle-databases` | Stop Oracle databases |
| `test-odbc-driver` | Test ODBC driver |
| `uninstall-mysql` | Uninstall MySQL packages |
| `uninstall-mysql-odbc` | Uninstall MySQL ODBC packages |

### System Administration

| Script | Platform | Description |
|---|---|---|
| `attach-rhel` | RHEL | Attach via Red Hat Subscription Manager |
| `clean-up-kernel-packages` |  | Uninstall all but current kernel packages |
| `clean-up-zfs-snapshots` | Solaris/illumos | Clean up ZFS snapshots on Solaris |
| `clear-software-update-catalog` | macOS | Clear macOS software update catalog |
| `configure-hyper-v-guest` | Hyper-V | Configure Hyper-V guest resolution |
| `configure-tls` |  | Configure Git and pip to use a PEM CA certificate file |
| `enable-nfs` |  | Export `/home/nfsshare` and enable the NFS server |
| `enable-sudo` |  | Install `sudo` and add supplemental group `sudo` |
| `fix-libcuda` | WSL | Repair `libcuda` symbolic links under WSL |
| `fstab-format` |  | Align columns of file system entries in `/etc/fstab` |
| `fstab-format.awk` |  | Align columns of file system entries in `/etc/fstab` |
| `get-nameserver` |  | Return nameserver value from file argument |
| `get-nameserver-from-resolver` |  | Return nameserver value from resolver |
| `install-tls-ca-certificate` |  | Install a CA certificate into the system trust store |
| `install-virtualbox-guest-additions` | VirtualBox | Install Oracle VirtualBox Guest Additions |
| `populate-sub-ids` |  | Add subordinate UID and GID ranges for rootless containers |
| `register-rhel` | RHEL | Register via Red Hat Subscription Manager |
| `rehash-tls-ca-certificates` |  | Rehash a directory of CA certificates |
| `renew-dhcp-lease` |  | Renew the DHCP lease |
| `set-up-tunnel` |  | Set up IP forwarding tunnel using iptables |
| `show-software-update-defaults` | macOS | Show macOS software update defaults |
| `subscribe-rhel` | RHEL | Subscribe via Red Hat Subscription Manager |

### Desktop and Workstation Software

| Script | Platform | Description |
|---|---|---|
| `askpass` |  | Configure or query askpass helper |
| `get-askpass-helper` |  | Print the askpass helper path for a desktop environment |
| `get-askpass-package` |  | Get name of package with askpass helper |
| `install-adobe-source-code-pro` |  | Install Adobe Source Code Pro fonts |
| `install-ansible` |  | Install Ansible with pipx |
| `install-askpass-helper` |  | Install askpass helper package |
| `install-google-chrome` |  | Install Google Chrome |
| `install-vagrant` | RHEL | Install Vagrant from the HashiCorp repository |
| `install-xrdp` | RHEL | Install and enable the xrdp remote desktop server |

## Single-Purpose Tools

### Flask Application Lifecycle

These scripts install, run, and manage a Python Flask application served by
uWSGI, together with its database. They rely on the `restapi-functions.sh`
and `restapi-parameters.sh` libraries.

| Script | Description |
|---|---|
| `build-uwsgi` | Download and build uWSGI from GitHub source |
| `configure-uwsgi` | Download and configure uWSGI |
| `create-app-database` | Create application database |
| `docker-app` | Wrap Docker CLI commands for Python Flask application |
| `drop-app-database` | Drop application database |
| `get-app-status` | Print last few lines of service log file |
| `install-app` | Install Python Flask application uWSGI service |
| `manage-app-database` | Create or drop application database |
| `restart-app` | Restart Python Flask application uWSGI service |
| `run-app` | Run Python Flask application |
| `start-app` | Start Python Flask application uWSGI service |
| `stop-app` | Stop Python Flask application uWSGI service |
| `uninstall-app` | Uninstall Python Flask application uWSGI service |

### Special-Purpose Projects

| Script | Description |
|---|---|
| `create-hercules-dasd` | Create Hercules DASD container files |
| `get-lilith-build-packages` | Get list of Lilith OS build packages |
| `get-lilith-os-packages` | Get list of Lilith OS packages |
| `install-lilith-build-deps` | Install Lilith OS build dependencies |
| `make-lilith` | Invoke make to build Lilith OS |
| `set-up-hercules` | Install and configure Hercules emulator |

## Shell Libraries

These files are sourced by other scripts and are not run directly.

| Library | Description |
|---|---|
| `common-functions.sh` | Define commonly used shell functions |
| `config-functions.sh` | Define configuration shell functions |
| `ibm-db2-config.sh` | Define IBM Db2 shell parameters |
| `oracle-config.sh` | Define Oracle shell parameters |
| `oracle-library.sh` | Define Oracle shell functions |
| `parameter-functions.sh` | Define parameter shell functions |
| `restapi-functions.sh` | Define Python RESTful API shell functions |
| `restapi-parameters.sh` | Define Python RESTful API shell parameters |
| `sap-hana-config.sh` | Define SAP HANA shell parameters |
| `utility-functions.sh` | Define commonly used shell functions |

## Data Files

### Platform Package Data

Each `.ini` file maps package categories to package names for one platform
release, named `<ID>-<VERSION_ID>.ini` after the values that `get-os-release`
reports. The repository contains 101 data files:

| Platform | Releases |
|---|---|
| AlmaLinux | 8.5 through 10.0 |
| Amazon Linux | 2023 |
| CentOS | 7 and 8 |
| Debian | 10 through 13 |
| Fedora | 32 through 42 |
| FreeBSD | 11.3 through 13.1 |
| illumos | 2020.04 |
| macOS | 10.14 through 26.0 |
| NetBSD | 8.2 through 9.1 |
| openSUSE Leap and Tumbleweed | Leap 15.2 through 15.6, and Tumbleweed |
| Oracle Linux | 8.4 through 10.0 |
| Raspbian | 10 |
| Red Hat Enterprise Linux | 7.9 through 9.8 |
| Rocky Linux | 8.4 and 8.5 |
| Ubuntu | 18.04 through 24.04 |
| Windows (MinGW-w64) | 10 |

### Command Version Data

`which-version.txt` lists, for each supported command, the option that prints
its version and the `sed` expression that extracts the version number.
`which-version` uses it through `which-version.awk`.

## Tested Platforms

The project has been tested on the following platforms. The platform package
data covers additional, later releases, which have not all been recorded
here.

| OS Family | Distribution | OS Version (OS Ports) |
|---|---|---|
| GNU/Linux | Debian | 10 (amd64, s390x) |
| GNU/Linux | Debian | 11 (amd64) |
| GNU/Linux | Fedora | 35 (x86_64) |
| GNU/Linux | openSUSE Leap | 15.2 (x86_64) |
| GNU/Linux | openSUSE Leap | 15.3 (x86_64) |
| GNU/Linux | Raspbian | 10 (armhf) |
| GNU/Linux | Red Hat (RHEL) | 7.9 (x86_64) |
| GNU/Linux | Red Hat (RHEL) | 8.5 (x86_64) |
| GNU/Linux | Rocky | 8.5 (x86_64) |
| GNU/Linux | Ubuntu | 20.04 LTS (x86_64) |
| GNU/Linux | Ubuntu | 22.04 LTS (arm64, x86_64) |
| Unix | Apple macOS | 12.1 (arm64) |
| Unix | FreeBSD | 12.2 (amd64) |
| Unix | FreeBSD | 13.0 (amd64) |
| Unix | NetBSD | 9.1 (amd64) |

The OS ports have been tested on the following processors:

| CPU ISA | CPU Vendor and Microarchitecture | 32-Bit | 64-Bit |
|---|---|---|---|
| ARMv8.4-A | Apple M1 | N/A | arm64 |
| ARMv8-A | ARM Cortex-A53 | armhf | arm64 |
| x86-64 | Intel Silvermont, Kaby Lake, and Coffee Lake | N/A | amd64/x86_64 |
| z/Architecture | IBM z900 via Hercules emulator | N/A | s390x |

## License

This project is licensed under the GNU General Public License, version 3. See
`LICENSE` for details.
