import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

ApplicationWindow {
    id: win

    readonly property var pages: Pages.visible(Backend.gameModeEdition)
    // "wizard" is the first-boot assistant; the rest are entries of `pages`.
    property string current: initialPage()
    readonly property bool wizard: current === "wizard"
    readonly property bool newsOnly: Backend.startPage === "news"

    width: 1180
    height: 820
    minimumWidth: 640
    minimumHeight: 520
    // Started at login only for the news: stay hidden until there are some
    // (the backend quits if there are none).
    visible: !newsOnly || Backend.newsAvailable
    visibility: Backend.handheld ? Window.FullScreen : Window.AutomaticVisibility
    title: "Bienvenido a Ocelado Linux"
    color: Theme.window

    function initialPage() {
        var start = Backend.startPage
        if (start === "wizard" || (Backend.firstRun && start === "welcome"))
            return "wizard"
        return Pages.find(start) ? start : "welcome"
    }

    function pageIndex(id) {
        for (var i = 0; i < pages.length; ++i)
            if (pages[i].id === id)
                return i
        return -1
    }

    function go(id) {
        if (id === current)
            return
        if (id !== "wizard" && pageIndex(id) < 0)
            id = "welcome"
        current = id
    }

    function step(delta) {
        if (wizard)
            return
        var i = pageIndex(current)
        var n = pages.length
        go(pages[((i + delta) % n + n) % n].id)
    }

    // ---- Gamepad and keyboard navigation ----

    function focusFirst() {
        var page = pageLoader.item
        if (!page)
            return
        var item = page.nextItemInFocusChain(true)
        if (item)
            item.forceActiveFocus(Qt.TabFocusReason)
    }

    function moveFocus(forward) {
        var item = win.activeFocusItem
        if (!item || item === win.contentItem) {
            focusFirst()
            return
        }
        var next = item.nextItemInFocusChain(forward)
        if (next) {
            next.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason)
            if (pageLoader.item && pageLoader.item.ensureVisible)
                pageLoader.item.ensureVisible(next)
        }
    }

    function activate(item) {
        if (item && typeof item.clicked === "function" && item.enabled)
            item.clicked()
    }

    function handleNav(action) {
        // Popups and the page get the first chance (X/Y shortcuts, dialogs).
        if (confirm.opened) {
            if (action === "back")
                confirm.close()
            else if (action === "accept")
                activate(win.activeFocusItem)
            else if (action === "left" || action === "up")
                moveFocus(false)
            else if (action === "right" || action === "down")
                moveFocus(true)
            return
        }
        if (news.opened) {
            if (action === "back")
                news.dismiss()
            else if (action === "accept")
                activate(win.activeFocusItem)
            else if (action === "up" || action === "left")
                moveFocus(false)
            else if (action === "down" || action === "right")
                moveFocus(true)
            return
        }
        var page = pageLoader.item
        if (page && page.gamepadAction && page.gamepadAction(action))
            return
        switch (action) {
        case "up": case "left": moveFocus(false); break
        case "down": case "right": moveFocus(true); break
        case "accept": activate(win.activeFocusItem); break
        case "back": if (!wizard && current !== "welcome") go("welcome"); break
        case "prev": step(-1); break
        case "next": step(1); break
        }
    }

    Connections {
        target: Backend
        function onGamepad(action) { win.handleNav(action) }
        function onActionDone(ok, message) {
            if (message !== "")
                notice.show(ok, message)
        }
        function onNewsAvailableChanged() {
            if (Backend.newsAvailable)
                news.open()
        }
    }

    Shortcut { sequences: ["Ctrl+Tab", "Ctrl+PgDown"]; onActivated: win.step(1) }
    Shortcut { sequences: ["Ctrl+Shift+Tab", "Ctrl+PgUp"]; onActivated: win.step(-1) }
    // In the handheld layout the arrow keys behave like the d-pad, so it can
    // be tried with a keyboard too.
    Shortcut { sequence: "Down"; enabled: Backend.handheld && !confirm.opened && !news.opened; onActivated: win.moveFocus(true) }
    Shortcut { sequence: "Up"; enabled: Backend.handheld && !confirm.opened && !news.opened; onActivated: win.moveFocus(false) }
    Shortcut { sequence: "Esc"; enabled: !confirm.opened && !news.opened; onActivated: win.handleNav("back") }

    Component.onCompleted: {
        if (Backend.newsAvailable)
            news.open()
    }

    Timer {
        // Development screenshots (OCELADO_HELLO_SCREENSHOT)
        running: Backend.screenshotPath !== ""
        interval: 1500
        onTriggered: layoutRoot.grabToImage(function (result) {
            result.saveToFile(Backend.screenshotPath)
            Qt.quit()
        })
    }

    // ---- Layout ----

    background: Rectangle { color: Backend.handheld ? Theme.ground : Theme.window }

    RowLayout {
        id: layoutRoot
        anchors.fill: parent
        spacing: 0

        Sidebar {
            visible: !Backend.handheld && !win.wizard
            Layout.fillHeight: true
            Layout.preferredWidth: 248
            pages: win.pages
            current: win.current
            onSelected: function (id) { win.go(id) }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            TopBar {
                visible: Backend.handheld && !win.wizard
                Layout.fillWidth: true
                pages: win.pages
                current: win.current
                onSelected: function (id) { win.go(id) }
            }

            // Progress of long actions
            Rectangle {
                visible: Backend.busy
                Layout.fillWidth: true
                implicitHeight: busyRow.implicitHeight + 16
                color: Theme.blueSoft
                RowLayout {
                    id: busyRow
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 12
                    BusyIndicator {
                        running: Backend.busy
                        implicitWidth: 24
                        implicitHeight: 24
                    }
                    Label {
                        Layout.fillWidth: true
                        text: Backend.busyText !== "" ? Backend.busyText : "Trabajando…"
                        color: Theme.blueSoftText
                        font.pixelSize: Theme.fontBody
                        elide: Text.ElideRight
                    }
                }
            }

            Loader {
                id: pageLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Backend.handheld ? 32 : 0
                Layout.bottomMargin: Backend.handheld ? 12 : 0
                source: win.wizard ? "WizardPage.qml"
                                   : (Pages.find(win.current) ? Pages.find(win.current).file : "WelcomePage.qml")
                onLoaded: {
                    if (Backend.handheld)
                        Qt.callLater(win.focusFirst)
                }
            }

            HintBar {
                visible: Backend.handheld
                Layout.fillWidth: true
                hints: pageLoader.item && pageLoader.item.hints ? pageLoader.item.hints : []
                wizard: win.wizard
            }
        }
    }

    Connections {
        target: pageLoader.item
        ignoreUnknownSignals: true
        function onNavigate(id) { win.go(id) }
        function onConfirm(title, text, action, danger, callback) {
            confirm.ask(title, text, action, danger, callback)
        }
    }

    Notice { id: notice }
    ConfirmDialog { id: confirm }
    NewsDialog {
        id: news
        onFinished: {
            if (win.newsOnly)
                Qt.quit()
        }
    }
}
