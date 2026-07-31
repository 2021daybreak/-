#ifndef SSHMANAGER_H
#define SSHMANAGER_H

#include <QObject>
// 引入 QSsh 的关键头文件
// 注意：确保你的 CMakeLists.txt 里 include_directories 指向了 QSsh/src/libs
#include <qSsh/sshconnection.h>
#include <qSsh/sftpchannel.h>
class sshmanager : public QObject
{
    Q_OBJECT
public:
    explicit sshmanager(QObject *parent = nullptr);
    Q_INVOKABLE void startDownload();
//signals:
private:
    //使用指针，避免头文件依赖问题
    QSsh::SshConnection *m_connection;
};

#endif // SSHMANAGER_H
