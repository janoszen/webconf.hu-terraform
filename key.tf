resource "tls_private_key" "ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

resource "tls_self_signed_cert" "ca" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.ca.private_key_pem

  validity_period_hours = 26280
  early_renewal_hours   = 8760

  is_ca_certificate = true

  allowed_uses = ["cert_signing"]

  subject {
    common_name  = "Magyar Webert Egyesulet CA"
    organization = "Magyar Webert Egyesulet"
    country = "AT"
  }
}

//region ECDSA
resource "tls_private_key" "web-ecdsa" {
  algorithm = "ECDSA"
}

resource "tls_cert_request" "web-ecdsa" {
  key_algorithm = tls_private_key.web-ecdsa.algorithm
  private_key_pem = tls_private_key.web-ecdsa.private_key_pem
  subject {
    common_name  = "${var.server_hostname}.${var.server_domain}"
    organization = "Magyar Webert Egyesulet"
    country = "AT"
  }
}

resource "tls_locally_signed_cert" "web-ecdsa" {
  cert_request_pem = tls_cert_request.web-ecdsa.cert_request_pem

  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 17520
  early_renewal_hours   = 8760

  allowed_uses = ["server_auth"]
}
//endregion

//region RSA
resource "tls_private_key" "web-rsa" {
  algorithm = "RSA"
}

resource "tls_cert_request" "web-rsa" {
  key_algorithm = tls_private_key.web-rsa.algorithm
  private_key_pem = tls_private_key.web-rsa.private_key_pem
  subject {
    common_name  = "${var.server_hostname}.${var.server_domain}"
    organization = "Magyar Webert Egyesulet"
    country = "AT"
  }
}

resource "tls_locally_signed_cert" "web-rsa" {
  cert_request_pem = tls_cert_request.web-rsa.cert_request_pem

  ca_key_algorithm   = tls_private_key.ca.algorithm
  ca_private_key_pem = tls_private_key.ca.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.ca.cert_pem

  validity_period_hours = 17520
  early_renewal_hours   = 8760

  allowed_uses = ["server_auth"]
}
//endregion

resource "tls_private_key" "initial" {
  algorithm = "RSA"
  rsa_bits = 4096
}

resource "exoscale_ssh_keypair" "initial" {
  name = local.domain_name
  public_key = replace(tls_private_key.initial.public_key_openssh, "\n", "")
}

output "known_hosts_ca" {
  value = "@cert-authority *.${var.server_domain} ${tls_private_key.ca.public_key_openssh}"
}