import QtQuick 2.15
//Qt基础组件
import QtQuick.Controls 2.15
//Qt按钮，文本框
import QtQuick.Layouts
import QtQuick.Window
ApplicationWindow {
    id:root
    visible: true
    //显示窗口
    width: 500
    height: 900
    title: "TCP 测试客户端"
    property var inputvalues:["0","0","0","0","0","0","0","0","0","0","0"]
    property var feedbackValues:["0","0","0","0","0","0","0","0","0","0","0"]
    property var inputvalues_hands:["0","0","0","0","0","0"]
    property var feedbackValues_hands:["0","0","0","0","0","0"]
    property bool isServoReady: false
    property bool isServoReady_1:false
    property int currentPageIndex: 0
    property double mapResolution: 0.05      // resolution
    property double mapOriginX: -3.8         // origin[0]
    property double mapOriginY: -5.55        // origin[1]
    property real currentAngleDegree:0
    property point targetPos: Qt.point(0, 0)
    property real pixelX: 0
    property real pixelY: 0
    //两个数组，一个存输入，一个存反馈
    Rectangle//引航栏
        {
            id: topNavBar
            width: parent.width
            height: 60 // 导航栏高度
            color: "#e6e6fa"
            Text {
                id: statusText
                text: "未连接 (等待点击连接)"
                font.pixelSize: 15
                color: "black"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 20
            }

        Switch{
             id:servoSwitch
             x:20
             y:20
             checked:false
             indicator:Rectangle{
                  implicitHeight: 20
                  implicitWidth: 40
                  radius:10
                  color: servoSwitch.checked ? "#4CD964":"#555555"
                  Rectangle{
                  x: servoSwitch.checked ? parent.width - width-2 :2
                  y:2
                  width: 16
                  height: 16
                  radius:8
                  color: "white"
                  }
             }

             onCheckedChanged: {
                     if (checked) {
                         tcpManager.sendMessage("1003:1");
                         isServoReady = true;
                         statusLabel.text="伺服已供电"
                         statusLabel.color="green"
                     } else {
                         tcpManager.sendMessage("1003:0");
                         isServoReady = false;
                         statusLabel.text="伺服已断电"
                         statusLabel.color="red"
                     }
                 }
        }
        Text{
                id: statusLabel
                x:20;
                y:40;
                text:"伺服状态"
                font.pixelSize: 14
        }
        Text{
                id: statusLabel_1
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.top: parent.top
                anchors.topMargin: 40
                text:"使能状态"
                font.pixelSize: 14
        }

        Switch{
                id:servoSwitch_1
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.top: parent.top
                anchors.topMargin: 20
                checked:false
                indicator:Rectangle{
                     implicitHeight: 20
                     implicitWidth: 40
                     radius:10
                     color: servoSwitch_1.checked ? "#4CD964":"#555555"
                     Rectangle{
                     x: servoSwitch_1.checked ? parent.width - width-2 :2
                     y:2
                     width: 16
                     height: 16
                     radius:8
                     color: "white"
                     }
                }
                onCheckedChanged: {
                        if (checked) {
                            tcpManager.sendMessage("1004:1");
                            isServoReady_1 = true;
                            statusLabel_1.text="已使能"
                            statusLabel_1.color="green"
                        } else {
                            tcpManager.sendMessage("1004:0");
                            isServoReady_1 = false;
                            statusLabel_1.text="未使能"
                            statusLabel_1.color="red"
                        }
                    }
        }
    }
    RowLayout{
                   anchors.top: topNavBar.bottom
                   anchors.bottom: parent.bottom
                   width: parent.width
                   spacing: 0
    Rectangle//左侧导航栏
    {
                Layout.preferredWidth: 100  // 核心：限制左侧宽度
                Layout.fillHeight: true     // 高度跟随父容器

                color: "#87cefa"
    ColumnLayout {
                   anchors.fill: parent    // 填满父容器
                   spacing: 0              // 按钮之间不留缝隙
                   Button {
                           Layout.fillWidth: true
                           Layout.preferredHeight: 60
                           text: "指令"
                           onClicked:currentPageIndex = 0
                           background: Rectangle {
                                      // 如果当前是第0页，显示蓝色背景，否则透明
                                      color: (currentPageIndex === 0) ? "#3498db" : "transparent"
          }
                           Rectangle {
                                           width: 4; height: parent.height; color: "#2980b9"
                                           visible: (currentPageIndex === 0)
                                       }

                           contentItem: Text {
                                       text: parent.text
                                       // 如果当前是第0页，文字变白，否则深灰
                                       color: (currentPageIndex === 0) ? "white" : "black"
                                       horizontalAlignment: Text.AlignHCenter
                                       verticalAlignment: Text.AlignVCenter
                                   }
    }
                   Button {
                   Layout.fillWidth: true
                   Layout.preferredHeight: 60
                   text: "控制"

                           // 点击时跳转到第 1 页
                   onClicked: currentPageIndex = 1
                   background: Rectangle {
                   color: (currentPageIndex === 1) ? "#3498db" : "transparent"
                   Rectangle {
                   width: 4; height: parent.height; color: "#2980b9"
                   visible: (currentPageIndex === 1)
                                      }
                   }
                   contentItem: Text {
                   text: parent.text
                   color: (currentPageIndex === 1) ? "white" : "black"
                   horizontalAlignment: Text.AlignHCenter
                   verticalAlignment: Text.AlignVCenter
                                      }
                   }
                   Button {
                   Layout.fillWidth: true
                   Layout.preferredHeight: 60
                   text: "设置"

                           // 点击时跳转到第 2 页
                   onClicked: currentPageIndex = 2
                   background: Rectangle {
                   color: (currentPageIndex === 2) ? "#3498db" : "transparent"
                   Rectangle {
                   width: 4; height: parent.height; color: "#2980b9"
                   visible: (currentPageIndex === 2)
                                      }
                   }
                   contentItem: Text {
                   text: parent.text
                   color: (currentPageIndex === 2) ? "white" : "black"
                   horizontalAlignment: Text.AlignHCenter
                   verticalAlignment: Text.AlignVCenter
                                      }
                   }
                   Button {
                   Layout.fillWidth: true
                   Layout.preferredHeight: 60
                   text: "导航"

                           // 点击时跳转到第 3 页
                   onClicked: currentPageIndex = 3
                   background: Rectangle {
                   color: (currentPageIndex === 3) ? "#3498db" : "transparent"
                   Rectangle {
                   width: 4; height: parent.height; color: "#2980b9"
                   visible: (currentPageIndex === 3)
                                      }
                   }
                   contentItem: Text {
                   text: parent.text
                   color: (currentPageIndex === 3) ? "white" : "black"
                   horizontalAlignment: Text.AlignHCenter
                   verticalAlignment: Text.AlignVCenter
                                      }
                   }

    }
    }
    StackLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        // 关键：绑定到 currentPageIndex
        currentIndex: currentPageIndex
    Rectangle //主页面
    {
        id: mainPage
        anchors.fill: parent
        color: "#f0f0f0" // 浅灰色背景
    Column {
        //垂直布局容器
        anchors.centerIn: parent
        //于父容器居中放置
        spacing: 10
        width: parent.width * 0.9
        //父容器的70%

        Button {
                text: "连接服务器 (127.0.0.1:8888)"
                width: parent.width
                height: 40
                onClicked: tcpManager.connectToServer()
                //调用tcpmanager的connectToServer()方法
            }
        Row{
                width:parent.width - 40
                anchors.horizontalCenter: parent.horizontalCenter
                spacing:10
        Grid {
                   columns: 3
                   spacing: 10
                   width: parent.width*0.5 - 5

                   // Axis 1
                   Text { text: "axis 1:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_0; text: "0"; width: 80;
                       onAccepted: sendSingle(0) // 回车也能发
                   }
                   Text { id: feedback_0; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   // Axis 2
                   Text { text: "axis 2:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_1; text: "0"; width: 80;
                       onAccepted: sendSingle(1)
                   }
                   Text { id: feedback_1; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   // Axis 3
                   Text { text: "axis 3:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_2; text: "0"; width: 80;
                       onAccepted: sendSingle(2)
                   }
                   Text { id: feedback_2; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   // Axis 4
                   Text { text: "axis 4:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_3; text: "0"; width: 80;
                       onAccepted: sendSingle(3)
                   }
                   Text { id: feedback_3; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   // Axis 5
                   Text { text: "axis 5:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_4; text: "0"; width: 80;
                       onAccepted: sendSingle(4)
                   }
                   Text { id: feedback_4; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   // Axis 6
                   Text { text: "axis 6:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_5; text: "0"; width: 80;
                       onAccepted: sendSingle(5)
                   }
                   Text { id: feedback_5; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   // Axis 7
                   Text { text: "axis 7:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_6; text: "0"; width: 80;
                       onAccepted: sendSingle(6)
                   }
                   Text { id: feedback_6; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   //axis 8
                   Text { text: "axis 8:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_7; text: "0"; width: 80;
                       onAccepted: sendSingle(7)
                   }
                   Text { id: feedback_7; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   //axis 9
                   Text { text: "axis 9:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_8; text: "0"; width: 80;
                       onAccepted: sendSingle(8)
                   }
                   Text { id: feedback_8; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   //axis 10
                   Text { text: "axis 10:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_9; text: "0"; width: 80;
                       onAccepted: sendSingle(9)
                   }
                   Text { id: feedback_9; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                   //axis 11
                   Text { text: "axis 11:"; verticalAlignment: Text.AlignVCenter }
                   TextField {
                       id: input_10; text: "0"; width: 80;
                       onAccepted: sendSingle(10)
                   }
                   Text { id: feedback_10; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }
               }
        Grid {
                columns: 3
                width: parent.width * 0.5 - 5
                spacing: 10
                // Finger 1
                Text { text: "Finger 1:"; verticalAlignment: Text.AlignVCenter }
                TextField {
                    id: inputH_0; text: "0"; width: 80;
                    onAccepted: sendSingleHand(0) // 回车也能发
                }
                Text { id: feedbackH_0; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                // Finger 2
                Text { text: "Finger 2:"; verticalAlignment: Text.AlignVCenter }
                TextField {
                    id: inputH_1; text: "0"; width: 80;
                    onAccepted: sendSingleHand(1)
                }
                Text { id: feedbackH_1; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                // Finger 3
                Text { text: "Finger 3:"; verticalAlignment: Text.AlignVCenter }
                TextField {
                    id: inputH_2; text: "0"; width: 80;
                    onAccepted: sendSingleHand(2)
                }
                Text { id: feedbackH_2; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                // Finger 4
                Text { text: "Finger 4:"; verticalAlignment: Text.AlignVCenter }
                TextField {
                    id: inputH_3; text: "0"; width: 80;
                    onAccepted: sendSingleHand(3)
                }
                Text { id: feedbackH_3; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                // Finger 5
                Text { text: "Finger 5:"; verticalAlignment: Text.AlignVCenter }
                TextField {
                    id: inputH_4; text: "0"; width: 80;
                    onAccepted: sendSingleHand(4)
                }
                Text { id: feedbackH_4; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }

                // Finger 6
                Text { text: "Finger 6:"; verticalAlignment: Text.AlignVCenter }
                TextField {
                    id: inputH_5; text: "0"; width: 80;
                    onAccepted: sendSingleHand(5)
                }
                Text { id: feedbackH_5; text: "0"; verticalAlignment: Text.AlignVCenter; color: "blue" }
        }
}
        Button {
            text: "发送全部(机械臂部分)"
                       width: parent.width
                       height: 40
                       onClicked: {
                   if(!root.checkServoReady())return;
                           var msg = "1001:"
                           msg += input_0.text + ","
                           msg += input_1.text + ","
                           msg += input_2.text + ","
                           msg += input_3.text + ","
                           msg += input_4.text + ","
                           msg += input_5.text + ","
                           msg += input_6.text + ","
                           msg += input_7.text + ","
                           msg += input_8.text + ","
                           msg += input_9.text + ","
                           msg += input_10.text
                           tcpManager.sendMessage(msg)
                       }
                   }
         Button{
             text: "发送全部(机械手部分)"
                      width: parent.width
                      height: 40
                      onClicked: {
                   if(!root.checkServoReady())return;
                      var msg = "1002:"
                      msg += inputH_0.text + ","
                      msg += inputH_1.text + ","
                      msg += inputH_2.text + ","
                      msg += inputH_3.text + ","
                      msg += inputH_4.text + ","
                      msg += inputH_5.text
                      tcpManager.sendMessage(msg)
                      }
         }

         Button {
                   text: "断开连接按钮"
                        width: parent.width
                        height: 40
                        onClicked: tcpManager.disconnectFromServer()
         }

         Text {
                   id: errorText
                   text: ""
                   font.pixelSize: 14
                   color: "red"
                   anchors.horizontalCenter: parent.horizontalCenter
                   visible: false  // 默认隐藏
    }
}
    Connections {        target: tcpManager
        function onArmDataReceived(values) {

                   // 安全检查：防止传过来空数据
                   if (!values) {
                      return;
                   }
                   if (values.length !==11){
                   errorText.text = "机械臂数据格式错误";
                   errorText.visible = true;
                   return;
                   }
                   errorText.visible = false;
                   //隐藏错误界面
                   if (values.length > 0) feedback_0.text = values[0];
                   if (values.length > 1) feedback_1.text = values[1];
                   if (values.length > 2) feedback_2.text = values[2];
                   if (values.length > 3) feedback_3.text = values[3];
                   if (values.length > 4) feedback_4.text = values[4];
                   if (values.length > 5) feedback_5.text = values[5];
                   if (values.length > 6) feedback_6.text = values[6];
                   if (values.length > 7) feedback_7.text = values[7];
                   if (values.length > 8) feedback_8.text = values[8];
                   if (values.length > 9) feedback_9.text = values[9];
                   if (values.length > 10) feedback_10.text = values[10];
                   }
        function onHandDataReceived(values){
                   if (!values) {
                   return;}

                   if (values.length !== 6) {
                   errorText.text = "机械手数据格式错误";
                   errorText.visible = true;
                   return;
        }          if (values.length > 0)feedbackH_0.text = values[0];
                   if (values.length > 1)feedbackH_1.text = values[1];
                   if (values.length > 2)feedbackH_2.text = values[2];
                   if (values.length > 3)feedbackH_3.text = values[3];
                   if (values.length > 4)feedbackH_4.text = values[4];
                   if (values.length > 5)feedbackH_5.text = values[5];
        }
        function onErrorMessage(msg) {
                    errorText.text = msg;
                    errorText.visible = true;
                }
         function onConnectionStatusChanged(status){
            statusText.text = status
            errorText.visible = false
        }
}
}
    Rectangle {
        id: runPage
        anchors.fill: parent
        color: "#f0f0f0" // 浅灰色背景
    Item {
        id: container
        anchors.fill: parent
    Grid{              columns: 2
                       spacing: 10
                       anchors.top:parent.top
                       anchors.left:parent.left
                       anchors.margins:20
                       TextField{
                           id:instruction_1 ; text:"";width: 120;height:40;
                           background: Rectangle {
                                   color: "white"
                                   border.color: "#ccc"
                                   border.width: 1
                                   radius: 4
                               }
                       }
                       Button{
                       text:"发送"
                       width: 80
                       height:40
                       onClicked: { if(!root.checkServoReady())return;
                                          tcpManager.sendMessage("1005:"+instruction_1.text)}
                       }
              }
    }
    }
    Rectangle{
        id:settings
        anchors.fill: parent
        color: "#f0f0f0"
        Item{
             anchors.fill:parent
             Button{
                    id:modeBtn
                    text:"切换模式"
                    anchors.top:parent.top
                    anchors.left:parent.left
                    anchors.margins:20
                    width:130
                    height:50
                    onClicked: {
                   if(!root.checkServoReady())return;
                   var pos = modeBtn.mapToItem(modePopup.parent, 0, modeBtn.height + 5)
                   modePopup.x = pos.x
                   modePopup.y = pos.y
                   modePopup.open();
             }
             }

             }
        }
    Rectangle{
                   id: imagePage
                   color: "#E0E0E0"
                   anchors.fill: parent
                   property real currentAngle: 0
                   Component.onCompleted: {
                       targetPos = Qt.point(0, 0)
                   }
                   Button {
                               id: loadBtn
                               text: "加载图片"
                               anchors.top: parent.top
                               anchors.horizontalCenter: parent.horizontalCenter
                               anchors.topMargin: 20
                               onClicked: {
                                                  if(!root.checkServoReady())return;
                                   imageItem.source = "file:///C:/Users/sz/Downloads/lab_7.6.pgm"
                               }
                           }
                   Rectangle {
                   id: mapContainer
                   anchors.top: loadBtn.bottom
                   anchors.left: parent.left
                   anchors.right: parent.right
                   anchors.bottom: parent.bottom
                   anchors.margins: 10 // 这里的 margins 只是为了让容器离边远点，不影响内部坐标
                   Image {
                               id: imageItem
                               anchors.fill: parent // 填满容器
                               fillMode: Image.PreserveAspectFit
                               MouseArea {
                                      anchors.fill: parent
                                      property point startPos: Qt.point(0, 0)  // 存储起始点击位置
                                      property point currentPos: Qt.point(0, 0) // 存储当前鼠标位置
                                      onPressed:function(mouse){
                                      if(!root.checkServoReady()) return;

                                      var paintedX = (imageItem.width - imageItem.paintedWidth) / 2;
                                      var paintedY = (imageItem.height - imageItem.paintedHeight) / 2;

                                      if (mouse.x < paintedX || mouse.x > paintedX + imageItem.paintedWidth ||
                                      mouse.y < paintedY || mouse.y > paintedY + imageItem.paintedHeight) {
                                      marker.visible = false;
                                      arrow.visible = false;
                                      return;
                                      }
                                      imagePage.currentAngle=0;
                                      //记录目标点坐标，起始点和当前坐标
                                      startPos=Qt.point(mouse.x,mouse.y);
                                      currentPos=Qt.point(mouse.x,mouse.y);
                                      targetPos = Qt.point(mouse.x, mouse.y);
                                      //4.显示绿点
                                      marker.x = mouse.x-marker.width/2;
                                      marker.y = mouse.y-marker.height/2;
                                      marker.visible = true;
                                      //5.显示箭头，定位到起始点
                                      arrow.x = startPos.x
                                      arrow.y = startPos.y - arrow.height / 2;
                                      arrow.visible = true;
                                      arrow.rotation = 0;  // 初始角度归零


                                           }
                                      onPositionChanged:function(mouse){
                                      if(!arrow.visible)return;
                                      //更新当前位置
                                      currentPos=Qt.point(mouse.x,mouse.y);
                                      // 计算鼠标相对于箭头中心的偏移
                                      var dx = currentPos.x - startPos.x;
                                      var dy = currentPos.y - startPos.y;
                                      if (dx === 0 && dy === 0) return;
                                      // atan2 算角度
                                      var rad = Math.atan2(dy, dx);
                                      var deg = rad * (180 / Math.PI);
                                      imagePage.currentAngle=deg;
                                      arrow.rotation=deg;

                                      }
                                      onReleased:function(mouse){
                                      if (!arrow.visible) return;
                                      targetPos=currentPos;
                                      var paintedX = (imageItem.width - imageItem.paintedWidth) / 2;
                                      var paintedY = (imageItem.height - imageItem.paintedHeight) / 2;
                                      var localPixelX = targetPos.x - paintedX;
                                      var localPixelY = targetPos.y - paintedY;
                                       var scaleFactor = imageItem.paintedWidth / imageItem.sourceSize.width;
                                      var originPixelX = localPixelX / scaleFactor;
                                      var originPixelY = localPixelY / scaleFactor;
                                          var worldX = mapOriginX + (originPixelX * mapResolution);
                                          var worldY = mapOriginY + ((imageItem.sourceSize.height - originPixelY) * mapResolution);
                                          var thetaRad = imagePage.currentAngle * Math.PI / 180.0;
                                          var qz = Math.sin(thetaRad / 2.0);
                                          var qw = Math.cos(thetaRad / 2.0);
                                      var messageLocation = worldX.toFixed(3) + "," +
                                      worldY.toFixed(3) + "," + qz.toFixed(4) + "," + qw.toFixed(4);
                                      if(!root.checkServoReady())return;
                                      tcpManager.sendMessage("1007:"+messageLocation);
                                      }
                                       }
                               asynchronous: true  // 异步加载，避免大图卡顿
                           }

                   Rectangle {
                           id: marker
                           width: 10; height: 10
                           radius: 5
                           color: "black"
                           visible: false
                           z:10
                       }
                   Image{
                          id:arrow
                          width: 40
                          height: 40
                          source:"file:///C:/Users/sz/Downloads/arrow.png"
                          visible:false
                          z:20
                          transformOrigin: Item.Left
                   // 绑定旋转角度
                   rotation: imagePage.currentAngle
                   }
    }
    }
    }
}
    Popup {
            id: modePopup

            // 关键配置
            modal: false
            focus: true
            closePolicy: Popup.CloseOnPressOutside
            background: Item {}
    // 菜单内容

            Rectangle {
                width: 170
                height: 190
                color: "#E0E0E0"
                border.color: "#999"
                radius: 5
                Column {
                    anchors.fill: parent
                    spacing: 5
                    padding: 10

                    Button {
                        text: "示教模式"; width: 150; height: 50
                        onClicked: { tcpManager.sendMessage("1006:0");
                                      modeBtn.text="示教模式"
                                           modePopup.close() }
                    }
                    Button {
                        text: "运行模式"; width: 150; height: 50
                        onClicked: { tcpManager.sendMessage("1006:1");
                                      modeBtn.text="运行模式"
                                           modePopup.close() }
                    }
                    Button {
                        text: "远程模式"; width: 150; height: 50
                        onClicked: { tcpManager.sendMessage("1006:2");
                                      modeBtn.text="远程模式"
                                           modePopup.close() }
                    }
                  }
               }
           }
    Text{
            id:enableError
            text: ""
            font.pixelSize:14
            color:"red"
            x:225
            y:130
            visible: false
            z:100
    }
    Timer {
            id: errorTimer
            interval: 3000  // 3秒
            onTriggered: {
                enableError.visible = false;
                enableError.text = "";
            }
    }
    function checkServoReady(){
                       if(!isServoReady){
                                          enableError.text="错误,未激活伺服供电"
                                          enableError.visible=true;
                                          errorTimer.restart();
                                          return false;
                       }
                       if(!isServoReady_1){
                                          enableError.text="错误,未使能"
                                          enableError.visible=true;
                                          errorTimer.restart();
                                          return false;
                       }
                       enableError.visible=false;
                       enableError.text="";
                       errorTimer.stop();
                       return true;
                       }
    }
