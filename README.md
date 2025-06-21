# HHD Control Plasmoid

![alt text](https://i.imgur.com/pxDZ3mH.png)

A KDE Plasma widget that provides a minimalistic GUI for HHD (Handheld Daemon). This plasmoid allows you to manage TDP (Thermal Design Power) settings and other handheld device controls directly from your desktop.

![alt text](https://i.imgur.com/JiLI78g.png)

## Building

To build the plasmoid package for installation:

```bash
./build.sh
```

This will create a `.plasmoid` file that can be installed on any KDE Plasma desktop.

## Installation

### From Release
1. Download the `.plasmoid` file from releases
2. Install using: `kpackagetool6 --type=Plasma/Applet --install <filename>.plasmoid`

### From Source
1. Build the package: `./build.sh`
2. Install the generated `.plasmoid` file: `kpackagetool6 --type=Plasma/Applet --install org.kde.plasma.desktoptdpcontrol-*.plasmoid`

### Manual Installation
1. On your desktop: Right-click > Enter Edit Mode > Add or Manage Widgets > Get New > Install Widget From Local File...
   ![alt text](https://i.imgur.com/FEWM2Hj.png)
2. Select the `.plasmoid` file
3. The widget will be available in your widget list

## Management Commands

After installation, you can manage the plasmoid using these commands:

```bash
# Upgrade to newer version
kpackagetool6 --type=Plasma/Applet --upgrade org.kde.plasma.desktoptdpcontrol-*.plasmoid

# Remove/uninstall
kpackagetool6 --type=Plasma/Applet --remove org.kde.plasma.desktoptdpcontrol

# List installed plasmoids  
kpackagetool6 --type=Plasma/Applet --list
```

## Configuration

The widget can be configured by right-clicking on it and selecting "Configure". You can customize TDP limits and other HHD daemon settings through the configuration panel.

## Development

For development, you can link the source directory directly:

```bash
git clone <this-repo> <repo-path>
cd ~/.local/share/plasma/plasmoids/
ln -s <repo-path> org.kde.plasma.desktoptdpcontrol
```

This allows you to edit the source files and see changes immediately by restarting Plasma or refreshing the widget.
