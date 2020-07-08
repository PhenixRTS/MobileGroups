# Phenix Groups

## Requirements

- Xcode (11.5)
- Swift 5.2
- iOS 12.0 and above

## 1. step - Build
*(Commands must be executed from the project's **root** directory)*

1. Install [Bundler](https://bundler.io) using Terminal:
```
gem install bundler
```

2. Install project environment dependencies listed in [Gemfile](/iOS/PhenixGroups/Gemfile):
```
bundle install
```
This will install specific version of dependency management tool called `Cocoapods`, which our project uses to link 3rd party dependecy libraries.

3. Install project dependencies listed in [Podfile](/iOS/PhenixGroups/Podfile):
```
bundle exec pod install
```

## 2. step - Run Project

1. Open `PhenixGroups.xcworkspace` 
2. Select schema `PhenixGroups` 

![Schema location](/iOS/PhenixGroups/Images/xcode_schema_location.png)

3. Select desired device (Simulator or Physical device)

![Select device](/iOS/PhenixGroups/Images/xcode_device_list.png)

4. Press Run

![Run project](/iOS/PhenixGroups/Images/xcode_run_project.png)
