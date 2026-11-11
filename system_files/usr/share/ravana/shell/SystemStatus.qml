// Copyright (c) 2026 Ravana OS. All rights reserved.
// One set of system checks shared by every menu bar (so two screens don't mean twice the
// work): network, keyboard layout, microphone in use, and a staged OS update.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: sys
    property var net: ({})
    property var kbd: ({})
    property bool micInUse: false
    property bool updateReady: false

    function kv(text) {
        const s = {};
        text.split("\n").forEach(l => { const i = l.indexOf("="); if (i > 0) s[l.slice(0, i)] = l.slice(i + 1); });
        return s;
    }
    function refreshKbd() { kbdReader.running = true; }

    Process { id: netReader; command: ["/usr/libexec/ravana-cc", "net"]
        stdout: StdioCollector { onStreamFinished: sys.net = sys.kv(text) } }
    Process { id: kbdReader; command: ["/usr/libexec/ravana-cc", "kbd"]
        stdout: StdioCollector { onStreamFinished: sys.kbd = sys.kv(text) } }
    Process { id: micReader; command: ["/usr/libexec/ravana-cc", "mic"]
        stdout: StdioCollector { onStreamFinished: sys.micInUse = /mic=([1-9])/.test(text) } }
    Process { id: updReader; command: ["/usr/libexec/ravana-cc", "staged"]
        stdout: StdioCollector { onStreamFinished: sys.updateReady = /staged=1/.test(text) } }

    // NetworkManager says when something changes (connect, disconnect, Wi-Fi on/off), so
    // the menu bar's icon follows at once; the slow timer is only a safety net
    Process {
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: netSoon.restart() }
    }
    Timer { id: netSoon; interval: 400; onTriggered: netReader.running = true }
    Timer { interval: 60000; repeat: true; running: true; triggeredOnStart: true; onTriggered: netReader.running = true }
    Timer { interval: 30000; repeat: true; running: true; triggeredOnStart: true; onTriggered: kbdReader.running = true }
    Timer { interval: 8000;  repeat: true; running: true; triggeredOnStart: true; onTriggered: micReader.running = true }
    Timer { interval: 1800000; repeat: true; running: true; onTriggered: updReader.running = true }
    Timer { interval: 120000; running: true; onTriggered: updReader.running = true }    // first look 2 min after login
}
