use cxx_qt_build::{CxxQtBuilder, QResource, QResources, QmlFile, QmlModule};
use std::path::PathBuf;

/// QML files of the `org.ocelado.hello` module. Singletons are marked so the
/// generated qmldir declares them.
const QML_FILES: &[&str] = &[
    "qml/Main.qml",
    "qml/Badge.qml",
    "qml/Card.qml",
    "qml/Icon.qml",
    "qml/InfoTile.qml",
    "qml/ListRow.qml",
    "qml/OButton.qml",
    "qml/PageBase.qml",
    "qml/SectionLabel.qml",
    "qml/Sidebar.qml",
    "qml/TopBar.qml",
    "qml/HintBar.qml",
    "qml/Notice.qml",
    "qml/ConfirmDialog.qml",
    "qml/NewsDialog.qml",
    "qml/WelcomePage.qml",
    "qml/UpdatesPage.qml",
    "qml/KernelPage.qml",
    "qml/StoragePage.qml",
    "qml/DeckyPage.qml",
    "qml/ControllersPage.qml",
    "qml/AppsPage.qml",
    "qml/HelpPage.qml",
    "qml/WizardPage.qml",
];

const QML_SINGLETONS: &[&str] = &["qml/Theme.qml", "qml/Icons.qml", "qml/Pages.qml"];

/// Main.qml is loaded by URL from the `qml/` folder of the module, and QML
/// implicitly imports the types of a file's own folder. Without a qmldir
/// there, `Theme`, `Icons` and `Pages` would be plain types in that import
/// instead of singletons, so the folder gets its own qmldir.
fn write_folder_qmldir() -> PathBuf {
    let mut text = String::new();
    for f in QML_SINGLETONS {
        let file = f.trim_start_matches("qml/");
        text.push_str(&format!("singleton {} 1.0 {file}\n", file.trim_end_matches(".qml")));
    }
    for f in QML_FILES {
        let file = f.trim_start_matches("qml/");
        text.push_str(&format!("{} 1.0 {file}\n", file.trim_end_matches(".qml")));
    }
    let path = PathBuf::from(std::env::var("OUT_DIR").unwrap()).join("qml-folder-qmldir");
    std::fs::write(&path, text).unwrap();
    path
}

fn main() {
    let folder_qmldir = write_folder_qmldir();
    let files = QML_FILES
        .iter()
        .map(|f| QmlFile::from(*f))
        .chain(QML_SINGLETONS.iter().map(|f| QmlFile::from(*f).singleton(true)));

    CxxQtBuilder::new_qml_module(QmlModule::new("org.ocelado.hello").qml_files(files))
        .qt_module("Quick")
        .qrc_resources([
            "qml/assets/ocelado-logo.svg",
            "qml/assets/ocelado-logo-small.svg",
        ])
        .qrc_resources(QResources::new().resource(
            QResource::new().file(qt_build_utils::QResourceFile::new(&folder_qmldir).alias("qml/qmldir")),
        ))
        .include_dir("cpp")
        .files(["src/bridge.rs"])
        .build();
}
