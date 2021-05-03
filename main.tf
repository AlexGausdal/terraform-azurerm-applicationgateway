locals {
    azurerm_application_gateway_name = "${var.k8s_name}-application-gateway"
    gateway_ip_configuration_name    = "${var.k8s_name}-gateway-ip-configuration"
    frontend_port_name               = "${var.k8s_name}-frontend-port"
    frontend_ip_configuration_name   = "${var.k8s_name}-frontend-ip-configuration"
    backend_address_pool_name        = "${var.k8s_name}-backend-address-pool"
    backend_http_settings_name       = "${var.k8s_name}-backend-http-settings"
    http_listener_name               = "${var.k8s_name}-http-listener"
    request_routing_rule_name        = "${var.k8s_name}-request-routing-rule"
    host_name                        = "${var.k8s_name}.eksempel.no"
    probe_name                       = "${var.k8s_name}-probe"
}

resource "azurerm_subnet" "agw-snet" {
  name                 = "snet-${var.k8s_name}-agw"
  resource_group_name  = var.rg_k8s_name
  virtual_network_name = var.virtual_network_name
  address_prefixes     = var.k8s_agw_snet_address_prefixes

 # depends_on = [azurerm_virtual_network.k8s-vnet]
}


resource "azurerm_application_gateway" "network" {
  name                = local.azurerm_application_gateway_name
  resource_group_name = var.rg_k8s_name
  location            = azurerm_resource_group.k8s-rg.location

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = local.gateway_ip_configuration_name
    subnet_id = azurerm_subnet.agw-snet.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80 //kanskje 443
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.k8s-ingress-ip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.backend_http_settings_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/" //look at
    port                  = 80 //changed from "80"
    protocol              = "http" //changed from "http"
    request_timeout       = 60
    probe_name            = local.probe_name
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "http" //changed from "http"
    host_name                      = local.host_name //finn ut av hostname
    //ssl_certificate_name           = "wildcard-eksempel.no" //finn ut av certificat
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.backend_http_settings_name
  }

  probe {
    name                       = local.probe_name
    protocol                   = "http"
    host                       = local.host_name
    path                       = "/" //(med mindre kunde ønsker noe annet)
    interval                   = 1
    timeout                    = 30
    unhealthy_threshold        = 1


    match {               //Dette trenger nok noen tweeks
      body = "Health probe sent status"
      status_code = [ "200" ]
      
    }
  }

  lifecycle {
    ignore_changes = [
      probe,
      http_listener,
      backend_http_settings,
    ]
  }

  tags = var.tags

 # depends_on = [azurerm_virtual_network.k8s-vnet, azurerm_public_ip.k8s-ingress-ip]
}

resource "azurerm_public_ip" "k8s-ingress-ip" {
  location            = var.location
  name                = "${var.k8s_name}-ingress-ip"
  resource_group_name = var.rg_k8s_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = lower(var.k8s_name)

  tags = var.tags
}