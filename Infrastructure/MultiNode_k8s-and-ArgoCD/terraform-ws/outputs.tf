data "local_file" "ansible_outputs" {
  depends_on = [null_resource.trigger_ansible_playbook_argocd_nginx_ingress]
  filename = "${path.module}/../ansible-ws/ansible_outputs.json"
}

locals {
  outputs = jsondecode(data.local_file.ansible_outputs.content)
}

output "argocd_url" {
  value = local.outputs.argocd_url
  description = "Use this URL to access Argo CD UI in browser"
}

output "argocd_password" {
  value = local.outputs.argocd_password
  description = "Use this password to login to Argo CD UI with username 'admin'"
#   sensitive = true # I want the password to be printed on screen in terraform outputs
}

output "ingress_url" {
  value = local.outputs.ingress_url
  description = "Use this to access any Ingress-based service"
}
