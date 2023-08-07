## fixes for 2023.08.01
`archinstall` did not add necessary `safe_dev_path` after `obj_id`. Manual fix was needed:

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
