resource "null_resource" "bastion_connect" {
  depends_on = [module.bastion_host]

  connection {
    type        = "ssh"
    host        = module.bastion_host.bastion_ip[0]
    user        = "ec2-user"
    password    = ""
    private_key = file("private-key/terraform-key-1.pem")
  }

  provisioner "file" {
    source      = "private-key/terraform-key-1.pem"
    destination = "/tmp/terraform-key-1.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /tmp/terraform-key-1.pem"
    ]
  }
}