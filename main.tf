terraform {
  required_providers {
    datadog = {
      source = "DataDog/datadog"
    }
  }
}

provider "datadog" {
  api_key = var.dd_api_key
  app_key = var.dd_app_key
  api_url = "https://app.datadoghq.eu"
}

resource "null_resource" "linux" {
  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = file(var.private_key_dir) #Directory to your private key but if you have a password you can input it here instead
    host        = var.ssh_host_ip
  }

  provisioner "file" {
    source      = "dd_agent.sh"
    destination = "/home/ubuntu/dd_agent.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/dd_agent.sh",
      "sudo /home/ubuntu/dd_agent.sh",
    ]
  }

}

resource "datadog_monitor" "cpumonitor" {
  name    = "cpu monitor ${var.ssh_host_ip}"
  type    = "metric alert"
  message = "CPU usage alert"
  query   = "avg(last_1h):avg:system.cpu.system{*} by {host} > 75" #You could use {host:${var.private_ip}} instead of {*} if you want

  monitor_thresholds {
    warning  = 50
    critical = 75
  }
}

resource "datadog_monitor" "memorymonitor" {
  name    = "memory monitor ${var.ssh_host_ip}"
  type    = "metric alert"
  message = "Memory usage alert"
  query   = "avg(last_1h):avg:system.mem.used{*} by {host} > 2000000000"

  monitor_thresholds {
    warning  = 50000000
    critical = 2000000000
  }
}

resource "datadog_monitor" "diskmonitor" {
  name    = "disk monitor ${var.ssh_host_ip}"
  type    = "metric alert"
  message = "Disk usage alert"
  query   = "avg(last_1h):avg:system.disk.used{*} by {host} > 2000000000"

  monitor_thresholds {
    warning  = 999000000
    critical = 2000000000
  }
}

resource "datadog_dashboard" "ordered_dashboard" {
  title       = "Server Monitoring Dashboard"
  description = "Dashboard for monitoring server metrics"
  layout_type = "ordered"

  widget {
    query_value_definition {
      request {
        q          = "avg:system.uptime{*}"
        aggregator = "avg"
      }
      autoscale  = true
      precision  = "4"
      text_align = "right"
      title      = "System Uptime"
      live_span  = "1h"
    }
  }

  widget {
    alert_graph_definition {
      alert_id  = datadog_monitor.cpumonitor.id
      viz_type  = "timeseries"
      title     = "CPU Usage"
      live_span = "1h"
    }
  }

  widget {
    alert_graph_definition {
      alert_id  = datadog_monitor.memorymonitor.id
      viz_type  = "timeseries"
      title     = "Memory Usage"
      live_span = "1h"
    }
  }

  widget {
    alert_graph_definition {
      alert_id  = datadog_monitor.diskmonitor.id
      viz_type  = "timeseries"
      title     = "Disk Usage"
      live_span = "1h"
    }
  }
}
