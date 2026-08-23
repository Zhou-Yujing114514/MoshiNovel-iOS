import Foundation

// 下载管理器，支持进度回调
class DownloadManager: NSObject, URLSessionDownloadDelegate {
    private var progressCallback: ((Double) -> Void)?
    private var completionCallback: ((URL?, Error?) -> Void)?
    private var destinationURL: URL?
    
    func download(url: URL, to destination: URL, progress: @escaping (Double) -> Void, completion: @escaping (URL?, Error?) -> Void) {
        self.progressCallback = progress
        self.completionCallback = completion
        self.destinationURL = destination
        
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        let task = session.downloadTask(with: url)
        task.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        progressCallback?(min(progress, 1.0))
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let destination = destinationURL else {
            completionCallback?(nil, NSError(domain: "DownloadManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "目标路径未设置"]))
            return
        }
        
        do {
            // 如果目标文件已存在，先删除
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: location, to: destination)
            completionCallback?(destination, nil)
        } catch {
            completionCallback?(nil, error)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            completionCallback?(nil, error)
        }
        session.finishTasksAndInvalidate()
    }
}
