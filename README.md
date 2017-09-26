# iOS Deploy

> Deploy to iOS for testing in one click from within Godot!

Contact me for help at:
- indicainkwell@gmail.com
- discord: indicainkwell
- reddit: indicainkwell

### Prerequisites

1. macOS
2. iOS Developer account
    - sign up on apple's website, its free
    - Xcode should help set this up to be used for code signing
3. Xcode and its command line tools
    - Install Xcode from the App Store and 
    - Open Terminal and type xcodebuild 
        - should ask to install the command line tools
4. [Godot export templates](https://godotengine.org/download)
5. Godot binary in your $PATH
    - In your .bash\_profile include 
        - `export PATH=$PATH:/Applications/Godot.app/Contents/MacOS/godot`
6. ios-deploy
    - Install ios-deploy with [homebrew](https://brew.sh)
        - `brew install ios-deploy`

### Install

Download or clone this repository into a temporary location and then drag and
drop the com.indicainkwell.iosdeploy folder into the addons folder of your
project. Create res://addons folder in your project if it does not exist.

I will eventually put this up on the asset library.

### Setting Up Your Project

After the above prerequisites, you'll need to unzip the iOS export template,
`~/.godot/templates/GodotiOSXCode.zip`, move the unzipped xcode project to
wherever you want, then open it in xcode.

Follow the godot [guide on exporting to
ios](http://docs.godotengine.org/en/latest/learning/workflow/export/exporting_for_ios.html)
to get it ready, but don't add data.pck, drag your  game folder to xcode making
sure that Copy Files is **unchecked**.

You only need to setup a xcode project once per godot project.

Here's a checklist to prepare your bundle:
- **Check automatic signing and provision**
- Set bundle identifier and name
- Info.plist you have set godot\_path to your game folder name
- Update xcode project image assets with your custom images such as
    - icon
    - splash screen

### Usage

An apple button will appear in Godot's Editor's toolbar that you can

1. *Left click* to start deploy pipeline to a connected ios device.
2. *Right click* to view a menu with options to
    - rebuild xcode proj
    - show settings
    - show and choose from connected devices
    - deploy options
        - deploy with remote fs
        - deploy with fresh install (default)

^ That's it. If everything is set up, otherwise...

The following stipulations will be checked on click:

- Xcode project has been created and setup
    - if not, the xcode configuration menu will popup
- Xcode project has been built
    - if not, it will build it in the background
    - then continue to...
- Valid device is connected/selected
    - if single device is connected it will validate automatically
    - if multiple devices are connected the device menu will popup

If all goes well it attempt to deploy it, but can fail for multiple reasons:

1. Security Failure
    - You must verify your app or developer account on your iOS device by going
      to `Settings > General > Device Management > Your account` and tap verify.
2. Not or improperly signed bundle
    - turn on automatic code signing in xcode
3. Unknown
    - We will see...

**Note**: at this time only one ios device at a time is supported, but that is not a
hard limitation.  
**Note**: only iPhone is supported, also not a hard limitation.

### To Do / Roadmap

- [X] show alert with deploy fail reasons
- [X] _FIXME_ reconnect all disconnected signals
- [ ] Code software requirements and offer to install as much as possible.
- [ ] Support iPad
- [X] Some sort of visual of deploy status
- [ ] Look into copying godot project into bundle if binary already installed
    - Faster
- [ ] Automate creation of xcode project
    - Copy icons and splash images
    - Check out run script build phase to copy godot project into ios bundle
    - Modify Info.plist with `plutil`
        - "CFBundleName" => "${PRODUCT\_NAME}"
        - "CFBundleIdentifier" => "$(PRODUCT\_BUNDLE\_IDENTIFIER)"
        - "CFBundleExecutable" => "godot\_opt.iphone"
        - "CFBundleShortVersionString" => "1.0"
        - "CFBundleDisplayName" => "Insert Name Here"
        - "UISupportedInterfaceOrientations"
            - 0 => "UIInterfaceOrientationLandscapeLeft"
            - 1 => "UIInterfaceOrientationLandscapeRight"
        - "UISupportedInterfaceOrientations~ipad"
            - 0 => "UIInterfaceOrientationLandscapeLeft"
            - 1 => "UIInterfaceOrientationLandscapeRight"

