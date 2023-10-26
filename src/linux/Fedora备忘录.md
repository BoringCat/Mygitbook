# Fedora备忘录 <!-- omit in toc -->

- [批量改源](#批量改源)
- [libvirtd](#libvirtd)

## 批量改源
```sh
sed -e 's!^metalink=!#metalink=!g' \
    -e 's!^#baseurl=!baseurl=!g' \
    -e 's!//download\.example/pub!//mirrors.sjtug.sjtu.edu.cn!g' \
    -e 's!http://mirrors\.sjtug!https://mirrors.sjtug!g' \
    -i /etc/yum.repos.d/fedora-modular.repo \
    /etc/yum.repos.d/fedora.repo \
    /etc/yum.repos.d/fedora-updates-modular.repo \
    /etc/yum.repos.d/fedora-updates.repo \
    /etc/yum.repos.d/fedora-updates-testing-modular.repo \
    /etc/yum.repos.d/fedora-updates-testing.repo
```

## libvirtd
```sh
dnf install libvirt qemu-kvm qemu-system-x86
```
- with cockpit?
    ```sh
    dnf install libvirt qemu-kvm qemu-system-x86 collectd-virt
    ```