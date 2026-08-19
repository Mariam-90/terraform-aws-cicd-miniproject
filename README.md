# Terraform + Flask CI/CD Mini Project

A Flask REST API, provisioned on AWS EC2 with modular Terraform, automatically tested on every pull request and automatically deployed to production on every merge to `main` via GitHub Actions.

**Live flow in one sentence:** push code → GitHub Actions lints/scans/tests it → on merge to `main`, GitHub Actions SSHes into the EC2 instance, pulls the new code, reinstalls dependencies, and restarts the app — all without anyone touching the AWS Console.

---

## Architecture

```
GitHub repo
├── terraform/                 Infrastructure as Code (provisions AWS)
│   ├── main.tf                 wires the 3 modules together
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars        (gitignored — your real values)
│   └── modules/
│       ├── vpc/                 VPC, subnet, internet gateway, route table
│       ├── security_group/      firewall rules (SSH, HTTP, HTTPS, app port)
│       └── ec2/                 the EC2 instance + first-boot bootstrap script
│
├── app/                        Flask REST API (Todo API)
│   ├── main.py
│   ├── business_logic.py
│   ├── requirements.txt
│   └── tests/
│
└── .github/workflows/
    ├── test.yml                 runs on every pull request
    └── deploy.yml                runs on every push to main
```

### Request flow once deployed
```
Internet → EC2 Security Group (port 5000) → gunicorn (3 workers) → Flask app (main:app)
```
gunicorn is managed by a systemd service (`flask-app.service`) so it survives reboots and restarts automatically if it crashes.

---

## Prerequisites

- AWS account with an IAM user that has programmatic access (access key + secret)
- [Terraform](https://developer.hashicorp.com/terraform/install) v1.5+
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), configured via `aws configure`
- Python 3.11+ (for running the app locally)
- An existing EC2 key pair in your target AWS region (for SSH access)
- Git and a GitHub account

---

## 1. Provision the infrastructure

```bash
cd terraform/
```

Create `terraform.tfvars` (this file is gitignored — never commit it):
```hcl
ami_id           = "ami-xxxxxxxxxxxxxxxxx"   # current Ubuntu 22.04 AMI for your region — see note below
my_ip_cidr       = "YOUR.PUBLIC.IP.HERE/32"  # curl ifconfig.me, then append /32
key_name         = "your-ec2-key-pair-name"  # must already exist in AWS, same region
github_repo_url  = "https://github.com/your-username/your-repo.git"

# optional overrides — sensible defaults exist for all of these
# region             = "us-east-1"
# vpc_cidr           = "10.0.0.0/16"
# project_name       = "terraform-vpc"
# cidr_public_subnet = "10.0.1.0/24"
# environment        = "dev"
```

**Finding a current AMI ID** — AMI IDs are region-specific and change over time, don't reuse an old one from a tutorial:
```bash
aws ec2 describe-images \
  --owners 099720109477 \
  --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" "Name=virtualization-type,Values=hvm" \
  --query 'sort_by(Images, &CreationDate)[-1].[ImageId,Name]' \
  --output table
```

Then:
```bash
terraform init
terraform plan     # review before applying
terraform apply
```

After it finishes, get the public IP:
```bash
terraform output app_public_ip
```

Give the instance 1–2 minutes after creation — its first-boot script (`user_data.sh`) needs time to install Python, clone the repo, build the virtualenv, and start the app before it's actually reachable.

---

## 2. What happens automatically on first boot

`modules/ec2/user_data.sh` runs once, the very first time the instance starts:

1. Updates the system and installs Python 3.11, pip, and git.
2. Creates a dedicated low-privilege user, `appuser` (the app never runs as root).
3. Clones this repository into `/home/appuser/app`.
4. Creates a Python virtualenv at `/home/appuser/app/venv`.
5. Installs dependencies from `app/app/requirements.txt` (see the folder-nesting note below).
6. Installs gunicorn (a production WSGI server — Flask's built-in dev server isn't meant for real traffic).
7. Writes a systemd unit file (`/etc/systemd/system/flask-app.service`) so the app restarts automatically on crash or reboot.
8. Enables and starts the service.

**Important, non-obvious detail:** because `user_data.sh` clones the *entire* repository (not just the `app/` folder) into `/home/appuser/app`, the actual Flask code ends up nested one level deeper, at `/home/appuser/app/app/`. Every path in the systemd service, the deploy script, and this README accounts for that nesting — if you restructure the repo later, update those paths too.

**Also important:** `user_data.sh` only ever runs on first boot. If you edit it after an instance already exists, nothing happens to that running instance — Terraform won't retroactively re-run it. To pick up changes, force a replace:
```bash
terraform apply -replace="module.ec2.aws_instance.app"
```
(this gives the instance a new public IP — update the `EC2_HOST` GitHub secret afterward)

---

## 3. Run the app locally

```bash
cd app/
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
python3 main.py
```
Visit `http://localhost:5000`.

**macOS note:** port 5000 is often already taken by Control Center's AirPlay Receiver feature. If you get "Address already in use," either disable it (System Settings → General → AirDrop & Handoff → turn off AirPlay Receiver) or run the app on a different local port for testing.

