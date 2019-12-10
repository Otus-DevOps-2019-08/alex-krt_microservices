variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default = "europe-west1"
}

variable public_key_path {
  description = "Public key path"
}

variable disk_image {
  description = "Disk image"
}

variable instances_count {
  description = "Count of instances"
  default = 1
}
