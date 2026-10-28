# Assignment 2 — Dockerized Diagnostic CLI

A Bash diagnostic tool packaged as a lightweight Docker image. It shows Linux system information, checks network hosts and reports disk usage, and it can be run with plain Docker or with Docker Compose.

## Project structure

```
assignment-2/
├── README.md
├── app/
│   ├── diagnostic.sh      # The CLI
│   └── health-check.sh    # Container health check
├── Dockerfile
├── compose.yaml
├── .dockerignore
├── test.sh                # Docker image test suite
└── grade.sh               # Instructor grading script
```

## Requirements

- Linux (tested on Ubuntu 26.04 under WSL2)
- Docker with the Compose plugin (`docker compose`)

## Setup

```bash
git clone https://github.com/Wonderfullymade01/assignment-2.git
cd assignment-2
chmod +x grade.sh test.sh app/*.sh
docker build -t diagnostic-tool .
```

## Usage

### Commands

| Command | Description |
|---|---|
| `system` | Show hostname, user, date/time, OS, kernel, uptime, CPU and memory |
| `network <host>` | Resolve the host and ping it |
| `disk [path]` | Show disk usage (default path: `/`) |
| `help` | Show commands and usage |

### With Docker

```bash
docker run --rm diagnostic-tool help
docker run --rm diagnostic-tool system
docker run --rm diagnostic-tool disk
docker run --rm diagnostic-tool network google.com
```

Running the image with no command shows the help text.

### With Docker Compose

```bash
docker compose run --rm diagnostic system
docker compose run --rm diagnostic network google.com
```

### Without Docker

```bash
./app/diagnostic.sh system
```

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Success |
| 1 | Operational/runtime failure (e.g. host cannot be resolved or does not reply) |
| 2 | Invalid command or input (e.g. unknown command, missing host, bad path) |

## Docker image

- **Base image:** `alpine:3.20` (final image about 15 MB)
- **Packages:** only `bash` is installed; `ping`, `df`, `awk`, `hostname` and `getent` come with Alpine
- **Non-root:** the container runs as `appuser`
- **Entrypoint:** `diagnostic`, with `help` as the default command
- **Health check:** `app/health-check.sh` checks that the required tools exist and that `diagnostic help` works
- **.dockerignore:** excludes `.git`, logs, temporary files and files not needed in the image

## Testing

Run the test suite (builds the image, then runs 11 tests covering help, system, disk, invalid commands and the health check):

```bash
./test.sh
```

Run the grader:

```bash
./grade.sh
```

## Assumptions

- Containers use UTC time, so the date/time in `system` may differ from the host's local time.
- Some networks block ping (ICMP), so `network` may return exit code 1 even if the host is up.
- The `system` command reads uptime and memory from `/proc`, so it needs a Linux kernel (works in Docker on Linux, WSL2 and Docker Desktop).

## Git workflow

Development was done on the `feature/docker-cli` branch and merged into `main`.
