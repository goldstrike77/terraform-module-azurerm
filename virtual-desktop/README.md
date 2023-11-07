#### Usage
Only the release number needs to be modified.

```
In the automation that's running Terraform, once terraform apply succeeds run terraform output -raw password to get the raw password value. 

password="$(terraform output -raw admin_password)"
echo ${password}