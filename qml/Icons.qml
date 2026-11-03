pragma Singleton
import QtQuick

// SVG path data for the icons (24×24, stroke only).
QtObject {
    readonly property string home: "M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z"
    readonly property string updates: "M4 12a8 8 0 0 1 14-5.3M20 12a8 8 0 0 1-14 5.3M18 3v4h-4M6 21v-4h4"
    readonly property string kernel: "M8 6h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2zM9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4"
    readonly property string storage: "M4 6c0-1.7 3.6-3 8-3s8 1.3 8 3-3.6 3-8 3-8-1.3-8-3zM4 6v12c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12c0 1.7 3.6 3 8 3s8-1.3 8-3"
    readonly property string decky: "M12 3l8 4.5v9L12 21l-8-4.5v-9zM12 12l8-4.5M12 12v9M12 12L4 7.5"
    readonly property string controllers: "M8 7h8a5 5 0 0 1 0 10H8A5 5 0 0 1 8 7zM8 10v4M6 12h4"
    readonly property string apps: "M4.5 3h4A1.5 1.5 0 0 1 10 4.5v4A1.5 1.5 0 0 1 8.5 10h-4A1.5 1.5 0 0 1 3 8.5v-4A1.5 1.5 0 0 1 4.5 3zM15.5 3h4A1.5 1.5 0 0 1 21 4.5v4a1.5 1.5 0 0 1-1.5 1.5h-4A1.5 1.5 0 0 1 14 8.5v-4A1.5 1.5 0 0 1 15.5 3zM4.5 14h4a1.5 1.5 0 0 1 1.5 1.5v4A1.5 1.5 0 0 1 8.5 21h-4A1.5 1.5 0 0 1 3 19.5v-4A1.5 1.5 0 0 1 4.5 14zM15.5 14h4a1.5 1.5 0 0 1 1.5 1.5v4a1.5 1.5 0 0 1-1.5 1.5h-4a1.5 1.5 0 0 1-1.5-1.5v-4a1.5 1.5 0 0 1 1.5-1.5z"
    readonly property string help: "M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0zM9.5 9a2.5 2.5 0 1 1 3.5 2.3c-.7.3-1 .9-1 1.7M12 17h.01"
    readonly property string check: "M5 12l5 5 9-10"
    readonly property string chevron: "M9 6l6 6-6 6"
    readonly property string rollback: "M3 12a9 9 0 1 0 3-6.7M3 4v5h5"
    readonly property string bug: "M8 2v3M16 2v3M7 9h10v5a5 5 0 0 1-10 0zM3 13h4M17 13h4M4 19l3-2M20 19l-3-2"
    readonly property string book: "M4 4h12a4 4 0 0 1 4 4v12H8a4 4 0 0 1-4-4zM8 9h8M8 13h6"
    readonly property string chat: "M21 12a8 8 0 0 1-11.6 7.1L4 20l1-5A8 8 0 1 1 21 12z"
    readonly property string bluetooth: "M7 7l10 10-5 5V2l5 5L7 17"
    readonly property string fan: "M12 10a2 2 0 1 1 0 4 2 2 0 0 1 0-4zM12 10c0-4 2-7 5-7 1 3-1 6-5 7zM14 12c4 0 7 2 7 5-3 1-6-1-7-5zM12 14c0 4-2 7-5 7-1-3 1-6 5-7zM10 12c-4 0-7-2-7-5 3-1 6 1 7 5z"
    readonly property string sdcard: "M7 3h7l5 5v12a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1zM10 3v4M13 3v4"
    readonly property string eject: "M12 4l8 10H4zM4 19h16"
    readonly property string power: "M12 3v9M6.3 6.3a8 8 0 1 0 11.4 0"
    readonly property string external: "M14 4h6v6M20 4l-9 9M18 14v5a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h5"
    readonly property string globe: "M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0zM3 12h18M12 3c2.5 2.7 3.8 5.7 3.8 9s-1.3 6.3-3.8 9c-2.5-2.7-3.8-5.7-3.8-9S9.5 5.7 12 3z"
    readonly property string folder: "M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"
    readonly property string gamepad: "M8 7h8a5 5 0 0 1 0 10H8A5 5 0 0 1 8 7zM8 10v4M6 12h4M15 11h.01M17 13h.01"
    readonly property string sliders:"M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6"
}
