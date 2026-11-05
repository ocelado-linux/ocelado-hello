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
    readonly property bool pageExclusive: pageLoader.item ? pageLoader.item.exclusive === true : false

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
    //
    // Spatial: up/down/left/right go to the nearest control in that
    // direction, only inside the open dialog or the current page (never the
    // sidebar or the tabs; L1/R1 change section).

    function navRoot() {
        if (confirm.opened)
            return confirm.contentItem
        if (news.opened)
            return news.contentItem
        return pageLoader.item
    }

    function collect(item, out) {
        if (!item || !item.visible || out.indexOf(item) >= 0)
            return
        if (item.activeFocusOnTab && item.enabled && item.width > 0 && item.height > 0) {
            out.push(item)
            return // a control's own parts are not separate stops
        }
        var kids = item.children
        for (var i = 0; i < kids.length; ++i)
            collect(kids[i], out)
        // Flickable/ScrollView keep their children in contentItem
        if (item.contentItem && item.contentItem !== item && item.contentItem.parent === item)
            collect(item.contentItem, out)
    }

    function focusables() {
        var out = []
        collect(navRoot(), out)
        return out
    }

    function rect(item) {
        var p = item.mapToItem(null, 0, 0)
        return { l: p.x, t: p.y, r: p.x + item.width, b: p.y + item.height,
                 cx: p.x + item.width / 2, cy: p.y + item.height / 2 }
    }

    function focusItem(item) {
        if (!item)
            return
        item.forceActiveFocus(Qt.TabFocusReason)
        var page = pageLoader.item
        if (!confirm.opened && !news.opened && page && page.ensureVisible)
            page.ensureVisible(item)
    }

    function focusFirst() {
        var list = focusables()
        if (list.length === 0)
            return
        var best = list[0], bc = rect(best)
        for (var i = 1; i < list.length; ++i) {
            var c = rect(list[i])
            if (c.t < bc.t - 4 || (Math.abs(c.t - bc.t) <= 4 && c.l < bc.l)) {
                best = list[i]
                bc = c
            }
        }
        focusItem(best)
    }

    function moveFocus(direction) {
        var list = focusables()
        var current = win.activeFocusItem
        var index = list.indexOf(current)
        if (index < 0) {
            // focus is inside a control (e.g. a TextArea's parts) or nowhere
            for (var k = 0; k < list.length && index < 0; ++k)
                for (var it = current; it; it = it.parent)
                    if (it === list[k]) { index = k; break }
        }
        if (index < 0) {
            focusFirst()
            return
        }
        // Distance between edges in the direction of travel, plus a penalty
        // for being off to the side (0 when the two overlap).
        var from = rect(list[index])
        var best = null, bestScore = 1e9
        for (var i = 0; i < list.length; ++i) {
            if (i === index)
                continue
            var c = rect(list[i])
            var along, gap
            if (direction === "down" || direction === "up") {
                along = direction === "down" ? c.t - from.b : from.t - c.b
                if ((direction === "down" ? c.cy - from.cy : from.cy - c.cy) <= 4)
                    continue
                gap = Math.max(0, c.l - from.r, from.l - c.r)
            } else {
                along = direction === "right" ? c.l - from.r : from.l - c.r
                if ((direction === "right" ? c.cx - from.cx : from.cx - c.cx) <= 4)
                    continue
                // sideways only to things on the same row
                if (c.b <= from.t || c.t >= from.b)
                    continue
                gap = 0
            }
            var score = Math.max(0, along) + 3 * gap
            if (score < bestScore) {
                bestScore = score
                best = list[i]
            }
        }
        if (best)
            focusItem(best)
    }

    function activate(item) {
        for (var it = item; it; it = it.parent) {
            if (typeof it.clicked === "function") {
                if (it.enabled)
                    it.clicked()
                return
            }
        }
    }

    function handleNav(action) {
        if (confirm.opened && action === "back") {
            confirm.close()
            return
        }
        if (news.opened && action === "back") {
            news.dismiss()
            return
        }
        // The page gets the first chance (Y to install, B in the wizard…);
        // during the button test it takes everything, L1/R1 included.
        var page = pageLoader.item
        if (page && page.exclusive) {
            page.gamepadAction(action)
            return
        }
        if (!confirm.opened && !news.opened && page && page.gamepadAction && page.gamepadAction(action))
            return
        switch (action) {
        case "up": case "down": case "left": case "right": moveFocus(action); break
        case "accept": activate(win.activeFocusItem); break
        case "back": if (!wizard && current !== "welcome") go("welcome"); break
        case "prev": if (!confirm.opened && !news.opened) step(-1); break
        case "next": if (!confirm.opened && !news.opened) step(1); break
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

    // Keyboard equivalents of L1/R1 (change section), also to test section
    // changes without a controller
    Shortcut { sequences: ["Ctrl+Tab", "Ctrl+PgDown"]; onActivated: win.handleNav("next") }
    Shortcut { sequences: ["Ctrl+Shift+Tab", "Ctrl+PgUp"]; onActivated: win.handleNav("prev") }
    // Arrow keys (and Steam's desktop controller layout, which sends them)
    // move like the d-pad when the focused control does not use them.
    // In dialogs they are shortcuts; on the page they arrive in pageLoader.
    Shortcut { sequence: "Down"; enabled: confirm.opened || news.opened; onActivated: win.handleNav("down") }
    Shortcut { sequence: "Up"; enabled: confirm.opened || news.opened; onActivated: win.handleNav("up") }
    Shortcut { sequence: "Left"; enabled: confirm.opened || news.opened; onActivated: win.handleNav("left") }
    Shortcut { sequence: "Right"; enabled: confirm.opened || news.opened; onActivated: win.handleNav("right") }
    // Not during the button test: there Esc (B in Steam's desktop layout)
    // must reach the page, which ends the test when it is held.
    Shortcut { sequence: "Esc"; enabled: !confirm.opened && !news.opened && !win.pageExclusive; onActivated: win.handleNav("back") }

    Component.onCompleted: {
        if (Backend.newsAvailable)
            news.open()
    }

    Timer {
        // Development screenshots (OCELADO_HELLO_SCREENSHOT)
        running: Backend.screenshotPath !== ""
        interval: 1500
        onTriggered: {
            if (Backend.devNav !== "")
                Backend.devNav.split(",").forEach(function (a) { win.handleNav(a.trim()) })
            shotDelay.start()
        }
    }
    Timer {
        id: shotDelay
        interval: 500
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
                // Keys not used by the focused control bubble up to here
                Keys.onUpPressed: win.handleNav("up")
                Keys.onDownPressed: win.handleNav("down")
                Keys.onLeftPressed: win.handleNav("left")
                Keys.onRightPressed: win.handleNav("right")
                Keys.onReturnPressed: win.activate(win.activeFocusItem)
                Keys.onEnterPressed: win.activate(win.activeFocusItem)
            }


            HintBar {
                visible: Backend.handheld
                Layout.fillWidth: true
                hints: pageLoader.item && pageLoader.item.hints ? pageLoader.item.hints : []
                exclusive: pageLoader.item ? pageLoader.item.exclusive === true : false
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
