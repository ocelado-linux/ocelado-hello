pragma Singleton
import QtQuick
import org.ocelado.hello

// The app's sections, in navigation order.
QtObject {
    readonly property var all: [
        { id: "welcome", title: "Bienvenida", short: "Inicio", icon: Icons.home, file: "WelcomePage.qml" },
        { id: "updates", title: "Actualizaciones", short: "Actualizar", icon: Icons.updates, file: "UpdatesPage.qml" },
        { id: "kernel", title: "Kernel y arranque", short: "Kernel", icon: Icons.kernel, file: "KernelPage.qml" },
        { id: "storage", title: "Almacenamiento", short: "Discos", icon: Icons.storage, file: "StoragePage.qml" },
        { id: "decky", title: "Decky", short: "Decky", icon: Icons.decky, file: "DeckyPage.qml", gameMode: true },
        { id: "controllers", title: "Mandos y hardware", short: "Mandos", icon: Icons.controllers, file: "ControllersPage.qml" },
        { id: "apps", title: "Aplicaciones", short: "Apps", icon: Icons.apps, file: "AppsPage.qml" },
        { id: "help", title: "Ayuda y comunidad", short: "Ayuda", icon: Icons.help, file: "HelpPage.qml" }
    ]

    /// Sections shown for this edition (Decky only with Game Mode).
    function visible(gameModeEdition) {
        return all.filter(function (p) { return !p.gameMode || gameModeEdition })
    }

    function find(id) {
        for (var i = 0; i < all.length; ++i)
            if (all[i].id === id)
                return all[i]
        return null
    }
}
