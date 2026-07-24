#include "mapimageprovider.h"
#include <QDebug>
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
    //两个变量暂时用不到，消除警告
    Q_UNUSED(requestedSize)
    qDebug() << "[Provider] requestImage 被调用，m_image 尺寸：" << m_image.size();
    // 如果 QML 需要知道尺寸，填入当前图片的尺寸
    if (size) {
        *size = m_image.size();
        //把要返回的的宽高，赋值给指针指向的变量
    }

    // 返回内存中的图片对象
    return m_image;
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
    QImage tempImage(path);
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
void MapImageProvider::drawLine(int x1, int y1,int x2,int y2,int width, const QColor &color)
{
    if (m_image.isNull()) {
        createBlankMap(349, 259); // 如果还没初始化，先创建白纸
    }

QPainter painter(&m_image);
painter.setRenderHint(QPainter::Antialiasing);  // 这个仍然要保留！
painter.setPen(QPen(QColor(color), 1, Qt::SolidLine, Qt::RoundCap, Qt::RoundJoin));
painter.drawLine(x1,y1,x2,y2);
painter.end();

emit imageChanged();
}
void MapImageProvider::clearMap()
{
    // 清空时保持原有尺寸
    createBlankMap(m_image.width(), m_image.height());
    emit imageChanged();
}
