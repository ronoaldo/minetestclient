# Minetest client AppImage builds (unofficial)

Based on Debian 11, this project builds AppImages to help you test recent
development builds as well as easily download and run
[Minetest](https://www.minetest.net) in any Linux distro by providing it  with
bundled dependencies.

## How to use them?

[AppImage](https://appimage.org/) format is a simple way to distribute Linux
programs to users in any distribution. It includes a portable runtime, as well
as bundle the application dependencies so it should run on your machine without
many modifications.

To start using the AppImage, just download it from the
[Releases](https://github.com/ronoaldo/minetestclient/releases) page on Github,
make it executable either using your file manager GUI or the command line with
`chmod +x Minetest*.AppImage`, then execute it as `./Minetest*.AppImage` or from
the file manager GUI with a single/double click.

## Portable home folder

Want to test the release candidate without breaking your worlds? No problem!
You can have a portable alternative Home directory to test this one out!

To use this feature, you just create a folder with the same name of the program,
and a `.home` suffix. For instance, the program
`Minetest-5.6.0-rc1_x86_64.AppImage` will use the
`Minetest-5.6.0-rc1_x86_65.AppImage.home` folder as a home directory if it
exists. 

One simple way to get started is from the terminal by using the
`--appimage-portable-home` command line flag:

    ./Minetest*.AppImage --appimage-portable-home

## Better desktop integration

You can also install the companion program `appimagelauncher` that will help you
better integrate the test builds with your system. On Debian and derivatives,
you can to so by installing it form `apt`:

    sudo apt install appimagelauncher

