# lxd-helpers

# Installation

Just clone/download and use. 

# Configuration

* Have LXD installed
* Be in the `lxd` group
* Have a suguid/subgid map for your user. These scripts assume your uid is 1000. (A usual default uid for the main user)
In `/etc/subuid` and `/etc/subgid`:
```
root:1000:1
```

You can edit the `USER` variable in the scripts to change the user created in the container.

# Examples

### create_lxc_container.sh
Creates an Ubuntu 18.04 container named `testlxd` with the directory `/tmp/share` shared in the container as `/host`.
```
create_lxc_container.sh testlxd 1 /tmp/share
```

### create_gui_container.sh
Creates an GUI capable Ubuntu 18.04 container named `testgui` with the directory `/tmp/share` shared in the container as `/host`. Firefox is installed to provide GUI packages and a testable application.
```
create_gui_container.sh testgui 1 /tmp/share
```

### delete_lxc_container.sh
Deletes the container `testlxd`
```
delete_lxc_container.sh testlxd
```

### enter_lxc_container.sh
Enters the container `testlxd`
```
delete_lxc_container.sh testlxd
```

# Sources

Referenced this page a lot, especially for GUI containers: https://blog.simos.info/how-to-easily-run-graphics-accelerated-gui-apps-in-lxd-containers-on-your-ubuntu-desktop/

The `lxdgui-profile.txt` file is based off the profile provided on that page. 