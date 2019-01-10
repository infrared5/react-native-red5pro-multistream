import { NativeModules } from 'react-native'
import R5AudioMode from '../enum/R5VideoView.audiomode'
import R5PublishType from '../enum/R5VideoView.publishtype'
const { R5MultiStreamViewManager } = NativeModules

export const subscribe = (handle, streamName, host, context, withVideo, audioMode = R5AudioMode.STANDARD) => R5MultiStreamViewManager.subscribe(streamName, host, context, withVideo, audioMode)
export const unsubscribe = (handle, streamName) => R5MultiStreamViewManager.unsubscribe(streamName)
export const preview = (handle, streamName) => R5MultiStreamViewManager.preview(streamName)
export const publish = (handle, streamName, host, context, withVideo, width = 640, height = 480, streamType = R5PublishType.LIVE) => R5MultiStreamViewManager.publish(streamName, host, context, withVideo, width, height, streamType)
export const unpublish = (handle, streamName) => R5MultiStreamViewManager.unpublish(streamName)
export const sendToBackground = (handle, streamName) => R5MultiStreamViewManager.sendToBackground(streamName)
export const returnToForeground = (handle, streamName) => R5MultiStreamViewManager.returnToForeground(streamName)
export const swapCamera = (handle, streamName) => R5MultiStreamViewManager.swapCamera(streamName)
export const updateScaleMode = (handle, streamName, scale) => R5MultiStreamViewManager.updateScaleMode(streamName, scale)
export const updateScaleSize = (handle, streamName, width, height, screenWidth, screenHeight) => R5MultiStreamViewManager.updateScaleSize(streamName, width, height, screenWidth, screenHeight)
export const shutdown = (handle) => R5MultiStreamViewManager.shutdown()
export const setPermissionsFlag = (handle, flag) => R5MultiStreamViewManager.setPermissionsFlag(flag)
