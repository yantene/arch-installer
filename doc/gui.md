# GUI setup

## Install

```bash
sudo pacman -Syy
curl -L goo.gl/SM8Qfc | sh
```

```bash
yaourt -S pulseaudio{,-alsa} alsa-utils pamixer pavucontrol\
          xorg-{xinit,server,server-utils}\
          xf86-video-intel xf86-input-synaptics\
          lightdm{,-gtk-greeter}\
          xmonad xmonad-contrib xmobar\
          xsel rofi dunst termite\
          fcitx-mozc fcitx-im fcitx-config-tool\
          ttf-migu noto-fonts{,-cjk,-emoji,-unhinted} otf-takao{,ex,mj}
sudo -E nvim /etc/lightdm/lightdm.conf
# greeter-sesssion=lightdm-gtk-greeter
sudo systemctl enable lightdm.service
```

```bash
mv 60-synaptics.conf /etc/X11/xorg.conf.d/60-synaptics.conf
```