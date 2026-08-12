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
    Q_INVOKABLE void connectToServer(const QString &ip,int port);
    Q_INVOKABLE void sendMessage(const QString &msg);
    Q_INVOKABLE void disconnectFromServer();
signals:
    void headDataReceived(const QVariantList &value);      // 1111:
    void bodyDataReceived(const QVariantList &value);      // 2222:
    void leftArmDataReceived(const QVariantList &value);   // 3333:
    void rightArmDataReceived(const QVariantList &value);  // 4444:
    void leftHandDataReceived(const QVariantList &value);  // 5555:
    void rightHandDataReceived(const QVariantList &value); // 6666:
    void connectionStatusChanged(const QString &status);
    void errorMessage(const QString &msg);
private:
    QTcpSocket*socket;
};

#endif // TCPCLIENT_H
