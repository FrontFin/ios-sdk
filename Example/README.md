# MeshLinkExample

A SwiftUI app that wires up the SDK's `.meshLink(...)` modifier against the
local `MeshLink` package.

The Xcode project is generated from [`project.yml`](project.yml) with
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (so no `.xcodeproj` is committed):

```bash
brew install xcodegen   # once
cd Example
xcodegen generate
open MeshLinkExample.xcodeproj
```

Run it on a simulator or device, paste a **client ID** and a **session token**
(mint the token on your backend — the client secret must never be in the app),
pick an environment, and tap **Open Link**.
