//
//  StringExtension.swift
//  PerfectLib
//
//  Created by virus1994 on 2017/8/31.
//

import Foundation
import PerfectCrypto

extension String {
    func encode(digest: Digest) -> String {
        if let digestBytes = self.digest(digest),
            let hexBytes = digestBytes.encode(.hex),
            let hexBytesStr = String(validatingUTF8: hexBytes) {
            return hexBytesStr
        }
        return ""
    }
    
    //MARK: - MD5
    func md5() -> String {
        return encode(digest: .md5)
    }
    
    //MARK: - sha1 加密
    func sha1() -> String {
        return encode(digest: .sha1)
    }
    
    //MARK: - sha256 加密
    func sha256() -> String {
        return encode(digest: .sha256)
    }
}
