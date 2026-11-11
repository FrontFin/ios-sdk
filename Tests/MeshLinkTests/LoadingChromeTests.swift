import Testing

@testable import MeshLink

@Suite("Loader and close button timing")
struct LoadingChromeTests {
    @Test func startsWithNothingShown() {
        let chrome = LoadingChrome()
        #expect(!chrome.isLoaderVisible)
        #expect(!chrome.isCloseButtonVisible)
        #expect(!chrome.isLoaded)
    }

    @Test func slowLoadShowsLoaderThenCloseButton() {
        var chrome = LoadingChrome()
        chrome.loaderDelayElapsed()
        #expect(chrome.isLoaderVisible)
        #expect(!chrome.isCloseButtonVisible)
        chrome.closeButtonDelayElapsed()
        #expect(chrome.isLoaderVisible)
        #expect(chrome.isCloseButtonVisible)
    }

    @Test func linkLoadedHidesBothAndBlocksLateTimers() {
        var chrome = LoadingChrome()
        chrome.loaderDelayElapsed()
        chrome.closeButtonDelayElapsed()
        chrome.linkLoaded()
        #expect(!chrome.isLoaderVisible)
        #expect(!chrome.isCloseButtonVisible)

        var early = LoadingChrome()
        early.linkLoaded()
        early.loaderDelayElapsed()
        early.closeButtonDelayElapsed()
        #expect(!early.isLoaderVisible)
        #expect(!early.isCloseButtonVisible)
    }

    @Test func linkPageCommitHidesLoaderAndKeepsItHidden() {
        var chrome = LoadingChrome()
        chrome.loaderDelayElapsed()
        chrome.pageCommitted(onLinkOrigin: true)
        #expect(!chrome.isLoaderVisible)

        var early = LoadingChrome()
        early.pageCommitted(onLinkOrigin: true)
        early.loaderDelayElapsed()
        #expect(!early.isLoaderVisible)
        // The close button still waits for `loaded`, not for the commit.
        early.closeButtonDelayElapsed()
        #expect(early.isCloseButtonVisible)
    }

    @Test func foreignPageCommitBeforeLoadKeepsLoader() {
        var chrome = LoadingChrome()
        chrome.pageCommitted(onLinkOrigin: false)
        chrome.loaderDelayElapsed()
        #expect(chrome.isLoaderVisible)
        #expect(!chrome.isCloseButtonVisible)
    }

    @Test func afterLoadCloseButtonFollowsCurrentPage() {
        var chrome = LoadingChrome()
        chrome.linkLoaded()
        chrome.pageCommitted(onLinkOrigin: false)
        #expect(chrome.isCloseButtonVisible)
        chrome.pageFinished(onLinkOrigin: true)
        #expect(!chrome.isCloseButtonVisible)
        #expect(!chrome.isLoaderVisible)
    }

    @Test func failedNavigationAfterLoadKeepsCloseButtonUntilNextNavigation() {
        var chrome = LoadingChrome()
        chrome.linkLoaded()
        chrome.navigationFailedAfterLoad()
        #expect(chrome.isCloseButtonVisible)
        // Still on Link's origin, but the document failed.
        chrome.pageFinished(onLinkOrigin: true)
        #expect(chrome.isCloseButtonVisible)

        chrome.navigationStarted()
        chrome.pageCommitted(onLinkOrigin: true)
        #expect(!chrome.isCloseButtonVisible)
    }

    @Test func endedHidesLoaderAndBlocksLateTimers() {
        var chrome = LoadingChrome()
        chrome.loaderDelayElapsed()
        chrome.ended()
        #expect(!chrome.isLoaderVisible)
        chrome.loaderDelayElapsed()
        chrome.closeButtonDelayElapsed()
        #expect(!chrome.isLoaderVisible)
        #expect(!chrome.isCloseButtonVisible)
    }
}
