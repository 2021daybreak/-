#ifndef TCPCLIENT_H
#define TCPCLIENT_H

#include <QObject>
#include <QTcpSocket>
#include <QList>
#include <QVariantList>
class TcpClient : public QObject
{
    Q_OBJECT
public:
    explicit TcpClient(QObject *parent = nullptr);
    Q_INVOKABLE void connectToServer();
    Q_INVOKABLE void sendMessage(const QString &msg);
    Q_INVOKABLE void disconnectFromServer();
signals:
    void armDataReceived(const QVariantList &value);
    void handDataReceived(const QVariantList &value);
    void connectionStatusChanged(const QString &status);
    void errorMessage(const QString &msg);
private:
    QTcpSocket*socket;
};

#endif // TCPCLIENT_H
