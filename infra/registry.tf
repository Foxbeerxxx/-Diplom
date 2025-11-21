resource "yandex_container_registry" "test_registry" {
  name      = "diplom-test-registry"
  folder_id = var.folder_id
}
