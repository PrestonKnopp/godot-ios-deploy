# iOS Deploy

> Deploy to iOS for testing in one click from within Godot!

## Prerequisites

1. macOS
2. iOS Developer account
    - sign up on apple's website, its free
    - Xcode should help set this up to be used for code signing
3. Xcode and its command line tools
    - Install Xcode from the App Store and 
    - Open Terminal and type xcodebuild 
        - should ask to install the command line tools
4. [Godot export templates](https://godotengine.org/download)
6. [ios-deploy](https://github.com/ios-control/ios-deploy)
    - Install ios-deploy with [homebrew](https://brew.sh)
        - `brew install ios-deploy`

## NOTE

This addon is rough around the edges. Looking forward to getting feedback and
hearing about ways to improve workflow, usability, and QoL.

## Features

1. Supports Godot versions 2 and 3 in one package
2. One click deploy
3. No need to open xcode (after you have registered your apple developer
   account)
4. Finds installed provisioning profiles and teams
5. Builds and signs project
6. Deploy to multiple ios devices in parallel

## Install

1. Download or clone this repo
2. Put com.indicainkwell.iosdeploy folder into the addons folder of your godot
   project

I will eventually put this up on the asset library.

## Usage

An apple button will appear in Godots Editor's toolbar. Pressing this button
will

1. Open onboarding flow menu if not setup or
2. Begin build and deploy

## Troubleshooting

If all goes well it will attempt to deploy it, but can fail for multiple reasons:

1. Security Failure
    - You must verify your app or developer account on your iOS device by going
      to `Settings > General > Device Management > Your account` and tap verify.
2. More in todo.txt
3. ...
