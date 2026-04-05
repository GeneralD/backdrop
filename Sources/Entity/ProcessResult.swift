public enum StartResult: Sendable {
    case started(pid: Int32)
    case alreadyRunning
    case daemonExitedImmediately
}

public enum StopResult: Sendable {
    case stopped
    case notRunning
    case lockReleaseTimedOut
}
