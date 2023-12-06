//
//  XmagicManager.swift
//  TencentEffectSample
//
//  Created by 藤本諭志 on R 5/11/30.
//

import UIKit
import XMagic
import YTCommonXMagic

class XmagicManager: NSObject, YTSDKEventListener, YTSDKLogListener {
    
    private var beautyKit: XMagic?
    
    func buildBeautySDK(renderSize: CGSize) {
        let assetsDict: [String: Any] = ["core_name": "LightCore.bundle",
                                         "root_path": Bundle.main.bundlePath]
        self.beautyKit = XMagic(renderSize: renderSize, assetsDict: assetsDict)
        self.beautyKit?.registerLoggerListener(self, withDefaultLevel: YtSDKLoggerLevel.YT_SDK_ERROR_LEVEL)
    }
    
    func destory() {
        self.beautyKit?.deinit()
    }
    
    func auth(url: String, key: String){
        YTCommonXMagic.TELicenseCheck.setTELicense(url, key: key) { authResult, errorMsg in
            print("Effect Auth result: \(authResult)  \(errorMsg)")
        }
    }
        
    @discardableResult
    func configProperty(type propertyType: String, name propertyName: String, data propertyValue: String, extraInfo: Any?) -> Int {
        return Int(self.beautyKit?.configProperty(withType: propertyType, withName: propertyName, withData: propertyValue, withExtraInfo: extraInfo) ?? 0)
    }
    
    
    func processFrame(_ frame: CVPixelBuffer) -> CVPixelBuffer? {
        
        
        let input = YTProcessInput()
        input.pixelData = YTImagePixelData()
        input.pixelData?.data = frame
        input.dataType = kYTImagePixelData
        
        let output = self.beautyKit?.process(input, with: .topLeft, with: .cameraRotation0)
        
        input.pixelData = nil
        
        return output?.pixelData?.data
//        return output?.pixelData?.data

    }

    func onAIEvent(_ event: Any) {}

    func onAssetEvent(_ event: Any) {}

    func onTipsEvent(_ event: Any) {}

    func onYTDataEvent(_ event: Any) {}

    func onLog(_ loggerLevel: YtSDKLoggerLevel, withInfo logInfo: String) {
        NSLog("[\(loggerLevel)]-\(logInfo)")
    }
    
}
