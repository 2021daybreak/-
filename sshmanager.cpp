#include "sshmanager.h"
#include <QDebug>
#include <QFileInfo>
sshmanager::sshmanager(QObject *parent)
    : QObject{parent},m_connection(nullptr)
{}
void sshmanager::startDownload()
{
    qDebug() << "开始尝试连接...";

    // 1. 设置连接参数
    QSsh::SshConnectionParameters params;
    params.setHost("192.168.112.148");
    params.setPort (22);
    params.setUserName("shuangzi");
    params.setPassword("1234");

    // 设置认证方式为密码
    params.authenticationType = QSsh::SshConnectionParameters::AuthenticationTypeTryAllPasswordBasedMethods;
    params.timeout = 10;

    // 2. 创建连接对象
    // 如果之前有连接，先清理
    if (m_connection) {
        delete m_connection;
        m_connection = nullptr;
    }

    m_connection = new QSsh::SshConnection(params, this);

    // 3. 连接信号槽 (处理连接结果)
    connect(m_connection, &QSsh::SshConnection::connected, this, [=]() {
        qDebug() << "SSH 连接成功！准备获取文件...";

        // 连接成功后，创建 SFTP 通道
        // 注意：createSftpChannel 返回的是一个指针
        auto sftp = m_connection->createSftpChannel();
        // 监听 SFTP 的finish信号再初始化
        connect(sftp.data(), &QSsh::SftpChannel::finished, this, [=](QSsh::SftpJobId id, QSsh::SftpError error, const QString &errorMsg) {
            if (errorMsg.isEmpty()) {
                qDebug() << "SFTP 任务完成 (ID:" << id << ") - 成功！";
            } else {
                qDebug() << "SFTP 任务失败 (ID:" << id << ") - 错误:" << errorMsg;
            }
        });
        //监听初始化成功
        connect(sftp.data(), &QSsh::SftpChannel::initialized, this, [=]() {
            qDebug() << "SFTP 通道已建立，开始下载 /home/user/snap ...";

            // 【下载操作】
            // 参数1: 远程路径 (Linux上的文件)
            // 参数2: 本地路径 (Windows上保存的位置)
            QString remoteFile = "/home/shuangzi/SZRobot/src/chassis_ws1/chassis_ws1/src/chassis_control/maps/my_map.pgm";
            QString localFile = "C:/Users/sz/Desktop/my_map.pgm";

            // 发起下载
            auto job = sftp->downloadFile(remoteFile, localFile, QSsh::SftpOverwriteExisting);

            // 监听下载完成
            connect(sftp.data(), &QSsh::SftpChannel::finished, this, [=]() {
                qDebug() << "文件下载任务已完成！";
            });
        });

        // 初始化 SFTP
        sftp->initialize();
    });

    connect(m_connection, &QSsh::SshConnection::error, this, [=](QSsh::SshError error) {
        qDebug() << "连接出错:" << error;
    });

    // 4. 发起异步连接
    m_connection->connectToHost();
}