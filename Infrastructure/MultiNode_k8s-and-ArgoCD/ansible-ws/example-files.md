## ansible.cfg will look like this
```
[defaults]
host_key_checking=False
inventory=./inventory
remote_user=ec2-user
private_key_file=../keys/id_rsa
ask_pass=false
deprecation_warnings=False

[privilege_escalation]
become=true
become_method=sudo
become_user=root
become_ask_pass=false
```

## inventory file will look like this

```
[master]
13.127.237.7 ansible_user=ec2-user ansible_ssh_private_key_file=../keys/id_rsa

[slaves]
43.204.25.157 ansible_user=ec2-user ansible_ssh_private_key_file=../keys/id_rsa
65.0.7.75 ansible_user=ec2-user ansible_ssh_private_key_file=../keys/id_rsa
```


## join-command will look like this
```
kubeadm join 172.31.41.171:6443 --token aapr6d.g8d2fibecdyeq110 --discovery-token-ca-cert-hash sha256:b8a56feb87577c0350668befd6ebf0ec81aa2d9e7475de5e8ff04d958a645a65
```