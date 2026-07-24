#ifndef MAPIMAGEPROVIDER_H
#define MAPIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QImage>
#include <QString>
#include <QColor>
class MapImageProvider :public QQuickImageProvider
{
    Q_OBJECT
public:
    MapImageProvider();
  QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
    // 自定义功能函数
    void createBlankMap(int width = 349, int height = 259);
    bool loadFromPng(const QString &path);
    bool saveAsPng(const QString &path);

    // 获取当前图片引用（用于 Manager 读取）
    const QImage& image() const { return m_image; }
    const QString& currentPath() const { return m_currentPath; }
    void setCurrentPath(const QString& path) { m_currentPath = path; }
public slots:
    // 在指定坐标画一个黑色像素点
    void drawLine(int x1, int y1,int x2,int y2 ,int width=2, const QColor &color = Qt::black);
    // 清空所有标记，恢复白纸
    void clearMap();
signals:
    void imageChanged();
private:
    QImage m_image;       // 存储图片数据
    QString m_currentPath; // 存储当前文件路径
};

#endif // MAPIMAGEPROVIDER_H
