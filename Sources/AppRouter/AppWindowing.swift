import Views

@MainActor
protocol AppWindowing: AnyObject {
    func orderOut(_ sender: Any?)
    func close()
}

extension AppWindow: AppWindowing {}
