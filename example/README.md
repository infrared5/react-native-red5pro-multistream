# Red5ProMultiStreamViewExamples

Examples in using the `react-native-red5pro-multistream` React Native component library.

> You will need a Red5 Pro SDK License and a Red5 Pro Server in order to use this component.  
[Sign up for a free trial!](https://account.red5pro.com/register)

# Menu

* [Installing](#installing)
* [Example](#example)
* [Running Examples](#running-examples)
  * [iOS](#ios-example)
  * [Android](#android-example)
* [Notes](#notes)

# Installing

You will need to install the required dependencies prior to running the examples. To do so, issue the following command in a terminal:

```sh
$ npm install
```

# Examples

A [Red5 Pro Server](https://red5pro.com) has been deployed remotely and the Red5 Pro Mobile SDK license is `YOU-RLIC-ENSE-1234`. You will ned to change both of these to where you Red5 Pro Server is deployed and your personal Red5 Pro Mobile SDK License, respectively.

* [App.js](App.js#L23)

> Note: Because of React Native's debugger defaulting to `8081` and the default unsecure websocket port of Red5 Pro being `8081`, you may need to re-define one or the other ports if developing locally.

## Stream Access

After successfully starting a broadcast session, the example app continually requests available streams to subscribe to using the basic `streams.jsp` request from the `live` webapp.

The streams to subscribe to are then filtered based on a naming convention:

## Streaming Name Convention

These examples use a naming convention for stream names in the folloing format:

* `r5pro-(video|audio)-<name>`

The prefix of `r5pro` relates to Red5 Pro and is used as a way to filter out any other streams _not_ prefixed as `r5pro` from the list of streams to start subscribing to.

The `video` or `audio` option is used to define whether the subscriber instance should also set up a view for playback (when `video` specified) or only subscribe to audio (when `audio` specified).

The `<name>` is whatever additional name you wish to provide to distinguish one stream from another.

As an example:

1. Jon is a moderator of a conference and is the only user allowed to broadcast video.
2. Jon begins his broadcast with a stream name of `r5pro-video-jon`.
3. Mary is an audience member that is allowed to add to the conversation, but with an audio stream only.
4. Mary begins her broadcast with a stream name of `r5pro-audio-mary`.
5. On Jon's mobile device, we sees his video feed and hears Mary's audio stream while broadcasting video and audio.
6. On Mary's mobile device, she sees and hears Jon's stream while broadcasting audio.

# Running Examples

You can launch these Red5 Pro Native Component examples onto your target device(s) doing the following:

## iOS Example

It is recommended to launch the [ios/Red5ProMultiStreamViewExample.xcoeproj](ios/Red5ProMultiStreamViewExample.xcoeproj) in Xcode, and deploying to a connected device.

## Android Example

Be sure you have a device tethered, then issue the following:

```sh
$ npm run android
```

# Notes

> This project was bootstrapped with [Create React Native App](https://github.com/react-community/create-react-native-app).
