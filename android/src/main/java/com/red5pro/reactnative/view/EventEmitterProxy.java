package com.red5pro.reactnative.view;

import com.facebook.react.bridge.WritableMap;

/**
 * Created by toddanderson on 3/22/18.
 */

public interface EventEmitterProxy {

    public void dispatchEvent(String streamName, String type, WritableMap map);

}
