//
//  XmagicManager.swift
//  TencentEffectSample
//
//  Created by 藤本諭志 on R 5/11/30.
//

import UIKit
import XMagic
import YTCommonXMagic

class XmagicManager {
    
    private var beautyKit: XMagic?
    
    func buildBeautySDK(renderSize: CGSize) {
        let assetsDict: [String: Any] = ["core_name": "LightCore.bundle",
                                         "root_path": Bundle.main.bundlePath]
        self.beautyKit = XMagic(renderSize: renderSize, assetsDict: assetsDict)
        //self.beautyKit?.registerLoggerListener(self, withDefaultLevel: YT_SDK_ERROR_LEVEL)
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
    
//    func processFrame(frame: CVPixelBuffer) -> CVPixelBuffer {
//        let input = YTProcessInput()
//        input.pixelData = YTImagePixelData()
//        input.pixelData?.data = frame
//        input.dataType = .kYTImagePixelData
//        let output = self.beautyKit?.process(input, withOrigin: .ytLightImageOriginTopLeft, withOrientation: .ytLightCameraRotation0)
//        input.pixelData = nil
//        return output?.pixelData?.data ?? frame
//    }
    
    func onAIEvent(_ event: Any) {
        // Implementation for onAIEvent if needed
    }
    
    func onAssetEvent(_ event: Any) {
        // Implementation for onAssetEvent if needed
    }
    
    func onTipsEvent(_ event: Any) {
        // Implementation for onTipsEvent if needed
    }
    
    func onYTDataEvent(_ event: Any) {
        // Implementation for onYTDataEvent if needed
    }
    
    func onLog(_ loggerLevel: YtSDKLoggerLevel, withInfo logInfo: String) {
        print("[\(loggerLevel)]-\(logInfo)")
    }
}
