# Phenix Groups

## Build

*(Commands must be executed from the project's **root** directory)*

1. Install [Bundler](https://bundler.io) using Terminal:
```
gem install bundler
```

2. Install project environment dependencies listed in [Gemfile](Gemfile):
```
bundle install
```
This will install the [CocoaPods](https://cocoapods.org), which this project uses to link 3rd party frameworks.

3. Install project dependencies listed in [Podfile](Podfile):
```
bundle exec pod install
```

## Deep links

The application can only be opened using a deep link together with configuration parameters.
Without these parameters, application will automatically fail to open.

### Examples:

```
https://phenixrts.com/group/?authToken=DIGEST:eyJhcHB...&publishToken=DIGEST:eyJhcHB...&roomAudioToken=DIGEST:eyJhcHB...&roomVideoToken=DIGEST:eyJhcHB...#xxx-xxxx-xxx
```

### Parameters

* `authToken` - Authentification token.
* `publishToken` - Publishing token.
* `roomAudioToken` - Stream token for audio-only subscription.
* `roomVideoToken` - Stream token for video-only subscription.
* `#xxx-xxxx-xxx` - Room alias (`#` before the room alias is required)

### Debugging

For easier deep link debugging, developer can use *Environment Variable* `PHENIX_DEEPLINK_URL` to inject a deep link on the application launch from Xcode.

Read more information about this in [PhenixDeeplink](../PhenixDeeplink/README.md).

## Debug menu

To open a debug menu, tap 5 times quickly anywhere in the application.
