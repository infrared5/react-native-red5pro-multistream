import R5MultiVideoView from './src/view/R5MultiVideoView'
import R5AudioMode from './src/enum/R5VideoView.audiomode'
import R5LogLevel from './src/enum/R5VideoView.loglevel'
import R5PublishType from './src/enum/R5VideoView.publishtype'
import R5ScaleMode from './src/enum/R5VideoView.scalemode'

import {
  subscribe,
  unsubscribe,
  preview,
  publish,
  unpublish,
  swapCamera,
  updateScaleMode,
  updateScaleSize
} from './src/commands/R5MultiVideoView.commands'

module.exports = {
  R5MultiVideoView,
  subscribe, unsubscribe, preview, publish, unpublish,
  swapCamera, updateScaleMode, updateScaleSize,
  R5AudioMode, R5LogLevel, R5PublishType, R5ScaleMode
}

