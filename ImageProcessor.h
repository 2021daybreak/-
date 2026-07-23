#ifndef IMAGEPROCESSOR_H
#define IMAGEPROCESSOR_H
#include <QObject>
#include <QImage>
#include <QColor>
class ImageProcessor:public QObject
{
    Q_OBJECT
public:
    // 构造函数
    explicit ImageProcessor(QObject *parent = nullptr);
    // Q_INVOKABLE 让这个函数可以被 QML 调用
    Q_INVOKABLE bool loadMap(const QString &filePath);
    // x, y 是图片上的像素坐标
    Q_INVOKABLE int getGrayValue(int x, int y);
    Q_INVOKABLE int mapWidth() const;
    Q_INVOKABLE int mapHeight() const;
    Q_INVOKABLE bool isOccupied(int x, int y);
private:
    QImage m_image; // 用于在内存中保存图片数据
};
#endif // IMAGEPROCESSOR_H
