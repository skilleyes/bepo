# bepo
My linux custom bepo layout, for french and english, optimised for programming.

### Install instructions for Ubuntu 20.04

1. Backup the current symbols file in `/usr/share/X11/xkb/symbols`

    ```
    sudo mv /usr/share/X11/xkb/symbols/fr /usr/share/X11/xkb/symbols/fr.bak
    ```

1. Copy the `pilotes/configGenerator/results/layout-1.1.xkb` into the `/usr/share/X11/xkb/symbols/fr` file.
    Overwrite the `"French (Bepo, ergonomic, Dvorak way)"` section.

    ```
    sudo vim /usr/share/X11/xkb/symbols/fr
1. Run the following to take changes into account:

    ```
    sudo dpkg-reconfigure xkb-data
    ```

1. Reboot shouldn’t be needed

### Install instructions for Mac OS

1. Unzip the bundle to `~/Library/Keyboard Layouts`

1. Go to `Settings -> Keyboard -> Input Sources -> + -> Others` and add the Keyboard !
