package com.red5pro.reactnative.view;

import android.app.Activity;
import android.util.Log;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.common.MapBuilder;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.annotations.ReactProp;

import com.red5pro.streaming.R5Stream;
import com.red5pro.streaming.R5StreamProtocol;
import com.red5pro.streaming.config.R5Configuration;

import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import javax.annotation.Nullable;

public class R5MultiVideoViewManager extends SimpleViewManager<R5MultiVideoViewLayout> {

    private static final String REACT_CLASS = "R5MultiVideoView";

    private static final int COMMAND_SUBSCRIBE = 1;
    private static final int COMMAND_PUBLISH = 2;
    private static final int COMMAND_UNSUBSCRIBE = 3;
    private static final int COMMAND_UNPUBLISH = 4;
    private static final int COMMAND_SWAP_CAMERA = 5;
    private static final int COMMAND_UPDATE_SCALE_MODE = 6;
    private static final int COMMAND_PREVIEW = 7;
    private static final int COMMAND_UPDATE_SCALE_SIZE = 8;
    private static final int COMMAND_SHUTDOWN = 9;

    private R5MultiVideoViewLayout mView;
    private ThemedReactContext mContext;

    public R5MultiVideoViewManager() {
        super();
    }

    @Override
    public String getName() {
        return REACT_CLASS;
    }

    @Override
    protected R5MultiVideoViewLayout createViewInstance(ThemedReactContext reactContext) {

        mContext = reactContext;
        mView = new R5MultiVideoViewLayout(reactContext);
        return mView;

    }

    @Override
    public void receiveCommand(final R5MultiVideoViewLayout root, int commandId, @Nullable ReadableArray args) {

        if (args != null) {
            Log.d("R5MultiVideoViewManager", "Args are " + args.toString());
        }

        final String streamName = args.size() > 0 ? args.getString(0) : null;

        switch (commandId) {
            case COMMAND_PREVIEW:

//                root.setupPublisher(streamName, true);

                break;
            case COMMAND_SUBSCRIBE:

                final String host = args.getString(1);
                final String context = args.getString(2);
                final Boolean withVideo = args.getBoolean(3);
                final int audioMode = args.getInt(4);
                root.subscribe(streamName, host, context, withVideo, audioMode);

                break;
            case COMMAND_PUBLISH:

                final String host = args.getString(1);
                final String context = args.getString(2);
                final Boolean withVideo = args.getBoolean(3);
                final int cameraWidth = args.getInt(4);
                final int cameraHeight = args.getInt(5);
                final int type = args.getInt(6);

                R5Stream.RecordType recordType = R5Stream.RecordType.Live;
                if (type == 1) {
                    recordType = R5Stream.RecordType.Record;
                }
                else if (type == 2) {
                    recordType = R5Stream.RecordType.Append;
                }
                root.publish(streamName, host, context, withVideo, cameraWidth, cameraHeight, recordType);

                break;
            case COMMAND_UNSUBSCRIBE:

                root.unsubscribe(streamName);

                break;
            case COMMAND_UNPUBLISH:

                root.unpublish(streamName);

                break;
            case COMMAND_SWAP_CAMERA:

                root.swapCamera(streamName);

                break;
            case COMMAND_UPDATE_SCALE_MODE:

                final int mode = args.getInt(1);
                root.updateScaleMode(streamName, mode);

                break;
            case COMMAND_UPDATE_SCALE_SIZE:

                int updateWidth = args.getInt(1);
                int updateHeight = args.getInt(2);
                int screenWidth = args.getInt(3);
                int screenHeight = args.getInt(4);
                root.updateScaleSize(streamName, updateWidth, updateHeight, screenWidth, screenHeight);

                break;
            case COMMAND_SHUTDOWN:

                root.shutdown();

                break;
            default:
                super.receiveCommand(root, commandId, args);
                break;
        }
    }

    @Nullable
    @Override
    public Map<String, Integer> getCommandsMap() {
        MapBuilder.Builder<String, Integer> builder = MapBuilder.builder();
        for (R5MultiVideoViewLayout.Commands command : R5MultiVideoViewLayout.Commands.values()) {
            builder.put(command.toString(), command.getValue());
        }
        return builder.build();
    }

    @Override
    @Nullable
    public Map<String, Object> getExportedCustomDirectEventTypeConstants() {
        MapBuilder.Builder<String, Object> builder = MapBuilder.builder();
        for (R5MultiVideoViewLayout.Events event : R5MultiVideoViewLayout.Events.values()) {
            builder.put(event.toString(), MapBuilder.of("registrationName", event.toString()));
        }
        return builder.build();
    }

    @ReactProp(name = "showDebugView", defaultBoolean = false)
    public void setShowDebugView(R5MultiVideoViewLayout view, boolean showDebug) {
        view.updateShowDebug(showDebug);
    }

    @ReactProp(name = "logLevel", defaultInt = 3) // LOG_LEVEL_ERROR
    public void setLogLevel(R5MultiVideoViewLayout view, int logLevel) {
        view.updateLogLevel(logLevel);
    }

    @ReactProp(name = "licenseKey", defaultString = "")
    public void setLicenseKey(R5MultiVideoViewLayout view, String licenseKey) {
        view.updateLicenseKey(licenseKey);
    }

    @ReactProp(name = "bundleID", defaultString = "com.red5pro.android")
    public void setBundleID(R5MultiVideoViewLayout view, String bundleID) {
        view.updateBundleID(bundleID);
    }

    @ReactProp(name = "bitrate", defaultInt = 750)
    public void setBitrate(R5MultiVideoViewLayout view, int value) {
        view.updatePublishBitrate(value);
    }

    @ReactProp(name = "framerate", defaultInt = 15)
    public void setFramerate(R5MultiVideoViewLayout view, int value) {
        view.updatePublishFramerate(value);
    }

    @ReactProp(name = "useAdaptiveBitrateController", defaultBoolean = false)
    public void setUseAdaptiveBitrateController(R5MultiVideoViewLayout view, boolean value) {
        view.updatePublisherUseAdaptiveBitrateController(value);
    }

    @ReactProp(name = "bufferTime", defaultDouble = 0.5f)
    public void setBufferTime(R5MultiVideoViewLayout view, double value) {
        view.updateBufferTime(value);
    }

    @ReactProp(name = "streamBufferTime", defaultDouble = 2.0f)
    public void setStreamBufferTime(R5MultiVideoViewLayout view, double value) {
        view.updateStreamBufferTime(value);
    }

    @Nullable
    @Override
    public Map<String, Object> getConstants() {
        return super.getConstants();
    }

    @Override
    public boolean hasConstants() {
        return super.hasConstants();
    }

}
