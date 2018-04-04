import React from 'react'
import {
  findNodeHandle,
  Alert,
  Button,
  Dimensions,
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
  unpublish,
  shutdown,
  updateScaleSize
} from 'react-native-red5pro-multistream'

const host = '18.218.79.30'
const licenseKey = 'BWAP-WF5E-JZU2-6I5G'
const bundleID = 'com.red5pro.multistream'

const streamlistURL = 'https://nafarat.red5.org/streammanager/api/2.0/event/list'
const subscribeURL = 'https://${sm-host}/streammanager/api/2.0/event/live/{streamName}?action=subscribe'

const window = Dimensions.get('window')

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

    this.streamCheckTimer = 0
    this.bannedList = []

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
    this.onToggle = this.onToggle.bind(this)

    this._checkForSubscriptionStreams = this._checkForSubscriptionStreams.bind(this)
    this._updateSubscriberList = this._updateSubscriberList.bind(this)

    this.state = {
      toggled: false,
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
        showDebug: true,
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
      const newSubs = currentLength > 0 ? nextSubs.slice(currentLength - 1) : nextSubs
      newSubs.map((sub, index) => {
        const withVideo = sub.name.match(/r5pro2-video/)
        const withAudio = sub.name.match(/r5pro2-audio/)
        if (!withVideo && !withAudio) {
          return false
        }
        console.log('SUBSCRIBE', sub)
        subscribe(findNodeHandle(this.red5pro_multistream),
          sub.name,
          sub.serverAddress,
          sub.scope.substring(1, sub.scope.length),
          withVideo === null ? false : true)
      })
    } else if (currentLength > nextSubs.length) {
      // TODO: unsubscribe
    }
  }

  componentDidUpdate (prevProps, prevState) {
    if (prevState.publisherSelection !== this.state.publisherSelection &&
        this.state.publisherSelection !== PubType.NONE) {
      console.log('PUBLISH', this.state.streamName)
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
      const subscribers = this.state.subscriberList.map((subscriber, index) => {
        return (
          <View key={`subscriber-${index}`} style={styles.subscriberTag}>
            <Text>{subscriber.name}</Text>
          </View>
        )
      })
      return (
        <View style={styles.container}>
          <R5MultiStreamView
            ref={assignVideoRef}
            {...this.state.videoProps} 
          />
          {subscribers}
          <Button title="Toggle" onPress={this.onToggle} style={{ flex: 1, height: 60, flexBasis: 60 }} />
          <Button title="Stop" onPress={this.onStop} style={{ flex: 1, height: 60, flexBasis: 60 }} />
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
    const mystream = this.state.streamName
    const currentStreamList = this.state.subscriberList
    const availableSubscribers = json.filter((stream, index) => {
      const withVideo = stream.name.match(/r5pro2-video/)
      const withAudio = stream.name.match(/r5pro2-audio/)
      let i = currentStreamList.length
      while (--i > -1) {
        if (currentStreamList[i].name === stream.name) {
          return false
        }
      }
      return stream.name !== mystream && (withVideo || withAudio)
    })
    if (availableSubscribers.length > 0) {
      this.setState({
        subscriberList: currentStreamList.concat(availableSubscribers)
      })
    }

    this.streamCheckTimer = setTimeout(() => {
      clearTimeout(this.streamCheckTimer)
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
    .then(function (res) {
      if (res.headers.get('content-type') &&
          res.headers.get('content-type').toLowerCase().indexOf('application/json') >= 0) {
        return res.json()
      }
      else {
        return res.text()
      }
    })
    .then((json) => {
      if (json.errorMessage) {
        console.error(json.errorMessage)
      } else {
        const list = typeof json === 'string' ? JSON.parse(json) : json
        list.map((arr, index) => arr.constructor === Array ? arr[0] : arr)
        this._updateSubscriberList(list)
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
    const { status, streamName } = event.nativeEvent
    console.log(`onPublisherStreamStatus :: ${JSON.stringify(status, null, 2)}`)
    let message = isValidStatusMessage(status.message) ? status.message : status.name
    if (status.name === 'ERROR') {
      this.bannedList.push(streamName)
      Alert.alert('Stream Error', `${streamName}: ${message}`)
    }
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
    const { status, streamName } = event.nativeEvent
    console.log(`onSubscriberStreamStatus :: ${JSON.stringify(status, null, 2)}`)
    let message = isValidStatusMessage(status.message) ? status.message : status.name
    if (status.name === 'CLOSE' ||
        (status.name === 'NET_STATUS' && status.message === 'NetStream.Play.UnpublishNotify')) {
      unsubscribe(findNodeHandle(this.red5pro_multistream), streamName)
      const streams = this.state.subscriberList.filter((sub, index) => {
        return sub.name !== streamName
      })
      this.setState({
        subscriberList: streams
      })
    }
    else if (status.name === 'ERROR') {
      this.bannedList.push(streamName)
      Alert.alert('Stream Error', `${streamName}: ${message}`)
    }
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
      streamName: 'r5pro2-videoStream-' + randomId,
      publisherSelection: PubType.VIDEO
    })
  }

  onPublishAudio () {
    const randomId = Math.floor(Math.random() * 0x10000).toString(16)
    this.setState({
      streamName: 'r5pro2-audioStream-' + randomId,
      publisherSelection: PubType.AUDIO
    })
  }

  onSubscribe () {
  }

  onStop () {
    //    unpublish(findNodeHandle(this.red5pro_multistream), this.state.streamName)
    clearTimeout(this.streamCheckTimer)
    shutdown(findNodeHandle(this.red5pro_multistream))
    this.setState({
      streamName: undefined,
      subscriberList: [],
      publisherSelection: PubType.NONE
    })
  }

  onToggle () {
    if (this.state.toggled) {
      updateScaleSize(findNodeHandle(this.red5pro_multistream), this.state.streamName,  parseInt(window.width, 10), parseInt(window.height, 10), parseInt(window.width, 10), parseInt(window.height, 10))
    } else {
      updateScaleSize(findNodeHandle(this.red5pro_multistream), this.state.streamName, 120, 120, parseInt(window.width, 10), parseInt(window.height, 10))
    }
    this.setState({ toggled: !this.state.toggled })
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
  },
  subscriberTag: {
    flex: 0,
    flexBasis: 20,
    flexDirection: 'row',
    alignContent: 'center',
    alignItems: 'center'
  }
})
