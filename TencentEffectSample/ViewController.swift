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
        let config = AgoraRtcEngineConfig()
        config.appId = appID
        agoraEngine = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
    }

    func setupLocalVideo() {

        agoraEngine.enableVideo()
        agoraEngine.startPreview()

        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = 0
        videoCanvas.renderMode = .hidden
        videoCanvas.view = localView
        agoraEngine.setupLocalVideo(videoCanvas)

        self.videoFilter.buildBeautySDK(renderSize: CGSize(width: 350, height: 330))

    }

    func initViews() {
        remoteView = UIView()
        self.view.addSubview(remoteView)

        localView = UIView()
        self.view.addSubview(localView)

        joinButton = UIButton(type: .system)
        joinButton.frame = CGRect(x: 10, y: 0, width: 100, height: 50)
        joinButton.setTitle("Join", for: .normal)
        joinButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        joinButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(joinButton)

        effectButton = UIButton(type: .system)
        effectButton.frame = CGRect(x: 100, y: 0, width: 100, height: 50)
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
            agoraEngine.setVideoFrameDelegate(self)
            self.videoFilter.configProperty(type: "beauty", name: "beauty.enlarge.eye", data: "100", extraInfo: nil)
            effected = true

        } else {
            agoraEngine.setVideoFrameDelegate(nil)
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
        DispatchQueue.global(qos: .userInitiated).async {AgoraRtcEngineKit.destroy()}
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
            let pixelBuffer = self.videoFilter.processFrame(videoFrame.pixelBuffer!)
            videoFrame.pixelBuffer = pixelBuffer
        }
        return true
    }

    // Occurs each time the SDK receives a video frame sent by the remote user
    func onRenderVideoFrame(_ videoFrame: AgoraOutputVideoFrame, uid: UInt, channelId: String) -> Bool {
        return false
    }

    func getVideoFrameProcessMode() -> AgoraVideoFrameProcessMode {
        return AgoraVideoFrameProcessMode.readWrite
    }

    func getVideoFormatPreference() -> AgoraVideoFormat {
        return AgoraVideoFormat.I420
    }

    func getObservedFramePosition() -> AgoraVideoFramePosition {
        return AgoraVideoFramePosition.postCapture
    }
}