### Endpoints
| Method | Path | Description |
|---|---|---|
| GET | `/` | Welcome page |
| GET | `/health` | Health check |
| GET | `/api/todos` | List all todos |
| POST | `/api/todos` | Create a todo |
| GET | `/api/todos/{id}` | Get one todo |
| PUT | `/api/todos/{id}` | Update a todo |
| DELETE | `/api/todos/{id}` | Delete a todo |

### Run the tests
```bash
pytest tests/ --cov=. --cov-report=term-missing --cov-fail-under=80
```

---

## 4. CI/CD pipeline

### `test.yml` — runs on every pull request into `main`
1. Checks out the code and sets up Python 3.11.
2. Installs dependencies (`requirements.txt` + `flake8`, `bandit`, `pytest-cov`).
3. **Lints** with flake8 — style/syntax issues.
4. **Security-scans** with bandit — flags risky patterns like hardcoded secrets or unsafe `eval()`/`subprocess` usage.
5. **Runs tests with coverage** — fails the whole job if total coverage drops below 80% (`--cov-fail-under=80`).

A PR can't be safely merged unless all of these pass.

### `deploy.yml` — runs on every push to `main`
1. Re-runs the same lint/security/test steps (never deploy code that hasn't just been verified).
2. SSHes into the EC2 instance (via `appleboy/ssh-action`) as `appuser`, pulls the latest code, reinstalls dependencies, and restarts `flask-app.service`.
3. Runs a health check (`curl -f .../health`) against the live instance — fails the job if the app doesn't come back up cleanly.

### Required GitHub Secrets
Repo → Settings → Secrets and variables → Actions:

| Secret | Value |
|---|---|
| `EC2_HOST` | The EC2 instance's public IP (`terraform output app_public_ip`) — **must be updated any time the instance is replaced** |
| `EC2_USER` | `ubuntu` |
| `EC2_SSH_PRIVATE_KEY` | Contents of your `.pem` key file |

---

## 5. Security decisions and trade-offs

- **SSH access** is split into two rules: one restricted to the developer's own IP (`my_ip_cidr`) for manual access, and a second rule open to `0.0.0.0/0` specifically so GitHub Actions' hosted runners (whose IPs are not fixed or predictable) can reach the instance to deploy. This is a deliberate, documented trade-off for a student project — in a production environment, the CI rule would instead be scoped to GitHub's published runner IP ranges (refreshed per deployment), or replaced entirely with AWS Systems Manager Session Manager, which avoids exposing port 22 to the internet at all.
- **The app runs as a dedicated non-root user** (`appuser`), not as `ubuntu` or `root` — limiting blast radius if the app itself is ever compromised.
- **`.gitignore`** excludes `*.tfstate`, `*.tfvars` (except the tracked `.example`), `.terraform/`, `*.pem`, and `.env` — none of these should ever be committed, since they can contain resource IDs, credentials, or infrastructure state.
- **No AWS or SSH credentials are hardcoded anywhere in the codebase** — everything sensitive is injected via GitHub Secrets at workflow runtime.

---

## 6. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `terraform apply` fails with `InvalidAMIID.Malformed` | `ami_id` isn't a real AMI ID (e.g. a name was pasted instead) | Look up the current AMI ID with the `describe-images` command above |
| `Your requested instance type is not supported in your requested Availability Zone` | AWS auto-assigned an AZ that doesn't support `t3.micro` for this account | Pin `availability_zone` explicitly in the VPC module's subnet (e.g. `us-east-1a`) |
| SSH `Permission denied` connecting as `ubuntu` to `/home/appuser` | `appuser`'s home directory is `700` — only `appuser` can enter it | Use `sudo` (or `sudo -u appuser`) for anything touching `/home/appuser`, including in `deploy.yml` |
| Deploy fails with `pip install requirements.txt` file-not-found | Forgot the nested `app/app/` folder structure, or forgot `-r` flag | Ensure the deploy script does `cd app` before `pip install -r requirements.txt`, from inside `/home/appuser/app` |
| `Failed to restart flask-app.service: Unit not found` | The running instance booted from an older/different version of `user_data.sh` | Force instance replacement: `terraform apply -replace="module.ec2.aws_instance.app"` |
| Deploy workflow: `dial tcp ***:22: i/o timeout` | `EC2_HOST` secret is stale after instance replacement, or security group blocks GitHub's runner IP | Update `EC2_HOST`, and confirm SSH (22) is reachable from `0.0.0.0/0` or GitHub's runner ranges |
| flake8 fails with `W293 blank line contains whitespace` | Trailing whitespace on an otherwise blank line | `sed -i '' -E 's/[[:space:]]+$//' path/to/file.py` (use `[[:space:]]`, not `\t` — BSD/macOS `sed` doesn't interpret `\t` as tab and will corrupt words ending in the letter "t") |
| GitHub Actions never runs on a new PR | Workflow file only exists on the feature branch, not on `main` yet | GitHub requires `pull_request`-triggered workflows to already exist on the base branch — merge the workflow file to `main` first, then open a fresh PR to see it trigger |

---

## 7. Tearing it down

To avoid ongoing AWS charges when you're done:
```bash
cd terraform/
terraform destroy
```
Also double check in the AWS Console that nothing was created manually outside of Terraform (e.g. security group rules added directly in the console) — `terraform destroy` only removes resources it's actually tracking in state.