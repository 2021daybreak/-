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
    void createBlankMap(int width = 349, int height = 259);

    const QImage& image() const { return m_image; }
    const QString& currentPath() const { return m_currentPath; }
    void setCurrentPath(const QString& path) { m_currentPath = path; }
public slots:
    bool loadFromPng(const QString &path);
    bool saveAsPng(const QString &path);
    void drawLine(int x1, int y1, int x2, int y2, int width = 2, const QColor &color = Qt::black);
    void clearMap();
signals:
    void imageChanged();
private:
    QImage m_image;       // 存储图片数据
    QString m_currentPath; // 存储当前文件路径
};

#endif // MAPIMAGEPROVIDER_H
