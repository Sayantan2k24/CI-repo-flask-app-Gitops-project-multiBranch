# CI Repo for GitOps Multi-Branch Project (Flask App)

This repository contains the **CI pipeline** for automating Docker image builds and pushing them to DockerHub, triggering GitOps-based deployment using **Argo CD**.

📦 **CD Repository** (used by Argo CD):
👉 [CD-repo-flask-app-Gitops-project-multiBranch](https://github.com/Sayantan2k24/CD-repo-flask-app-Gitops-project-multiBranch.git)

---

## 🔧 How to Use this Project

### 1. Clone the Repository

```bash
git clone https://github.com/Sayantan2k24/CI-repo-flask-app-Gitops-project-multiBranch.git
cd CI-repo-flask-app-Gitops-project-multiBranch/
```

---

## 🚀 Step 1: Provision Jenkins Server Using Terraform

Navigate to the Jenkins infrastructure setup directory:

```bash
cd infrastructure/jenkins_server/
```

### 🔐 Generate SSH Keys

```bash
cd ssh-keys/
ssh-keygen -t rsa -N "" -f id_rsa
chmod 400 id_rsa
```

### ⚙️ Run Terraform Commands

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply --auto-approve
```

### ✅ Jenkins Setup

Once provisioning is complete, Terraform will output:

* Jenkins URL
* Initial admin password (get fromt the logs, also available using the command below on the Jenkins server):

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## ☸️ Step 2: Provision Multi-Node Kubernetes Cluster with Argo CD

Navigate to the Kubernetes cluster setup directory:

```bash
cd ../../MultiNode_k8s-and-ArgoCD/
```

### 🔐 Generate SSH Keys for Master/Worker Nodes

```bash
cd keys/
ssh-keygen -t rsa -N "" -f id_rsa
chmod 400 id_rsa
```

### ⚙️ Apply Terraform Configuration

```bash
cd ../terraform-ws/

terraform init
terraform fmt
terraform validate
terraform plan
terraform apply --auto-approve
```

Once successful, Terraform will output:

* ✅ Argo CD URL (via NodePort on master node public IP)
* ✅ Argo CD Initial Admin Password
* ✅ NGINX Ingress Controller URL (also via NodePort)

You can access both using your browser with the public IP of the master node.

---

## 📌 Notes

* Jenkins builds and pushes the Docker image.
* The Jenkins pipeline triggers the CD repo, which is watched by Argo CD.
* Argo CD syncs the Kubernetes manifests and deploys the latest version.
* NGINX Ingress routes external traffic to the correct application pods.
* `externalTrafficPolicy` is set to `Cluster` to ensure master node can route traffic to pods on worker nodes.

---

## 📁 Directory Structure Overview

```
.
|-- Infrastructure
|   |-- Jenkins_server
|   |   |-- ssh-keys
|   |   |   |-- id_rsa
|   |   |   `-- id_rsa.pub
|   |   |-- install_jenkins.sh
|   |   |-- jenkins_server.tf
|   |   |-- output.tf
|   |   |-- providers.tf
|   |   |-- terraform.tfvars
|   |   `-- variables.tf
|   `-- MultiNode_k8s-and-ArgoCD
|       |-- ansible-ws
|       |   |-- example-files.md
|       |   |-- rhel_common.yml
|       |   |-- rhel_master.yml
|       |   `-- setup-argoCD-and-nginx-ingress.yml
|       |-- calico.yaml
|       |-- keys
|       |   |-- id_rsa
|       |   `-- id_rsa.pub
|       `-- terraform-ws
|           |-- main.tf
|           |-- outputs.tf
|           |-- providers.tf
|           |-- terraform.tfvars
|           `-- variables.tf
|-- README.md
|-- Screenshots
|   |-- 01-aws-configure.png
|   |-- 02-Instance-ssh-keys.png
|   |-- 03-terraform-init-jenkins-server.png
|   |-- 04-terraform-plan-jenkins-server.png
............Skipping...................
`-- dicovery-branches-note.md

8 directories, 83 files
```

---

📦 GitOps CI/CD Architecture

```markdown

                                        ┌────────────────────┐
                                        │  Your Local VM      │
                                        │(Terraform + Ansible)│
                                        └────────┬────────────┘
                                                 │
               ┌─────────────────────────────────┼─────────────────────────────────┐
               │                                 │                                 │
               ▼                                 ▼                                 ▼
    ┌─────────────────────┐          ┌────────────────────────┐        ┌────────────────────────┐
    │ Provision Jenkins EC2│         │Provision K8s EC2 Nodes │        │Trigger Ansible (Infra) │
    └────────┬─────────────┘          └────────┬───────────────┘        └────────┬───────────────┘
             │                                 │                                ▼
             │                        ┌────────▼─────────┐       ┌────────────────────────────────────┐
             │                        │Setup K8s Cluster │◄──────┤  Ansible Playbooks:                │
             │                        └────────┬─────────┘       │  - kubeadm multi-node cluster      │
             │                                 │                 │  - Argo CD installation            │
             │                                 │                 │  - NGINX Ingress setup             │
             │                                 ▼                 └────────────────────────────────────┘
             │                      ┌────────────────────┐
             │                      │  Deployed Argo CD   │
             │                      └────────┬────────────┘
             │                               │
             ▼                               ▼
 ┌────────────────────────────┐     ┌────────────────────────────┐
 │Jenkins Server (CI Role)    │     │GitHub CD Repo (Manifests)  │
 └────────┬───────────────────┘     └────────┬───────────────────┘
          │                                  │
          │  Push new manifests (via CI)     │
          └─────────────────────────────────►│
                                             ▼
                                    ┌────────────────────────────┐
                                    │        Argo CD Syncs       │
                                    │  (Auto Deployment to K8s)  │
                                    └────────────────────────────┘

```
---

### 🔁 Flow Summary:
* Terraform and Ansible from my local VM.
* Terraform provisions:
  1. Jenkins EC2 instance (and sets it up via remote-exec).
  2. EC2 instances for the Kubernetes multi-node cluster.
  3. 
* Terraform also triggers Ansible (via local-exec) to:
  1. Initialize and configure Kubernetes cluster (using the EC2s).
  2. Install Argo CD inside K8s.
  3. Deploy NGINX Ingress controller.

* Jenkins is used only for CI — it connects to GitHub repos, builds, and updates CD repo.
* Argo CD syncs from the CD repo and deploys apps.

---

