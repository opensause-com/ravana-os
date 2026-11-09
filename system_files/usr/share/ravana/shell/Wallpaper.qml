// Copyright (c) 2026 Ravana OS. All rights reserved.
// Desktop background, behind everything.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "ravana-wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "#0c0c0e"

    Image {
        anchors.fill: parent
        source: Paths.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
    }
}
