/* openos-files — 独立文件管理器 App */
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QUrl>
int main(int argc, char** argv) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("openos-files");
    app.setQuitOnLastWindowClosed(true);
    QQmlApplicationEngine engine;
    QQmlComponent token(&engine, QUrl(QStringLiteral("qrc:/qml/OpenUI.qml")));
    QObject* openUI = token.create();
    engine.rootContext()->setContextProperty("OpenUI", openUI);
    engine.load(QUrl(QStringLiteral("qrc:/qml/FileManager.qml")));
    return engine.rootObjects().isEmpty() ? 1 : app.exec();
}