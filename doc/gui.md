# GUI setup

## Install

```bash
sudo pacman -Syy
curl -L goo.gl/SM8Qfc | sh
```

```bash
yaourt -S pulseaudio{,-alsa} alsa-utils pamixer pavucontrol\
          xorg-{xinit,server}\
          xf86-video-intel xf86-input-synaptics\
          lightdm{,-gtk-greeter}\
          xmonad xmonad-contrib xmobar\
          xsel rofi dunst termite\
          fcitx-mozc fcitx-im fcitx-configtool\
          ttf-mplus noto-fonts{,-cjk,-emoji} otf-ipamjfont
sudo -E nvim /etc/lightdm/lightdm.conf
# greeter-sesssion=lightdm-gtk-greeter
sudo systemctl enable lightdm.service
```

```bash
mv 60-synaptics.conf /etc/X11/xorg.conf.d/60-synaptics.conf
```
