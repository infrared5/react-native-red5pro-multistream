package com.red5pro.reactnative.stream;

import android.hardware.Camera;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Surface;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.red5pro.reactnative.view.EventEmitterProxy;
import com.red5pro.reactnative.view.R5MultiStreamLayout;
import com.red5pro.streaming.R5Connection;
import com.red5pro.streaming.R5Stream;
import com.red5pro.streaming.config.R5Configuration;
import com.red5pro.streaming.event.R5ConnectionEvent;
import com.red5pro.streaming.event.R5ConnectionListener;
import com.red5pro.streaming.media.R5AudioController;
import com.red5pro.streaming.source.R5AdaptiveBitrateController;
import com.red5pro.streaming.source.R5Camera;
import com.red5pro.streaming.source.R5Microphone;
import com.red5pro.streaming.view.R5VideoView;

/**
 * Created by toddanderson on 3/22/18.
 */

public class PublisherStream implements Stream, R5ConnectionListener {

    public int mLogLevel;

    protected String mStreamName;
    protected R5Stream.RecordType mStreamType;
    protected boolean mIsStreaming;

    protected R5Connection mConnection;
    protected R5Stream mStream;
    protected R5Camera mCamera;
    protected R5Microphone mMicrophone;
    protected R5VideoView mVideoView;
    protected boolean mUseBackfacingCamera = false;
    protected boolean mUseAudio = true;

    protected int mCameraOrientation;
    protected int mDisplayOrientation;
    protected boolean mOrientationDirty;
    protected int mOrigCamOrientation = 0;

    protected ThemedReactContext mContext;
    protected EventEmitterProxy mEventEmitter;

    public PublisherStream(ThemedReactContext context, EventEmitterProxy eventEmitterProxy, R5VideoView view) {

        mContext = context;
        mEventEmitter = eventEmitterProxy;
        mVideoView = view; // can be null

    }

    protected void cleanup() {

        Log.d("PublisherStream", ":cleanup (" + mStreamName + ")!");
        if (mStream != null) {
            mStream.client = null;
            mStream.setListener(null);
            mStream = null;
        }

//        if (mConnection != null) {
//            mConnection.removeListener();
//            mConnection = null;
//        }
//        if (mVideoView != null) {
//            mVideoView.attachStream(null);
//            mVideoView = null;
//        }

        mMicrophone = null;
//        mVideoView = null;

        mIsStreaming = false;

    }

    protected void setupCamera(int width, int height, int bitrate, int framerate) {

        try {
            Camera device = mUseBackfacingCamera
                    ? openBackFacingCameraGingerbread()
                    : openFrontFacingCameraGingerbread();

            updateDeviceOrientationOnLayoutChange();
            int rotate = mUseBackfacingCamera ? 0 : 180;
            device.setDisplayOrientation((mCameraOrientation + rotate) % 360);

            R5Camera camera = new R5Camera(device, width, height);
            camera.setBitrate(bitrate);
            camera.setOrientation(mCameraOrientation);
            camera.setFramerate(framerate);

            mCamera = camera;
            Camera.Parameters params = mCamera.getCamera().getParameters();
            params.setRecordingHint(true);
            mCamera.getCamera().setParameters(params);
        }
        catch(Exception e) {
            WritableMap map = new WritableNativeMap();
            WritableMap statusMap = new WritableNativeMap();
            statusMap.putInt("code", R5ConnectionEvent.ERROR.value());
            statusMap.putString("message", "Camera Issue. " + e.getMessage());
            statusMap.putString("name", R5ConnectionEvent.ERROR.name());
            map.putMap("status", statusMap);
            mEventEmitter.dispatchEvent(mStreamName, R5MultiStreamLayout.Events.PUBLISHER_STATUS.toString(), map);
        }

    }

    protected void setupMicrophone() {

        // Establish Microphone if requested.
        if (mUseAudio) {

            R5Microphone mic = new R5Microphone();
            mStream.attachMic(mic);
            mic.setBitRate(32);
            // e.g., ->
            // This is required to be 8000 in order for 2-Way to work.
            mStream.audioController.sampleRate = 8000;
            mMicrophone = mic;

        }

    }

    protected Camera openFrontFacingCameraGingerbread() {

        int cameraCount = 0;
        Camera cam = null;
        Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
        cameraCount = Camera.getNumberOfCameras();
        for (int camIdx = 0; camIdx < cameraCount; camIdx++) {
            Camera.getCameraInfo(camIdx, cameraInfo);
            if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
                try {
                    cam = Camera.open(camIdx);
                    mCameraOrientation = cameraInfo.orientation;
                    applyDeviceRotation();
                    break;
                } catch (RuntimeException e) {
                    e.printStackTrace();
                }
            }
        }

