#include "tcpclient.h"
#include <QTcpSocket>
#include <QDebug>
#include <QVariant>
TcpClient::TcpClient(QObject *parent)
    : QObject{parent}
{

        // 1. 初始化 Socket,表示socket属于TcpSocket
        socket = new QTcpSocket(this);

        // 2. 监听 Socket 发来的信号，并把它转成我们自己的信号，发给 QML
        // 当接收到数据时
        connect(socket, &QTcpSocket::readyRead, this, [this]() {
            QByteArray data = socket->readAll();
            // 把接收到的数据，通过信号发给 QML
            QString str = QString::fromUtf8(data).trimmed(); // 去掉首尾可能存在的换行符或空格

            if (str.isEmpty()) return;

            // --- 协议解析逻辑 ---
            if (str.startsWith("1001:")) {
                // 机械臂数据：截取 "1001:" 之后的内容
                QString armStr = str.mid(5);
                QStringList parts = armStr.split(",");

                QVariantList values;
                for (const QString &part : parts) {
                    bool ok = false;
                    int val = part.toInt(&ok);
                    if (ok) values.append(val);
                }

                // 发送专门的机械臂信号给 QML
                emit armDataReceived(values);
            }
            else if (str.startsWith("1002:")) {
                // 机械手数据：截取 "1002:" 之后的内容
                QString handStr = str.mid(5);
                QStringList parts = handStr.split(",");

                QVariantList values;
                for (const QString &part : parts) {
                    bool ok = false;
                    int val = part.toInt(&ok);
                    if (ok) values.append(val);
                }

                // 发送专门的机械手信号给 QML
                emit handDataReceived(values);
            }else{
                emit errorMessage("未知格式数据");}
});
        // 当连接成功时
        connect(socket, &QTcpSocket::connected, this, [this]() {
            emit connectionStatusChanged(QString::fromUtf8("Connected"));
        });

        // 当断开连接时
        connect(socket, &QTcpSocket::disconnected, this, [this]() {
            emit connectionStatusChanged(QString::fromUtf8("Disconnected"));
        });
    }

    // 3. 实现“连接服务器”的功能
    void TcpClient::connectToServer()
    {
        if(socket->state() == QAbstractSocket::ConnectedState) {
            emit connectionStatusChanged("Connected");
            return;
        }
        // 这里的 IP 和端口要和你的服务端一致
        socket->connectToHost("127.0.0.1", 8888);
        emit connectionStatusChanged("TEST_SIGNAL");
    }

    // 4. 实现“发送消息”的功能
    void TcpClient::sendMessage(const QString &msg)
    {
            if (socket->state()!= QAbstractSocket::ConnectedState) return;
            socket->write(msg.toUtf8()); // 把中文转成 UTF-8 编码发出去
            socket->flush();
    }

    void TcpClient::disconnectFromServer() {
        if (socket && socket->isOpen()) {
            socket->disconnectFromHost();}
    }