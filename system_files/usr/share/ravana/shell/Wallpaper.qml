// Copyright (c) 2026 Ravana OS. All rights reserved.
// Desktop background, behind everything.
import QtQuick
import Quickshell
import Quickshell.Wayland
import org.ravana.ui as R

PanelWindow {
    id: win
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "ravana-wallpaper"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "#0c0c0e"

    Image {
        anchors.fill: parent
        source: R.Theme.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        // decode at the screen's size, not the 4K file's (≈8 MB instead of ≈33 MB on 1080p)
        sourceSize: Qt.size(win.width > 0 ? win.width : 1920, win.height > 0 ? win.height : 1080)
        cache: true
    }
}
