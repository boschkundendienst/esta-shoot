## fixes for 2023.08.01

### changes in configuration format

- the disk layout is now part of `user_configuration.json`
- `user_disk_layout.json` has been removed from `archinstall` 

### missing safe_dev_path

- `archinstall` did not add necessary `safe_dev_path` after `obj_id`. Manual fix was needed:

```
...
  "mountpoint": "/boot",
  "obj_id": "1ef9b934-27b8-4c36-bc32-b7df64aeadfd",
  "safe_dev_path": "/dev/sda1",
...
...
  "mountpoint": "/",
  "obj_id": "795504ff-3105-4421-8625-3a059dccb2c2",
  "safe_dev_path": "/dev/sda2",
...
```
