import { NativeModules } from 'react-native'
import R5AudioMode from '../enum/R5VideoView.audiomode'
import R5PublishType from '../enum/R5VideoView.publishtype'
const { R5MultiVideoViewManager } = NativeModules

export const subscribe = (handle, streamName, host, context, withVideo) => R5MultiVideoViewManager.subscribe(streamName, host, context, withVideo)
export const unsubscribe = (handle, streamName) => R5MultiVideoViewManager.unsubscribe(streamName)
export const preview = (handle, streamName) => R5MultiVideoViewManager.preview(streamName)
export const publish = (handle, streamName, host, context, withVideo, width, height, streamType = R5PublishType.LIVE) => R5MultiVideoViewManager.publish(streamName, host, context, withVideo, width, height, streamType)
export const unpublish = (handle, streamName) => R5MultiVideoViewManager.unpublish(streamName)
export const swapCamera = (handle, streamName) => R5MultiVideoViewManager.swapCamera(streamName)
export const updateScaleMode = (handle, streamName, scale) => R5MultiVideoViewManager.updateScaleMode(streamName, scale)
export const updateScaleSize = (handle, streamName, width, height, screenWidth, screenHeight) => R5MultiVideoViewManager.updateScaleSize(streamName, width, height, screenWidth, screenHeight)
export const shutdown = (handle) => R5MultiVideoViewManager.shutdown()

