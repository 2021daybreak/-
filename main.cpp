#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "tcpClient.h"
#include"ImageProcessor.h"
//引入头文件
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    TcpClient TcpClient;
    ImageProcessor mapProcessor;
    qmlRegisterType<ImageProcessor>("MyMapTools",1,0,"ImageProcessor");
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("tcpManager", &TcpClient);
    engine.rootContext()->setContextProperty("mapProcessor", &mapProcessor);
    const QUrl url(QStringLiteral("qrc:/qt/qml/server_test/Main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return QGuiApplication::exec();
}
