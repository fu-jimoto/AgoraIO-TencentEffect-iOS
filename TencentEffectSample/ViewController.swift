//
//  ViewController.swift
//  TencentEffectSample
//
//  Created by 藤本諭志 on R 5/11/30.
//

import UIKit
import AVFoundation
import AgoraRtcKit



class ViewController: UIViewController {

    let appID = ""
    let xMagicLicenceUrl = ""
    let xMagicLicenceKey = ""



    var agoraEngine: AgoraRtcEngineKit!
    var config:AgoraRtcEngineConfig!
    var userRole: AgoraClientRole = .broadcaster
    var token = ""
    var channelName = "sample"

    var videoFilter: XmagicManager!

    var localView: UIView!
    var remoteView: UIView!
    var joinButton: UIButton!
    var effectButton: UIButton!
    
    var joined: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.joinButton.setTitle( self.joined ? "Leave" : "Join", for: .normal)
            }
        }
    }
    
    var effected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.effectButton.setTitle( self.effected ? "EffectOff" : "EffectOn", for: .normal)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.videoFilter = XmagicManager()
        self.videoFilter.auth(url: xMagicLicenceUrl, key: xMagicLicenceKey)
        
        initViews()
        initializeAgoraEngine()

    }
    
    func joinChannel() async {
        if await !self.checkForPermissions() {
            showMessage(title: "Error", text: "Permissions were not granted")
            return
        }

        let option = AgoraRtcChannelMediaOptions()

        if self.userRole == .broadcaster {
            option.clientRoleType = .broadcaster
            setupLocalVideo()
        } else {
            option.clientRoleType = .audience
        }

        option.channelProfile = .liveBroadcasting

        let result = agoraEngine.joinChannel(
            byToken: token, channelId: channelName, uid: 0, mediaOptions: option,
            joinSuccess: { (channel, uid, elapsed) in }
        )

        if result == 0 {
            joined = true
            showMessage(title: "Success", text: "Successfully joined the channel as \(self.userRole)")
        }
    }

    func leaveChannel() {
        agoraEngine.stopPreview()
        let result = agoraEngine.leaveChannel(nil)
        if result == 0 { joined = false }
    }

    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        remoteView.frame = CGRect(x: 20, y: 50, width: 350, height: 330)
        localView.frame = CGRect(x: 20, y: 400, width: 350, height: 330)
    }
    
    func initializeAgoraEngine() {
        config = AgoraRtcEngineConfig()
        config.appId = appID
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        agoraEngine.setVideoFrameDelegate(self)
    }

    func setupLocalVideo() {

        agoraEngine.enableVideo()
        agoraEngine.startPreview()

        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localView
        agoraEngine.setupLocalVideo(videoCanvas)

    }

    func initViews() {
        remoteView = UIView()
        self.view.addSubview(remoteView)

        localView = UIView()
        self.view.addSubview(localView)

        joinButton = UIButton(type: .system)
        joinButton.frame = CGRect(x: 10, y: 50, width: 100, height: 50)
        joinButton.setTitle("Join", for: .normal)
        joinButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        joinButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(joinButton)

        effectButton = UIButton(type: .system)
        effectButton.frame = CGRect(x: 100, y: 50, width: 100, height: 50)
        effectButton.setTitle("EffectOn", for: .normal)
        effectButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        effectButton.addTarget(self, action: #selector(effectButtonAction), for: .touchUpInside)
        self.view.addSubview(effectButton)

    }
    
    @objc func buttonAction(sender: UIButton!) {
        if !joined {
            sender.isEnabled = false
            Task {
                await joinChannel()
                sender.isEnabled = true
            }
        } else {
            leaveChannel()
        }
    }
    
    @objc func effectButtonAction(sender: UIButton!) {
        if !effected {
            self.videoFilter.configProperty(type: "beauty", name: "basicV7.enlargeEye", data: "100", extraInfo: nil)
            self.videoFilter.configProperty(type: "beauty", name: "smooth.smooth", data: "100", extraInfo: nil)
            self.videoFilter.configProperty(type: "beauty", name: "beauty.faceFeatureLipsLut", data: "100", extraInfo: nil)
            self.videoFilter.configProperty(type: "beauty", name: "basicV7.mouthWidth", data: "100", extraInfo: nil)
            self.videoFilter.configProperty(type: "lut", name: "lut.bundle/n_baixi.png", data: "100", extraInfo: nil)
            self.videoFilter.configProperty(type: "beauty", name: "beauty.faceFeatureSoftlight", data: "100", extraInfo: ["beauty.softLight.softLightMask":"images/beauty/liti_junlang.png"])


            effected = true

        } else {
            self.videoFilter.configProperty(type: "beauty", name: "basicV7.enlargeEye", data: "0", extraInfo: nil)
            self.videoFilter.configProperty(type: "beauty", name: "smooth.smooth", data: "0", extraInfo: nil)
            self.videoFilter.configProperty(type: "beauty", name: "beauty.faceFeatureLipsLut", data: "0", extraInfo: nil)
            self.videoFilter.configProperty(type: "beauty", name: "basicV7.mouthWidth", data: "0", extraInfo: nil)
            self.videoFilter.configProperty(type: "lut", name: "lut.bundle/n_baixi.png", data: "0", extraInfo: nil)
            self.videoFilter.configProperty(type: "beauty", name: "beauty.faceFeatureSoftlight", data: "0", extraInfo: ["beauty.softLight.softLightMask":"images/beauty/liti_junlang.png"])

            effected = false
        }
    }
    

    func checkForPermissions() async -> Bool {
        var hasPermissions = await self.avAuthorization(mediaType: .video)
        if !hasPermissions { return false }
        hasPermissions = await self.avAuthorization(mediaType: .audio)
        return hasPermissions
    }

    func avAuthorization(mediaType: AVMediaType) async -> Bool {
        let mediaAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch mediaAuthorizationStatus {
        case .denied, .restricted: return false
        case .authorized: return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: mediaType) { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default: return false
        }
    }
    
    func showMessage(title: String, text: String, delay: Int = 2) -> Void {
        let deadlineTime = DispatchTime.now() + .seconds(delay)
        DispatchQueue.main.asyncAfter(deadline: deadlineTime, execute: {
            let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
            self.present(alert, animated: true)
            alert.dismiss(animated: true, completion: nil)
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        leaveChannel()
        DispatchQueue.global(qos: .userInitiated).async {
            AgoraRtcEngineKit.destroy()
            self.videoFilter.destory()
        }
    }

}


extension ViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.renderMode = .hidden
        videoCanvas.view = remoteView
        agoraEngine.setupRemoteVideo(videoCanvas)
    }
}

extension ViewController: AgoraVideoFrameDelegate {

    func onCapture(_ videoFrame: AgoraOutputVideoFrame, sourceType: AgoraVideoSourceType) -> Bool {
        if videoFrame.pixelBuffer != nil {
            let pixelBuffer = self.videoFilter.processFrame(videoFrame.pixelBuffer!,width: UInt32(videoFrame.width),height: UInt32(videoFrame.height))
            videoFrame.pixelBuffer = pixelBuffer
        }
        return true
    }

    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
        return false
    }

    func getVideoFrameProcessMode() -> AgoraVideoFrameProcessMode {
        return AgoraVideoFrameProcessMode.readWrite
    }

    func getVideoFormatPreference() -> AgoraVideoFormat {
        return AgoraVideoFormat.cvPixelNV12
    }

    func getObservedFramePosition() -> AgoraVideoFramePosition {
        return AgoraVideoFramePosition.postCapture
    }
}
