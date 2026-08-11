#ifndef MAPIMAGEPROVIDER_H
#define MAPIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QImage>
#include <QString>
#include <QColor>
#include <QList>
#include <QPointF>
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
    Q_INVOKABLE bool saveMapWithWalls(const QString &path);
    void addWallPoint(qreal x, qreal y);
    void finishCurrentWall();
    void clearCurrentWall();
    void selectWall(int index);
    void deselectWall();
    void selectCurrentWallPoint(int index);
    void deselectCurrentWallPoint();
    void deleteWall(int index);
    void deleteCurrentWallPoint(int index);
    void clearAllWalls();
    Q_INVOKABLE int getWallCount() const { return m_virtualWalls.size(); }
    Q_INVOKABLE int getCurrentPointCount() const { return m_currentWallPoints.size(); }
    Q_INVOKABLE qreal getCurrentWallPointX(int index) const {
        if (index >= 0 && index < m_currentWallPoints.size()) return m_currentWallPoints[index].x();
        return 0;
    }
    Q_INVOKABLE qreal getCurrentWallPointY(int index) const {
        if (index >= 0 && index < m_currentWallPoints.size()) return m_currentWallPoints[index].y();
        return 0;
    }
    void clearMap();
signals:
    void imageChanged();
    void wallsChanged();
private:
    QImage m_image;                  // 存储图片数据
    QString m_currentPath;           // 存储当前文件路径

    QList<QPointF> m_currentWallPoints;
    QList<QList<QPointF>> m_virtualWalls;
    int m_selectedWallIndex = -1;
    int m_selectedPointIndex = -1;
    void drawWallsOnImage(QImage &img);
};

#endif // MAPIMAGEPROVIDER_H
