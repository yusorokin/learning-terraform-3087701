output "instance_image" {
 value = google_compute_instance.instance-1.boot_disk[0].initialize_params[0].image
}

output "instance_id" {
 value = google_compute_instance.instance-1.instance_id
}
