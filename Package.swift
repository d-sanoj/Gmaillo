// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "MacMail",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacMail", targets: ["MacMail"])
    ],
    targets: [
        .executableTarget(
            name: "MacMail",
            exclude: [
                "Config/GoogleOAuthClient.example.json"
            ],
            linkerSettings: [
                .linkedLibrary("sqlite3")
            ]
        )
    ]
)
