import React from 'react'
import {
  findNodeHandle,
  Button,
  StyleSheet,
  Text,
  View
} from 'react-native'

import Permissions from 'react-native-permissions'
import {
  R5MultiStreamView,
  R5LogLevel,
  subscribe,
  unsubscribe,
  publish,
  unpublish
} from 'react-native-red5pro-multistream'

const host = 'nafarat.red5.org'
const licenseKey = 'IBBB-LOPP-I32M-UIOS'
const bundleID = 'com.red5pro.multistream'

export default class App extends React.Component {
  constructor (props) {
    super(props)

    // Events.
    this.onMetaData = this.onMetaData.bind(this)
    this.onConfigured = this.onConfigured.bind(this)
    this.onPublisherStreamStatus = this.onPublisherStreamStatus.bind(this)
    this.onSubscriberStreamStatus = this.onSubscriberStreamStatus.bind(this)
    this.onUnsubscribeNotification = this.onUnsubscribeNotification.bind(this)
    this.onUnpublishNotification = this.onUnpublishNotification.bind(this)

    // Actions.
    this.onPublish = this.onPublish.bind(this)
    this.onSubscribe = this.onSubscribe.bind(this)
    this.onStop = this.onStop.bind(this)

    this.state = {
      hasPermissions: false,
      isPublisher: false,
      streamNameFieldProps: {
        placeholder: 'Stream Name',
        autoCorrect: false,
        underlineColorAndroid: '#00000000',
        clearTextOnFocus: true,
        style: styles.inputField
      },
      videoProps: {
        ref: 'video',
        key: 'video',
        configuration: {
          host: host,
          licenseKey: licenseKey,
          bundleID: bundleID,
          key: Math.floor(Math.random() * 0x10000).toString(16)
        },
        logLevel: R5LogLevel.DEBUG,
        onMetaData: this.onMetaData,
        onConfigured: this.onConfigured,
        onPublisherStreamStatus: this.onPublisherStreamStatus,
        onSubscriberStreamStatus: this.onSubscriberStreamStatus,
        onUnsubscribeNotification: this.onUnsubscribeNotification,
        onUnpublishNotification: this.onUnpublishNotification
      }
    }
  }

  componentDidMount () {
    Permissions.checkMultiple(['camera', 'microphone'])
      .then((response) => {
        const isAuthorized = /authorized/
        const hasCamera = isAuthorized.test(response.camera)
        const hasMic = isAuthorized.test(response.microphone)

        if (!hasCamera || !hasMic) {
          this.requestPermissions()
          this.setState({hasPermissions: false})
        } else {
          this.setState({hasPermissions: true})
        }
      })
  }

  render() {
    return (
      <View style={styles.container}>
        <Text>Open up App.js to start working on your app!</Text>
        <Text>Changes you make will automatically reload.</Text>
        <Text>Shake your phone to open the developer menu.</Text>
        <R5MultiStreamView {...this.state.videoProps} />
      </View>
    )
  }

  requestPermissions () {
    const isAuthorized = /authorized/
    let camPermission = false
    let micPermission = false

    Permissions.request('camera')
      .then((camResponse) => {
        camPermission = isAuthorized.test(camResponse)

        Permissions.request('microphone')
          .then((micResponse) => {
            micPermission = isAuthorized.test(micResponse)

            this.setState({hasPermissions: camPermission && micPermission})
          })
      })
  }

  onMetaData (event) {
    console.log(`onMetadata(${event.nativeEvent.streamName}) :: ${event.nativeEvent.metadata}`)
  }

  onConfigured (event) {
    console.log(`onConfigured(${event.nativeEvent.streamName}) :: ${event.nativeEvent.key}`)
    /*
    this.refs.video.setState({
      configured: true
    })
    if (this.state.isPublisher) {
      publish(findNodeHandle(this.refs.video), this.state.videoProps.configuration.streamName)
    }
    else {
      subscribe(findNodeHandle(this.refs.video), this.state.videoProps.configuration.streamName)
    }
    */
  }
  
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    alignItems: 'center',
    justifyContent: 'center'
  }
})
