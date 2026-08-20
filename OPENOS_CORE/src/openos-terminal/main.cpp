/* openos-terminal — 独立终端 App */
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QUrl>
int main(int argc, char** argv) {
    QGuiApplication app(argc, argv);
    app.setApplicationName("openos-terminal");
    app.setQuitOnLastWindowClosed(true);
    QQmlApplicationEngine engine;
    QQmlComponent token(&engine, QUrl(QStringLiteral("qrc:/qml/OpenUI.qml")));
    QObject* openUI = token.create();
    engine.rootContext()->setContextProperty("OpenUI", openUI);
    engine.load(QUrl(QStringLiteral("qrc:/qml/Terminal.qml")));
    return engine.rootObjects().isEmpty() ? 1 : app.exec();
}