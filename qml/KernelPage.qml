import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.ocelado.hello

PageBase {
    id: page
    title: "Kernel y arranque"
    description: "Ocelado trae dos kernels instalados. Puedes cambiar entre ellos sin reinstalar nada: GRUB arranca el último que usaste."

    readonly property var kernels: JSON.parse(Backend.kernelsJson)

    function release(flavor) {
        var found = ""
        for (var i = 0; i < kernels.length; ++i)
            if (kernels[i].flavor === flavor)
                found = kernels[i].release
        return found
    }

    function askReboot(flavor, name) {
        page.confirm("¿Reiniciar con " + name + "?",
                     "Se cierra todo lo que tengas abierto. A partir de ahí, GRUB arrancará " + name + " por defecto hasta que vuelvas a cambiar.",
                     "Reiniciar", false,
                     function () { Backend.rebootIntoKernel(flavor) })
    }

    component KernelRow: ListRow {
        property string flavor
        property string name
        property string about
        readonly property string rel: page.release(flavor)
        readonly property bool running: Backend.kernelFlavor === flavor
        Layout.fillWidth: true
        text: name
        subtitle: about + (rel !== "" ? "\n" + rel : "\nNo instalado")
        enabled: running || (rel !== "" && !Backend.busy)
        badge: running ? "En uso" : ""
        badgeTone: "green"
        chevron: !running
        onClicked: if (!running) page.askReboot(flavor, name)
    }

    GridLayout {
        Layout.fillWidth: true
        columns: page.width > 760 ? 2 : 1
        columnSpacing: Theme.gap
        rowSpacing: Theme.gap
        KernelRow {
            flavor: "ogc"
            name: "OGC"
            about: "Open Gaming Collective: mandos, sensores y control de TDP de portátiles de juego."
            iconPath: Icons.kernel
        }
        KernelRow {
            flavor: "tkg"
            name: "linux-tkg"
            about: "BORE y GCC, para un escritorio más fluido. Variante x86-64-v"
                   + (Backend.cpuLevel >= 3 ? "3" : "2") + " para tu procesador."
            iconPath: Icons.kernel
            tint: "#c7b6f0"
        }
    }

    ColumnLayout {
        visible: Backend.gameModeEdition
        Layout.fillWidth: true
        spacing: Theme.gap

        SectionLabel { text: "Sesión al encender" }

        Repeater {
            model: [
                { mode: "last", text: "Repetir la última sesión", sub: "Como en SteamOS: si saliste al escritorio, vuelve al Modo Juego al reiniciar" },
                { mode: "gamemode", text: "Siempre Modo Juego", sub: "" },
                { mode: "desktop", text: "Siempre Escritorio", sub: "" }
            ]
            delegate: ListRow {
                required property var modelData
                Layout.fillWidth: true
                text: modelData.text
                subtitle: modelData.sub
                trailing: "radio"
                on: Backend.bootSession === modelData.mode
                onClicked: if (!on) Backend.changeBootSession(modelData.mode)
            }
        }
    }
}
