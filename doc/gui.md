# GUI setup

## Install yaourt

```bash
sudo pacman -Syy
curl -L goo.gl/SM8Qfc | sh
```

## Install GUI packages

```bash
yaourt -S pulseaudio{,-alsa} alsa-utils pamixer pavucontrol\
          xorg-{apps,xinit,server}\
          xf86-video-intel\
          lightdm{,-gtk-greeter}\
          xmonad xmonad-contrib xmobar\
          xsel rofi dunst termite\
          fcitx-{mozc,im,configtool}\
          ttf-mplus noto-fonts{,-cjk,-emoji,-extra} otf-ipamjfont
sudo -E nvim /etc/lightdm/lightdm.conf
# greeter-sesssion=lightdm-gtk-greeter
sudo systemctl enable lightdm.service
```

## Configure touchpad

```bash
mv 30-touchpad.conf /etc/X11/xorg.conf.d/
```