        return cam;

    }

    protected Camera openBackFacingCameraGingerbread() {

        int cameraCount = 0;
        Camera cam = null;
        Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
        cameraCount = Camera.getNumberOfCameras();
        for (int camIdx = 0; camIdx < cameraCount; camIdx++) {
            Camera.getCameraInfo(camIdx, cameraInfo);
            if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_BACK) {
                try {
                    cam = Camera.open(camIdx);
                    mCameraOrientation = cameraInfo.orientation;
                    applyInverseDeviceRotation();
                    break;
                } catch (RuntimeException e) {
                    e.printStackTrace();
                }
            }
        }

        return cam;

    }

    protected void applyInverseDeviceRotation(){

        int degrees = 0;
        int rotation = mContext.getCurrentActivity().getWindowManager().getDefaultDisplay().getRotation();

        switch (rotation) {
            case Surface.ROTATION_0: degrees = 0; break;
            case Surface.ROTATION_90: degrees = 270; break;
            case Surface.ROTATION_180: degrees = 180; break;
            case Surface.ROTATION_270: degrees = 90; break;
        }

        mCameraOrientation += degrees;
        mCameraOrientation = mCameraOrientation % 360;
        mOrigCamOrientation = mCameraOrientation;

    }

    protected void applyDeviceRotation () {

        int degrees = 0;
        int rotation = mContext.getCurrentActivity().getWindowManager().getDefaultDisplay().getRotation();

        switch (rotation) {
            case Surface.ROTATION_0: degrees = 0; break;
            case Surface.ROTATION_90: degrees = 90; break;
            case Surface.ROTATION_180: degrees = 180; break;
            case Surface.ROTATION_270: degrees = 270; break;
        }

        mCameraOrientation += degrees;
        mCameraOrientation = mCameraOrientation % 360;
        mOrigCamOrientation = mCameraOrientation;

    }

    public void onMetaData(String metadata) {

        WritableMap map = new WritableNativeMap();
        map.putString("metadata", metadata);
        mEventEmitter.dispatchEvent(mStreamName, R5MultiStreamLayout.Events.METADATA.toString(), map);

    }

    public void init(R5Configuration configuration,
                     int cameraWidth, int cameraHeight,
                     int bitrate, int framerate,
                     R5Stream.RecordType streamType,
                     boolean useABR) {

//        R5AudioController.mode = mAudioMode == 1
//                ? R5AudioController.PlaybackMode.STANDARD
//                : R5AudioController.PlaybackMode.AEC;

        mStreamType = streamType;
        mStreamName = configuration.getStreamName();
        mConnection = new R5Connection(configuration);
        mStream = new R5Stream(mConnection);

        Log.d("PublisherStream", ":init (" + mStreamName + ")!");

        mStream.setListener(this);
        mStream.client = this;

        mStream.setLogLevel(mLogLevel);

        if (mVideoView != null) {
            setupCamera(cameraWidth, cameraHeight, bitrate, framerate);
        }

        if (mUseAudio) {
            setupMicrophone();
        }

        // Assign ABR Controller if requested.
        if (useABR) {
            R5AdaptiveBitrateController adaptor = new R5AdaptiveBitrateController();
            adaptor.AttachStream(mStream);
        }

        if (mVideoView != null) {
            mVideoView.attachStream(mStream);
        }

        if (mCamera != null) {
            mStream.attachCamera(mCamera);
        }

    }

    public void swapCamera() {

        if (mCamera != null) {

            Camera updatedCamera;

            // NOTE: Some devices will throw errors if you have a camera open when you attempt to open another
            mCamera.getCamera().stopPreview();
            mCamera.getCamera().release();

            // NOTE: The front facing camera needs to be 180 degrees further rotated than the back facing camera
            int rotate = 0;
            if (!mUseBackfacingCamera) {
                updatedCamera = openBackFacingCameraGingerbread();
                rotate = 0;
            }
            else {
                updatedCamera = openFrontFacingCameraGingerbread();
                rotate = 180;
            }

            if(updatedCamera != null) {
                updatedCamera.setDisplayOrientation((mCameraOrientation + rotate) % 360);
                mCamera.setCamera(updatedCamera);
                mCamera.setOrientation(mCameraOrientation);

                updatedCamera.startPreview();
                mUseBackfacingCamera = !mUseBackfacingCamera;
                mStream.updateStreamMeta();
            }

        }

    }

    public void reorient() {

        if (mCamera != null) {

            int rotate = mUseBackfacingCamera ? 0 : 180;
            int displayOrientation = (mDisplayOrientation + rotate) % 360;
            mCamera.setOrientation(mCameraOrientation);
            mCamera.getCamera().setDisplayOrientation(displayOrientation);
            mStream.updateStreamMeta();

        }

    }

    public void updateDeviceOrientationOnLayoutChange() {

        int degrees = 0;
        int rotation = mContext.getCurrentActivity().getWindowManager().getDefaultDisplay().getRotation();

        switch (rotation) {
            case Surface.ROTATION_0: degrees = 0; break;
            case Surface.ROTATION_90: degrees = 270; break;
            case Surface.ROTATION_180: degrees = 180; break;
            case Surface.ROTATION_270: degrees = 90; break;
        }

        mDisplayOrientation = (mOrigCamOrientation + degrees) % 360;
        mCameraOrientation = rotation % 2 != 0 ? mDisplayOrientation - 180 : mDisplayOrientation;
        if (mUseBackfacingCamera && (rotation % 2 != 0)) {
            mCameraOrientation += 180;
        }
        mOrientationDirty = true;

    }

    @Override
    public void start() {

        Log.d("PublisherStream", ":start (" + mStreamName + ")");
        mStream.publish(mStreamName, mStreamType);

        if (mCamera != null) {
            mCamera.getCamera().startPreview();
        }

    }

    @Override
    public void stop() {

        Log.d("PublisherStream", ":stop (" + mStreamName + ")");

//        if (mCamera != null) {
//
//            Camera c = mCamera.getCamera();
//            c.stopPreview();
//            c.release();
//            mCamera = null;
//
//        }

        if (mStream != null) {
            mStream.client = null;

            if(mStream.getVideoSource() != null) {
                Log.d("PublisherStream", ":>>releaseCamera (" + mStreamName + ")");
                Camera c = ((R5Camera) mStream.getVideoSource()).getCamera();
                c.stopPreview();
                c.release();
                try {
                    Log.d("PublisherStream", "attachNullCamera...");
                    mStream.attachCamera(null);
                }
                catch (Exception e) {
                    // Attempted to clean out camera to avoid onResume crash with camera still
                    // in use by surface handler. not sure how it still gets there... but...
                    e.printStackTrace();
                }
                try {
                    Log.d("PublisherStream", "assignNullView");
                    mStream.setView(null);
                }
                catch (Exception e) {
                    // Ditto.
                    e.printStackTrace();
                }
                mCamera = null;
                Log.d("PublisherStream", ":<<releaseCamera (" + mStreamName + ")");
            }
            if (mVideoView != null) {
                mVideoView.attachStream(null);
                mVideoView = null;
            }
            mStream.stop();
        }
        else {

            WritableMap map = Arguments.createMap();
            mEventEmitter.dispatchEvent(mStreamName, R5MultiStreamLayout.Events.UNPUBLISH_NOTIFICATION.toString(), map);
            Log.d("PublisherStream", ":unpublishNotify (" + mStreamName + ")");
            cleanup();
        }

//        if (mVideoView != null) {
//            mVideoView.attachStream(null);
//        }

    }

    @Override
    public void resume () {
        // Nada. we shut down for good.
    }

    public void updateScaleSize(final int width, final int height, final int screenWidth, final int screenHeight) {

        if (mVideoView != null) {

            Log.d("PublisherStream", "rescaling...");

            final float xscale = (float)width / (float)screenWidth;
            final float yscale = (float)height / (float)screenHeight;

            final FrameLayout layout = mVideoView;
            final DisplayMetrics displayMetrics = new DisplayMetrics();
            mContext.getCurrentActivity().getWindowManager()
                    .getDefaultDisplay()
                    .getMetrics(displayMetrics);

            final int dwidth = displayMetrics.widthPixels;
            final int dheight = displayMetrics.heightPixels;

            layout.post(new Runnable() {
                @Override
                public void run() {
                    ViewGroup.LayoutParams params = (ViewGroup.LayoutParams) layout.getLayoutParams();
                    params.width = Math.round((displayMetrics.widthPixels * 1.0f) * xscale);
                    params.height = Math.round((displayMetrics.heightPixels * 1.0f) * yscale);
                    layout.setLayoutParams(params);
                }
            });

        }

    }

    @Override
    public int getLogLevel() {
        return mLogLevel;
    }
    public void setLogLevel(int level) {
        mLogLevel = level;
        if (mStream != null) {
            mStream.setLogLevel(level);
        }
    }

    @Override
    public R5VideoView getView () {
        return mVideoView;
    }

    @Override
    public void onConnectionEvent(R5ConnectionEvent event) {

        Log.d("Publisher", ":onConnectionEvent " + event.name());
        WritableMap map = new WritableNativeMap();
        WritableMap statusMap = new WritableNativeMap();
        statusMap.putInt("code", event.value());
        statusMap.putString("message", event.message);
        statusMap.putString("name", event.name());
        map.putMap("status", statusMap);
        mEventEmitter.dispatchEvent(mStreamName, R5MultiStreamLayout.Events.PUBLISHER_STATUS.toString(), map);

        if (event == R5ConnectionEvent.START_STREAMING) {
            mIsStreaming = true;
        }
        else if (event == R5ConnectionEvent.DISCONNECTED && mIsStreaming) {
            WritableMap evt = new WritableNativeMap();
            mEventEmitter.dispatchEvent(mStreamName, R5MultiStreamLayout.Events.UNPUBLISH_NOTIFICATION.toString(), evt);
            Log.d("PublisherStream", "DISCONNECT");
            cleanup();
            mIsStreaming = false;
        }

    }

}

