resource "exoscale_domain_record" "no-www" {
  domain      = "${var.dns_zone_name}"
  name        = "@"
  record_type = "A"
  ttl         = 60
  content     = "${exoscale_compute.web.ip_address}"
}

resource "exoscale_domain_record" "www" {
  domain      = "${var.dns_zone_name}"
  name        = "www"
  record_type = "A"
  ttl         = 60
  content     = "${exoscale_compute.web.ip_address}"
}

resource "exoscale_domain_record" "mx" {
  domain      = "${var.dns_zone_name}"
  name        = "@"
  record_type = "MX"
  ttl         = 600
  prio        = 10
  content     = "mx.opsbears.com."
}

resource "exoscale_domain_record" "dmarc" {
  domain      = "${var.dns_zone_name}"
  name        = "_dmarc"
  record_type = "TXT"
  ttl         = 60
  content     = "v=DMARC1; p=none; rua=mailto:hostmaster@pasztormuvek.hu; adkim=r; aspf=r; sp=none"
}

resource "exoscale_domain_record" "spf" {
  domain      = "${var.dns_zone_name}"
  name        = "@"
  record_type = "TXT"
  ttl         = 600
  content     = "v=spf1 mx a ?all"
}
