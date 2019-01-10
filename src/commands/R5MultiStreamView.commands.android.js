import { NativeModules } from 'react-native'
import R5AudioMode from '../enum/R5VideoView.audiomode'
import R5PublishType from '../enum/R5VideoView.publishtype'

const { UIManager } = NativeModules
const { R5MultiStreamView } = UIManager
const { Commands } = R5MultiStreamView

export const subscribe = (handle, streamName,
  host,
  context,
  withVideo,
  audioMode = R5AudioMode.STANDARD) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.subscribe, [
    streamName,
    host,
    context,
    withVideo,
    audioMode])
}

export const unsubscribe = (handle, streamName) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.unsubscribe, [streamName])
}

export const preview = (handle, streamName) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.preview, [streamName])
}

export const publish = (handle, streamName,
  host,
  context,
  withVideo,
  cameraWidth = 640,
  cameraHeight = 360,
  streamType = R5PublishType.LIVE) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.publish, [
    streamName,
    host,
    context,
    withVideo,
    cameraWidth,
    cameraHeight,
    streamType
  ])
}

export const unpublish = (handle, streamName) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.unpublish, [streamName])
}

export const sendToBackground = (handle, streamName) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.sendToBackground, [streamName])
}

export const returnToForeground = (handle, streamName) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.returnToForeground, [streamName])
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
  UIManager.dispatchViewManagerCommand(handle, Commands.shutdown, [])
}

export const setPermissionsFlag = (handle, flag) => {
  UIManager.dispatchViewManagerCommand(handle, Commands.setPermissionsFlag, ['unknown:permissions', flag])
}
