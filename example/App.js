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

const host = '52.77.244.201'
const licenseKey = 'IBBB-LOPP-I32M-UIOS'
const bundleID = 'com.red5pro.multistream'

const PubType = {
  NONE: 0,
  AUDIO: 1,
  VIDEO: 2
}

const isValidStatusMessage = (value) => {
  return value && typeof value !== 'undefined' && value !== 'undefined' && value !== 'null'
}

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
    this.onPublishAudio = this.onPublishAudio.bind(this)
    this.onSubscribe = this.onSubscribe.bind(this)
    this.onStop = this.onStop.bind(this)

    this.state = {
      hasPermissions: false,
      publisherSelection: PubType.NONE,
      streamName: undefined,
      streamNameFieldProps: {
        placeholder: 'Stream Name',
        autoCorrect: false,
        underlineColorAndroid: '#00000000',
        clearTextOnFocus: true,
        style: styles.inputField
      },
      videoProps: {
        style: styles.videoView,
        licenseKey: licenseKey,
        bundleID: bundleID,
        configuration: {
          host: host
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

  componentDidUpdate (prevProps, prevState) {
    if (prevState.publisherSelecion !== this.state.publisherSelection &&
        this.state.publisherSelection !== PubType.NONE) {
      const withVideo = this.state.publisherSelection === PubType.VIDEO
      publish(findNodeHandle(this.red5provideo_publisher),
        this.state.streamName,
        host,
        'live',
        withVideo)
    }
  }

  render() {
    if (this.state.hasPermissions && this.state.publisherSelection !== PubType.NONE) {
      const assignVideoRef = (video) => { this.red5provideo_publisher = video }
      return (
        <View style={styles.container}>
          <R5MultiStreamView
            ref={assignVideoRef}
            {...this.state.videoProps} 
          />
          <Button title="Stop" onPress={this.onStop} />
        </View>
      )
    } else if (this.state.hasPermissions) {
      return (
        <View style={[styles.container, { alignItems: 'center', justifyContent: 'space-between' }]}>
          <Button style={{ marginBottom: 20 }} onPress={this.onPublishAudio} title="Publish Audio" />
          <Button onPress={this.onPublish} title="Publish Video+Audio" />
        </View>
      )
    }

    return (
      <View style={styles.container}>
        <Text>Waiting for permissions...</Text>
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
    console.log(`onConfigured :: ${event.nativeEvent.key}`)
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

  onPublisherStreamStatus (event) {
    console.log(`onPublisherStreamStatus :: ${JSON.stringify(event.nativeEvent.status, null, 2)}`)
    const status = event.nativeEvent.status
    let message = isValidStatusMessage(status.message) ? status.message : status.name
      /*
    if (!this.state.inErrorState) {
      this.setState({
        toastProps: {...this.state.toastProps, value: message},
        isInErrorState: (status.code === 2)
      })
    }
    */
  }

  onSubscriberStreamStatus (event) {
    console.log(`onSubscriberStreamStatus :: ${JSON.stringify(event.nativeEvent.status, null, 2)}`)
    const status = event.nativeEvent.status
    let message = isValidStatusMessage(status.message) ? status.message : status.name
      /*
    if (!this.state.inErrorState) {
      this.setState({
        toastProps: {...this.state.toastProps, value: message},
        isInErrorState: (status.code === 2)
      })
    }
    */
  }

  onUnsubscribeNotification (event) {
    console.log(`onUnsubscribeNotification:: ${JSON.stringify(event.nativeEvent.status, null, 2)}`)
      /*
    this.setState({
      hasStarted: false,
      isInErrorState: false,
      toastProps: {...this.state.toastProps, value: 'waiting...'}
    })
    */
  }

  onUnpublishNotification (event) {
    console.log(`onUnpublishNotification:: ${JSON.stringify(event.nativeEvent.status, null, 2)}`)
      /*
    this.setState({
      hasStarted: false,
      isInErrorState: false,
      toastProps: {...this.state.toastProps, value: 'waiting...'}
    })
    */
  }

  onPublish () {
    const randomId = `red5pro-${Math.floor(Math.random() * 0x10000).toString(16)}`
    this.setState({
      streamName: 'videoStream' + randomId,
      publisherSelection: PubType.VIDEO
    })
  }

  onPublishAudio () {
    const randomId = `red5pro-${Math.floor(Math.random() * 0x10000).toString(16)}`
    this.setState({
      streamName: 'audioStream' + randomId,
      publisherSelection: PubType.AUDIO
    })
  }

  onSubscribe () {
  }

  onStop () {
    unpublish(findNodeHandle(this.red5provideo_publisher), this.state.streamName)
    this.setState({
      streamName: undefined,
      publisherSelection: PubType.NONE
    })
  }
  
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    justifyContent: 'center'
  },
  videoView: {
    flex: 1,
    flexDirection: 'row',
    // justifyContent: 'center',
    backgroundColor: 'black'
  }
})
