import { NativeModules } from 'react-native'
import R5AudioMode from '../enum/R5VideoView.audiomode'
import R5PublishType from '../enum/R5VideoView.publishtype'

const { UIManager } = NativeModules
const { R5MultiVideoView } = UIManager
const { Commands } = R5MultiVideoView

export const subscribe = (handle, streamName, host, context,
  withVideo,
  audioMode = R5AudioMode.STANDARD) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.subscribe, [
    streamName,
    host,
    context,
    withVideo])
}

export const unsubscribe = (handle, streamName) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.unsubscribe, [streamName])
}

export const preview = (handle, streamName) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.preview, [streamName])
}

export const publish = (handle, streamName, host, context,
  withVideo, width, height,
  streamType = R5PublishType.LIVE) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.publish, [
    streamName,
    host,
    context,
    withVideo,
    width,
    height,
    streamType
  ])
}

export const unpublish = (handle, streamName) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.unpublish, [streamName])
}

export const swapCamera = (handle, streamName) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.swapCamera, [streamName])
}

export const updateScaleMode = (handle, streamName, mode) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.updateScaleMode, [streamName, mode])
}

export const updateScaleSize = (handle,
  streamName,
  width, height,
  screenWidth, screenHeight) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.updateScaleSize, [
    streamName,
    width,
    height,
    screenWidth,
    screenHeight
  ])
}

export const shutdown = (handle) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.swapCamera, [streamName])
}