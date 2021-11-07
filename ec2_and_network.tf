# creation of an ec2 with all the network and other aws stuff creation:
# - creation of the ssh key pair and saving of the pem file locally
# - installation of an nginx

/* static authentication in aws - of course not reccomended */
provider "aws" {
  region = "eu-west-1"
  access_key = var.access_key
  secret_key = var.secret_key
  #version = "3.62.0"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "tf-example-vpc"
  }
}

resource "aws_subnet" "ec2_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = "eu-west-1a"

  tags = {
    Name = "tf-example-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "internet-gateway"
  }
}

# seleziono la route table create da aws per poi aggiungere una regola e rendere la subnet pubblica
data "aws_route_table" "route_table_ec2_autocreated" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route" "route" {
  route_table_id            = data.aws_route_table.route_table_ec2_autocreated.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "tls_private_key" "tls_pk" {
  algorithm = "RSA"
}

resource "aws_key_pair" "key_pair" {
  key_name   = "ec2_key_pair_auto"
  public_key = tls_private_key.tls_pk.public_key_openssh

  # provisioner are able to execute script locally or remotely, in this case locally
  # getting private key for connecting to the ec2
  # not very secure
  # create pem in same folder to make connection very easy
  provisioner "local-exec" {
    command = "touch ${self.key_name}.pem && echo '${tls_private_key.tls_pk.private_key_pem}' > ./${self.key_name}.pem && chmod 400 ./${self.key_name}.pem"
  }
}



# regole security group da associare alla macchina per poter accedere tramite la 22 in SSH
resource "aws_security_group" "allow_ssh" {
  name        = "ec2_security_group"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  // declaring a list as dynamic block
  dynamic "ingress" {
    for_each = var.security_group_default_ports
    iterator = port
    content {
      description      = "Opening port from outside"
      from_port        = port.value
      to_port          = port.value
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false
    }
  }

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids = []
      security_groups = []
      self = false
      description = "Default Egress for connecting outside"
    }
  ]

  tags = {
    Name = "allow_ssh"
  }
}

# ec2 machine creation
resource "aws_instance" "ec2_instance" {
  ami                    = "ami-0a8e758f5e873d1c1"
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.key_pair.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  subnet_id = aws_subnet.ec2_subnet.id

  depends_on = [aws_internet_gateway.gw]

  count = 2


}

# public ip to associate to ec2
resource "aws_eip" "lb" {
  instance = aws_instance.ec2_instance[count.index].id
  vpc      = true
  count = 2
}

resource "null_resource" "install_nginx_provisioner" {
  depends_on = [aws_instance.ec2_instance, aws_eip.lb, aws_key_pair.key_pair]

  provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y nginx",
      "sudo systemctl start nginx"
    ]

    connection {
      type = "ssh"
      user = "ubuntu"
      private_key = file("./${aws_key_pair.key_pair.key_name}.pem")
      host = aws_eip.lb[count.index].public_ip
    }
  }

  count = 2
}


# splash operator to print all the public generated ips
output "instance_ec2_public_ip" {
  value = aws_eip.lb[*].public_ip
}

output "combined" {
  value = zipmap(aws_instance.ec2_instance[*].arn, aws_eip.lb[*].public_ip)
}

/*
resource "aws_key_pair" "key_pair" {
  key_name   = "ec2_key_pair_generate_locally"
  # generated key pair with command ssh-keygen -t rsa -b 2048 -
  # Optional: I've passed the abs path to key_pair folder to generate the key pair in that location
  # followed by the key pair name (of course you can move it after from the default location)
  # after that take the pub part and paste it here
  # keep the private key secure to connect to

  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDQrl0eRlU+nFNCtcHGcU9/KMeSXsCDJAu/LSRbbxGlWrwvM6TjGBNVHLFPxgVsWALuERGIIb6XSoJB78Exy0o1Yu0/E9qvbm8DeXg9d+e7OiRcYzN52wGui7/Js+FWZpFqPwKUSZXskPg1MVcQHsLVU2ndDPCfv+Ne2xi9+84Lu55MA7In88ZhZRKL0teh2e6qCwp/Ica4RrtzFLmCrIAKcHB/5vHTbfj4JkLOPP/zbzoAFq40C4iBFxHDf7ov1ngzRrb1sge5ThHoOyWhz0WVpMc0dmwf8FvOQYfm1wR1+KU8q7ObQEsAwjpg/YjWYpd9PHtEUAdswGi48PEfA/SL"

  # in this way you don't need even to create the public key locally and paste it here
  # you can use a provisioner or output variable to get the private key, but is not very securecd
  # public_key = tls_private_key.tls_pk.public_key_openssh

  # Create "myKey.pem" to your computer!  Don't try this at home
  #  # You should
  #    - generate a key pair using ssh keygen
  #    - pass the public key in the variable above
  #    - keep the private key secure to connect to the ec2

  # provisioner are able to execute script locally or remotely, in this case locally
  #  provisioner "local-exec" {
  #    command = "echo '${tls_private_key.tls_pk.private_key_pem}' > ./ec2_key_pair.pem"
  #  }
}
*/
