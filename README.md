# iOS Deploy

> Deploy to iOS for testing in one click from within Godot!

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
6. ios-deploy
    - Install ios-deploy with [homebrew](https://brew.sh)
        - `brew install ios-deploy`

### Install

Download or clone this repository into a temporary location and then drag and
drop the com.indicainkwell.iosdeploy folder into the addons folder of your
project. Create res://addons folder in your project if it does not exist.

I will eventually put this up on the asset library.

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

### Pipeline

The following stipulations will be checked on click:

- Xcode project has been created and setup
    - if not, the xcode configuration menu will popup
- Xcode project has been built
    - if not, it will build it in the background
    - then continue to...
- Valid device is connected/selected
    - if single device is connected it will validate automatically
    - if multiple devices are connected the device menu will popup

### Failures

If all goes well it attempt to deploy it, but can fail for multiple reasons:

1. Security Failure
    - You must verify your app or developer account on your iOS device by going
      to `Settings > General > Device Management > Your account` and tap verify.
2. Not or improperly signed bundle
    - turn on automatic code signing in xcode
3. Unknown
    - We will see...
