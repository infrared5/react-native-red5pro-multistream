import React from 'react'
import PropTypes from 'prop-types'
import R5LogLevel from '../enum/R5VideoView.loglevel'
import { requireNativeComponent, ViewPropTypes } from 'react-native'

class R5MultiStreamView extends React.Component {

  constructor (props) {
    super(props)
    this._onMetaData = this._onMetaData.bind(this)
    this._onConfigured = this._onConfigured.bind(this)
    this._onPublisherStreamStatus = this._onPublisherStreamStatus.bind(this)
    this._onSubscriberStreamStatus = this._onSubscriberStreamStatus.bind(this)
    this._onUnpublishNotification = this._onUnpublishNotification.bind(this)
    this._onUnsubscribeNotification = this._onUnsubscribeNotification.bind(this)
    this._refHandle = this._refHandle.bind(this)

    this.state = {
      configured: false
    }
  }

  shouldComponentUpdate (nextProps, nextState) {
    if (this.state.configured !== nextState.configured) {
      return true
    }
    return false
  }

  _onMetaData = (event) => {
    if (!this.props.onMetaData) {
      return
    }
    this.props.onMetaData(event)
  }

  _onConfigured = (event) => {
    if (!this.props.onConfigured) {
      return
    }
    this.props.onConfigured(event)
  }

  _onPublisherStreamStatus = (event) => {
    if (!this.props.onPublisherStreamStatus) {
      return
    }
    this.props.onPublisherStreamStatus(event)
  }

  _onSubscriberStreamStatus = (event) => {
    if (!this.props.onSubscriberStreamStatus) {
      return
    }
    this.props.onSubscriberStreamStatus(event)
  }

  _onUnsubscribeNotification = (event) => {
    if (!this.props.onUnsubscribeNotification) {
      return
    }
    this.props.onUnsubscribeNotification(event)
  }

  _onUnpublishNotification = (event) => {
    if (!this.props.onUnpublishNotification) {
      return
    }
    this.props.onUnpublishNotification(event)
  }

  _refHandle = (video) => {
    this.red5provideo = video
  }

  _onLayout = (event) => {
    // const layout = event.nativeEvent.layout
    // console.log(`R5MultiStream:onLayout: ${event.nativeEvent.layout.x}, ${event.nativeEvent.layout.y}, ${event.nativeEvent.layout.width}x${event.nativeEvent.layout.height}`);
  }

  render() {
    let elementRef = this.props.videoRef ? this.props.videoRef : this._refHandle
    return <R5MultiStream
            ref={elementRef}
            {...this.props}
            onLayout={this._onLayout}
            onMetaDataEvent={this._onMetaData}
            onConfigured={this._onConfigured}
            onPublisherStreamStatus={this._onPublisherStreamStatus}
            onSubscriberStreamStatus={this._onSubscriberStreamStatus}
            onUnsubscribeNotification={this._onUnsubscribeNotification}
            onUnpublishNotification={this._onUnpublishNotification}
          />
  }

}

R5MultiStreamView.propTypes = {
    showDebugView: PropTypes.bool,
    logLevel: PropTypes.oneOf([R5LogLevel.ERROR, R5LogLevel.WARN, R5LogLevel.INFO, R5LogLevel.DEBUG]),
    licenseKey: PropTypes.string.isRequired,
    bundleID: PropTypes.string.isRequired,
    bitrate: PropTypes.number,                      // publisher only, kb/s
    framerate: PropTypes.number,                    // publisher only, fps
    useAdaptiveBitrateController: PropTypes.bool,   // publisher only
    bufferTime: PropTypes.number,
    streamBufferTime: PropTypes.number,
    key: PropTypes.string.isRequired,
    onConfigured: PropTypes.func,
    onMetaDataEvent: PropTypes.func,
    onPublisherStreamStatus: PropTypes.func,
    onSubscriberStreamStatus: PropTypes.func,
    onUnsubscribeNotification: PropTypes.func,
    onUnpublishNotification: PropTypes.func,
    ...ViewPropTypes
}
R5MultiStreamView.defaultProps = {
  showDebugView: false,
  logLevel: R5LogLevel.ERROR,
  bitrate: 750,
  framerate: 15,
  useAdaptiveBitrateController: false,
  bufferTime: 0.5,
  streamBufferTime: 2
}

let R5MultiStream = requireNativeComponent('R5MultiStreamView', R5MultiStreamView)

export default R5MultiStreamView

