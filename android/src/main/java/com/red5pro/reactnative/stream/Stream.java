package com.red5pro.reactnative.stream;

import com.red5pro.streaming.config.R5Configuration;
import com.red5pro.streaming.view.R5VideoView;

/**
 * Created by toddanderson on 3/22/18.
 */

public interface Stream {

    public void start();
    public void stop();
    public void pause();
    public void resume();

    public void updateScaleSize(final int width, final int height, final int screenWidth, final int screenHeight);

    public int getLogLevel();
    public void setLogLevel(int level);

    public R5VideoView getView();

}
