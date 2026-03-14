import Foundation

let path = "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote"
guard let handle = dlopen(path, RTLD_NOW),
      let sym = dlsym(handle, "MRMediaRemoteGetNowPlayingInfo") else { exit(1) }
typealias Fn = @convention(c) (DispatchQueue, @escaping (CFDictionary?) -> Void) -> Void
let fn = unsafeBitCast(sym, to: Fn.self)

func poll() {
    fn(DispatchQueue.main) { dict in
        guard let d = dict as? [String: Any],
              d["kMRMediaRemoteNowPlayingInfoTitle"] != nil else {
            print(#"{"has_info":false}"#)
            return
        }
        var r: [String: Any] = ["has_info": true]
        r["title"] = d["kMRMediaRemoteNowPlayingInfoTitle"]
        r["artist"] = d["kMRMediaRemoteNowPlayingInfoArtist"]
        r["duration"] = d["kMRMediaRemoteNowPlayingInfoDuration"]
        r["elapsed"] = d["kMRMediaRemoteNowPlayingInfoElapsedTime"]
        r["rate"] = d["kMRMediaRemoteNowPlayingInfoPlaybackRate"]
        if let ts = d["kMRMediaRemoteNowPlayingInfoTimestamp"] as? Date {
            r["timestamp"] = ts.timeIntervalSinceReferenceDate
        }
        if let art = d["kMRMediaRemoteNowPlayingInfoArtworkData"] as? Data {
            r["artwork_base64"] = art.base64EncodedString()
        }
        if let json = try? JSONSerialization.data(withJSONObject: r),
           let s = String(data: json, encoding: .utf8) {
            print(s)
            fflush(stdout)
        }
    }
}

Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in poll() }
poll()
RunLoop.main.run()
