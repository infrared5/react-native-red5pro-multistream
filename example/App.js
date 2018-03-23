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

const host = '18.218.79.30'
const licenseKey = 'IBBB-LOPP-I32M-UIOS'
const bundleID = 'com.red5pro.multistream'

const streamlistURL = 'https://nafarat.red5.org/streammanager/api/2.0/event/list'
const subscribeURL = 'https://nafarat.red5.org/streammanager/api/2.0/event/live/{streamName}?action=subscribe'

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

    this._checkForSubscriptionStreams = this._checkForSubscriptionStreams.bind(this)
    this._updateSubscriberList = this._updateSubscriberList.bind(this)

    this.state = {
      hasPermissions: false,
      publisherSelection: PubType.NONE,
      streamName: undefined,
      subscriberList: [],
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

  componentWillUpdate (nextProps, nextState) {
    const currentSubs = this.state.subscriberList
    const currentLength = currentSubs.length;
    const nextSubs = nextState.subscriberList
    if (currentLength < nextSubs.length) {
      const newSubs = nextSubs.slice(currentLength - 1)
      newSubs.map((sub, index) => {
        const withVideo = sub.name.match(/video/)
        subscribe(findNodeHandle(this.red5pro_multistream),
          sub.name,
          sub.serverAddress,
          sub.scope,
          withVideo)
      })
    } else if (currentLength > nextSubs.length) {
      // TODO: unsubscribe
    }
  }

  componentDidUpdate (prevProps, prevState) {
    if (prevState.publisherSelecion !== this.state.publisherSelection &&
        this.state.publisherSelection !== PubType.NONE) {
      const withVideo = this.state.publisherSelection === PubType.VIDEO
      publish(findNodeHandle(this.red5pro_multistream),
        this.state.streamName,
        host,
        'live',
        withVideo)
      this._checkForSubscriptionStreams(streamlistURL)
    }
  }

  render() {
    if (this.state.hasPermissions && this.state.publisherSelection !== PubType.NONE) {
      const assignVideoRef = (video) => { this.red5pro_multistream = video }
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

  _updateSubscriberList (json) {
    console.log(json)
    const mystream = this.state.streamName
    const currentStreamList = this.state.subscriberList
    const availableSubscribers = json.filter((stream, index) => {
      let isSubscribing = false
      let index = currentStreamList.length
      while(--index > -1) {
        isSubscribing = currentStreamList[index].name === stream.name
      }
      return stream.name !== mystream && !isSubscribing
    })

    console.log(availableSubscribers)
    if (availableSubscribers.length > 0) {
      this.setState({
        subscriberList: [...currentList, availableSubscribers]
      })
    }

    let timeout = setTimeout(() => {
      clearTimeout(timeout)
      this._checkForSubscriptionStreams(streamlistURL)
    }, 5000)

  }

  _checkForSubscriptionStreams (url) {
    fetch(url, {
      method: 'GET',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json'
      }
    })
    .then((response) => response.json())
    .then((json) => {
      if (json.errorMessage) {
        console.error(json.errorMessage)
      } else {
        this._updateSubscriberList(json)
      }
    })
    .catch((error) => {
      console.log(error)
    })
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
    const randomId = Math.floor(Math.random() * 0x10000).toString(16)
    this.setState({
      streamName: 'red5pro-videoStream-' + randomId,
      publisherSelection: PubType.VIDEO
    })
  }

  onPublishAudio () {
    const randomId = Math.floor(Math.random() * 0x10000).toString(16)
    this.setState({
      streamName: 'red5pro-audioStream-' + randomId,
      publisherSelection: PubType.AUDIO
    })
  }

  onSubscribe () {
  }

  onStop () {
    unpublish(findNodeHandle(this.red5pro_multistream), this.state.streamName)
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
