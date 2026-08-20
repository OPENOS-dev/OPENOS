/* openos-textedit — 独立文本编辑器 */
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QUrl>
#include "iconloader.h"
#include "iconprovider.h"
int main(int argc, char** argv) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("openos-textedit");
    app.setQuitOnLastWindowClosed(true);
    QQmlApplicationEngine engine;

    engine.addImageProvider(QStringLiteral("icons"), new IconProvider);
    IconLoader iconLoader(&app);
    engine.rootContext()->setContextProperty("_iconLoader", &iconLoader);
    QQmlComponent token(&engine, QUrl(QStringLiteral("qrc:/qml/OpenUI.qml")));
    QObject* openUI = token.create();
    engine.rootContext()->setContextProperty("OpenUI", openUI);
    engine.load(QUrl(QStringLiteral("qrc:/qml/TextEditor.qml")));
    return engine.rootObjects().isEmpty() ? 1 : app.exec();
}