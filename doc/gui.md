# GUI setup

## enable display manager

```bash
sudo -E nvim /etc/lightdm/lightdm.conf
# greeter-sesssion=lightdm-gtk-greeter
sudo systemctl enable lightdm.service
```

## Configure touchpad

```bash
mv 30-touchpad.conf /etc/X11/xorg.conf.d/
```
