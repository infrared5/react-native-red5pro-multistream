import R5MultiStreamView from './src/view/R5MultiStreamView'
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
} from './src/commands/R5MultiStreamView.commands'

module.exports = {
  R5MultiStreamView,
  subscribe, unsubscribe, preview, publish, unpublish,
  swapCamera, updateScaleMode, updateScaleSize,
  R5AudioMode, R5LogLevel, R5PublishType, R5ScaleMode
}

