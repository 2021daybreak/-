import QtQuick
//Qt基础组件
import QtQuick.Controls
//Qt按钮，文本框
ApplicationWindow {
    visible: true
    //显示窗口
    width: 400
    height: 200
    title: "TCP 测试客户端"

    Column {
        //垂直布局容器
        anchors.centerIn: parent
        spacing: 20
        width: parent.width * 0.7
        //父容器的70%

        Text {
            id: statusText
            text: "未连接 (等待点击连接)"
            font.pixelSize: 15
            color: "black"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Button {
            text: "连接服务器 (127.0.0.1:8888)"
            width: parent.width
            height: 40
            onClicked: tcpManager.connectToServer()
        }

        TextField {
            id: msgInput
            placeholderText: "输入要发送的消息..."
            width: parent.width
        }

        Button {
            text: "发送消息"
            width: parent.width
            height: 40
            onClicked: {
                if(msgInput.text !== "") {
                    tcpManager.sendMessage(msgInput.text)
                    msgInput.text = ""
                }
            }
        }

        Text {
            id: receiveText
            text: "等待接收..."
            font.pixelSize: 16
            wrapMode: Text.Wrap
            width: parent.width
        }
    }

    Connections {
        target: tcpManager
          onMessageReceived: {
            receiveText.text = "收到消息：" + msg
        }
         onConnectionStatusChanged:{
            statusText.text = status
            if(status === "已连接") {
                statusText.color = "green"
            } else {
                statusText.color = "red"
            }
        }
    }
}