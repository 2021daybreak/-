#include "ImageProcessor.h"
#include <QColor>
#include <qdebug.h>
#include <QFile>
#include <QDir>
ImageProcessor::ImageProcessor(QObject *parent) : QObject(parent) {loadMap("");}
bool ImageProcessor::loadMap(const QString &path) {
    QString realPath = QStringLiteral(":/lab_7.6.png");
    qDebug() << "正在尝试加载";
    QFile file(realPath);
    if (!file.open(QIODevice::ReadOnly)) {
        qDebug() << " 错误: 无法打开文件，错误信息:" << file.errorString();
        return false;
    }

    QByteArray data = file.readAll();
    file.close();

    // 从内存数据加载图片，这比直接传路径更可靠
    if (!m_image.loadFromData(data)) {
        qDebug() << "!!! 错误: 数据加载失败 (可能是图片损坏或格式不支持)";
        return false;
    }

    // 统一转为 ARGB32 格式
    if (m_image.format() != QImage::Format_ARGB32) {
        m_image = m_image.convertToFormat(QImage::Format_ARGB32);
    }

    qDebug() << " 尺寸:" << m_image.width() << "x" << m_image.height();
    return true;
}

int ImageProcessor::getGrayValue(int x, int y) {
    if (x < 0 || y < 0 || x >= m_image.width() || y >= m_image.height())
    //边界检查
    {
        return -1;
    //返回值-1，错误码
    }
    QRgb pixel = m_image.pixel(x, y);
    //从内存中读取指定的坐标数据
    return qGray(pixel);
    //将彩色转化为黑白
}
// 新增：基于灰度阈值的占用判断
bool ImageProcessor::isOccupied(int x, int y) {
    int gray = getGrayValue(x, y);


    if (gray < 0) {
        qDebug() << "警告：坐标越界或读取失败！";
        return false;
    }

    // 归一化到 0~1
    double normalized = gray / 255.0;
    // 翻转：黑色=高占用率，白色=低占用率
    double occupancy = 1.0 - normalized;

    // 阈值判断：occupied_Thresh = 0.65，free_Thresh = 0.25
    // negate = false，所以不翻转逻辑
    if (occupancy >= 0.15) {
        return true;   // 黑色区域，允许标注
    }
    return false;      // 灰色或白色区域，禁止标注
}
int ImageProcessor::mapWidth() const { return m_image.width(); }
int ImageProcessor::mapHeight() const { return m_image.height(); }