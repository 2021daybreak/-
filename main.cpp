#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "mapimageprovider.h"
#include "tcpClient.h"
#include"ImageProcessor.h"
//引入头文件
int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    TcpClient TcpClient;// 栈上创建
    ImageProcessor mapProcessor;
    MapImageProvider *imageProvider = new MapImageProvider();
    qmlRegisterType<ImageProcessor>("MyMapTools",1,0,"ImageProcessor");
    //声明一个叫ImageProcessor的C++类
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("tcpManager", &TcpClient);
    //声明tcpManager对应C++里的TcpClient
    engine.rootContext()->setContextProperty("mapProcessor", &mapProcessor);
    engine.addImageProvider("mapProvider", imageProvider);
    //注册图片
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
