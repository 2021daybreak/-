#include "mapimageprovider.h"
#include <QPainter>
#include <QPen>
MapImageProvider::MapImageProvider():QQuickImageProvider(QQuickImageProvider::Image){
    //调用父类构造函数
    createBlankMap(349,259);
    //
}
QImage MapImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id)
    Q_UNUSED(requestedSize)
    QImage result = m_image.copy();
    drawWallsOnImage(result);
    if (size) {
        *size = result.size();
    }
    return result;
}

void MapImageProvider::createBlankMap(int width, int height)
{
    // 创建指定大小的 RGB32 格式图片
    m_image = QImage(width, height, QImage::Format_RGB32);
    m_image.fill(Qt::white); // 填充白色背景
    m_currentPath.clear();   // 新建时清空路径
}

bool MapImageProvider::loadFromPng(const QString &path)
{
    QImage tempImage;

    // 获取文件扩展名并转为小写
    QString ext = path.right(4).toLower();

    // 根据扩展名加载图片
    if (ext == ".pgm") {
        tempImage.load(path, "PGM");
    } else {
        tempImage.load(path);  // Qt 自动检测格式（PNG等）
    }

    if (tempImage.isNull()) {
        return false; // 加载失败
    }

    // 转换为统一格式并赋值
    m_image = tempImage.convertToFormat(QImage::Format_RGB32);
    m_currentPath = path;
    return true;
}

bool MapImageProvider::saveAsPng(const QString &path)
{
    if(m_image.isNull()) return false;
    // 保存图片到磁盘
   bool result = m_image.save(path, "PNG");
    if(result){
       m_currentPath=path;
    }
    return result;
}
bool MapImageProvider::saveMapWithWalls(const QString &path)
{
    if (m_image.isNull()) return false;
    // 复制原图并在其上绘制虚拟墙，然后保存
    QImage result = m_image.copy();
    drawWallsOnImage(result);
    if (result.save(path, "PNG")) {
        return true;
    }
    return false;
}
void MapImageProvider::addWallPoint(qreal x, qreal y)
{
    m_currentWallPoints.append(QPointF(x, y));
    emit imageChanged();
    emit wallsChanged();
}
void MapImageProvider::finishCurrentWall()
{
    if (m_currentWallPoints.size() >= 2) {
        m_virtualWalls.append(m_currentWallPoints);
        m_currentWallPoints.clear();
        m_selectedPointIndex = -1;
        emit imageChanged();
        emit wallsChanged();
    }
}
void MapImageProvider::clearCurrentWall()
{
    if (!m_currentWallPoints.isEmpty()) {
        m_currentWallPoints.clear();
        m_selectedPointIndex = -1;
        emit imageChanged();
        emit wallsChanged();
    }
}
void MapImageProvider::selectWall(int index)
{
    if (index >= 0 && index < m_virtualWalls.size()) {
        m_selectedWallIndex = index;
        emit imageChanged();
        emit wallsChanged();
    }
}
void MapImageProvider::deselectWall()
{
    if (m_selectedWallIndex != -1) {
        m_selectedWallIndex = -1;
        emit imageChanged();
        emit wallsChanged();
    }
}
void MapImageProvider::selectCurrentWallPoint(int index)
{
    if (index >= 0 && index < m_currentWallPoints.size()) {
        m_selectedPointIndex = index;
        emit imageChanged();
    }
}
void MapImageProvider::deselectCurrentWallPoint()
{
    if (m_selectedPointIndex != -1) {
        m_selectedPointIndex = -1;
        emit imageChanged();
    }
}
void MapImageProvider::deleteWall(int index)
{
    if (index >= 0 && index < m_virtualWalls.size()) {
        m_virtualWalls.removeAt(index);
        if (m_selectedWallIndex == index) m_selectedWallIndex = -1;
        else if (m_selectedWallIndex > index) m_selectedWallIndex--;
        emit imageChanged();
        emit wallsChanged();
    }
}
void MapImageProvider::deleteCurrentWallPoint(int index)
{
    if (index >= 0 && index < m_currentWallPoints.size()) {
        m_currentWallPoints.removeAt(index);
        if (m_selectedPointIndex == index) m_selectedPointIndex = -1;
        else if (m_selectedPointIndex > index) m_selectedPointIndex--;
        emit imageChanged();
        emit wallsChanged();
    }
}
void MapImageProvider::clearAllWalls()
{
    m_currentWallPoints.clear();
    m_virtualWalls.clear();
    m_selectedWallIndex = -1;
    m_selectedPointIndex = -1;
    emit imageChanged();
    emit wallsChanged();
}
void MapImageProvider::clearMap()
{
    // 清空时保持原有尺寸
    createBlankMap(m_image.width(), m_image.height());
    clearAllWalls();
    emit imageChanged();
}

void MapImageProvider::drawWallsOnImage(QImage &img)
{
    QPainter painter(&img);
    painter.setRenderHint(QPainter::Antialiasing);
    for (int i = 0; i < m_virtualWalls.size(); i++) {
        const QList<QPointF> &wall = m_virtualWalls[i];
        if (wall.size() < 2) continue;
        bool sel = (i == m_selectedWallIndex);
        painter.setPen(QPen(sel ? QColor("#FF4444") : Qt::black, sel ? 4 : 3, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
        for (int j = 0; j < wall.size() - 1; j++) painter.drawLine(wall[j], wall[j + 1]);
    }
    if (m_currentWallPoints.size() >= 2) {
        painter.setPen(QPen(QColor("#888888"), 2, Qt::DashLine, Qt::RoundCap, Qt::RoundJoin));
        for (int i = 0; i < m_currentWallPoints.size() - 1; i++) painter.drawLine(m_currentWallPoints[i], m_currentWallPoints[i + 1]);
    }
    if (!m_currentWallPoints.isEmpty()) {
        for (int i = 0; i < m_currentWallPoints.size(); i++) {
            bool sel = (i == m_selectedPointIndex);
            if (sel) {
                // 选中点：红色实心圆 + 外圈光环
                painter.setPen(Qt::NoPen);
                painter.setBrush(QColor("#FF4444"));
                painter.drawEllipse(m_currentWallPoints[i], 5, 5);
                painter.setPen(QPen(QColor("#FF4444"), 2));
                painter.setBrush(Qt::NoBrush);
                painter.drawEllipse(m_currentWallPoints[i], 8, 8);
            } else {
                painter.setPen(Qt::NoPen);
                painter.setBrush(QColor("#00FFFF"));
                painter.drawEllipse(m_currentWallPoints[i], 3, 3);
            }
        }
    }
    painter.end();
}
