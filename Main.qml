import QtQuick 2.15
//Qt基础组件
import QtQuick.Controls 2.15
//Qt按钮，文本框
import QtQuick.Layouts
import MyMapTools 1.0
import QtQuick.Dialogs
import QtQuick.Effects
ApplicationWindow {
    id:root
    visible: true
    //显示窗口
    width: 500
    height: 900
    title: "TCP 测试客户端"
    color: "#1a1b26"

    Canvas { id: gridCanvas; anchors.fill: parent; z: -1
        onPaint: { var ctx = getContext("2d"); ctx.clearRect(0,0,width,height);
            var cx=width/2,cy=height*0.3,mx=Math.max(width,height)*1.5;
            ctx.strokeStyle="rgba(0,255,255,0.04)"; ctx.lineWidth=0.5;
            var st=40,ln=Math.floor(mx/st);
            for(var i=-ln;i<=ln;i++){ var a=Math.atan2(i*st,mx);
                ctx.beginPath(); ctx.moveTo(cx-i*st,cy);
                ctx.lineTo(cx+Math.cos(a)*mx,cy+Math.sin(a)*mx); ctx.stroke(); }
            for(var j=0;j<20;j++){ var r=j*st*2+20;
                ctx.beginPath(); ctx.ellipse(cx-r,cy-r*0.4,r*2,r*0.8); ctx.stroke(); }
        }
    }
    property var inputvalues:["0","0","0","0","0","0","0","0","0","0","0"]
    property var feedbackValues:["0","0","0","0","0","0","0","0","0","0","0"]
    property var inputvalues_hands:["0","0","0","0","0","0"]
    property var feedbackValues_hands:["0","0","0","0","0","0"]
    property bool isServoReady: false
    property bool isServoReady_1:false
    property bool isServerConnected: false
    property int currentPageIndex: 0
    property double mapResolution: 0.05      // resolution
    property double mapOriginX: -3.8         // origin[0]
    property double mapOriginY: -5.55        // origin[1]
    property real currentAngleDegree:0
    property point targetPos: Qt.point(0, 0)
    property real pixelX: 0
    property real pixelY: 0
    Rectangle//引航栏
        {
            id: topNavBar
            width: parent.width
            height: 60 // 导航栏高度
            color: "#1a1e2e"
            Text {
                id: statusText
                text: "未连接 (等待点击连接)"
                font.pixelSize: 15
                color: "#E0E0E0"
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 20
                layer.enabled: true
                layer.effect: MultiEffect { shadowColor: "#00FFFF"; shadowBlur: 1.0; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
            }

        Switch{
             id:servoSwitch
             enabled: isServerConnected
             x:20
             y:20
             checked:false
             indicator:Rectangle{
                  implicitHeight: 20
                  implicitWidth: 40
                  radius:10
                  color: servoSwitch.checked ? "#00FFFF":"#333333"
                  Rectangle{
                  x: servoSwitch.checked ? parent.width - width-2 :2
                  y:2
                  width: 16
                  height: 16
                  radius:8
                  color: "#E0E0E0"
                  }
             }

             onCheckedChanged: {
                     if (checked) {
                         tcpManager.sendMessage("1003:1");
                         isServoReady = true;
                         statusLabel.text="伺服已供电"
                         statusLabel.color="#00FFFF"
                     } else {
                         tcpManager.sendMessage("1003:0");
                         isServoReady = false;
                         statusLabel.text="伺服已断电"
                         statusLabel.color="#FF4444"
                     }
                 }
        }
        Text{
                id: statusLabel
                x:20;
                y:40;
                text:"伺服状态"
                font.pixelSize: 14
                color: "#E0E0E0"
        }
        Text{
                id: statusLabel_1
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.top: parent.top
                anchors.topMargin: 40
                text:"使能状态"
                font.pixelSize: 14
                color: "#E0E0E0"
        }

        Switch{
                id:servoSwitch_1
                enabled: isServerConnected
                anchors.right: parent.right
                anchors.rightMargin: 20
                anchors.top: parent.top
                anchors.topMargin: 20
                checked:false
                indicator:Rectangle{
                     implicitHeight: 20
                     implicitWidth: 40
                     radius:10
                     color: servoSwitch_1.checked ? "#00FFFF":"#333333"
                     Rectangle{
                     x: servoSwitch_1.checked ? parent.width - width-2 :2
                     y:2
                     width: 16
                     height: 16
                     radius:8
                     color: "#E0E0E0"
                     }
                }
                onCheckedChanged: {
                        if (checked) {
                            tcpManager.sendMessage("1004:1");
                            isServoReady_1 = true;
                            statusLabel_1.text="已使能"
                            statusLabel_1.color="#00FFFF"
                        } else {
                            tcpManager.sendMessage("1004:0");
                            isServoReady_1 = false;
                            statusLabel_1.text="未使能"
                            statusLabel_1.color="#FF4444"
                        }
                    }
        }
    }

    SwipeView {
        id: swipeView
        anchors.top: topNavBar.bottom
        anchors.bottom: pageIndicator.top
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        interactive: true

        currentIndex: currentPageIndex
    Rectangle //主页面
    {
        id: mainPage
        color: "#1a1b26"
    Column {
        //垂直布局容器
        anchors.centerIn: parent
        //于父容器居中放置
        spacing: 10
        width: parent.width * 0.9
        //父容器的70%

        Row{
                width:parent.width - 40
                anchors.horizontalCenter: parent.horizontalCenter
                spacing:10
        Grid {
                   columns: 3
                   spacing: 10
                   width: parent.width*0.5 - 5

                   // Axis 1
                   Text { text: "axis 1:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_0; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_0.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                        }
                   }
                   Text { id: feedback_0; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   // Axis 2
                   Text { text: "axis 2:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_1; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_1.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                        }
                   }
                   Text { id: feedback_1; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   // Axis 3
                   Text { text: "axis 3:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_2; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_2.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                        }
                   }
                   Text { id: feedback_2; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   // Axis 4
                   Text { text: "axis 4:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_3; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_3.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                        }
                   }
                   Text { id: feedback_3; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   // Axis 5
                   Text { text: "axis 5:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_4; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_4.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                        }
                   }
                   Text { id: feedback_4; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   // Axis 6
                   Text { text: "axis 6:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_5; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_5.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                        }
                   }
                   Text { id: feedback_5; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   // Axis 7
                   Text { text: "axis 7:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_6; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_6.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                        }
                   }
                   Text { id: feedback_6; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   //axis 8
                   Text { text: "axis 8:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_7; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_7.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                   }
                   }
                   Text { id: feedback_7; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   //axis 9
                   Text { text: "axis 9:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_8; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_8.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                        }
                   }
                   Text { id: feedback_8; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   //axis 10
                   Text { text: "axis 10:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_9; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                       }
                       background:Rectangle{
                       border.color: input_9.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                   }
                   }
                   Text { id: feedback_9; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                   //axis 11
                   Text { text: "axis 11:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                   TextField {
                       id: input_10; text: "0"; width: 80;
                       validator: DoubleValidator {
                               bottom: -360
                               top: 360
                           }
                       background:Rectangle{
                       border.color: input_10.acceptableInput ? "#333" : "#FF4444"
                       border.width: 2
                        }
                   }
                   Text { id: feedback_10; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
               }
        Grid {
                columns: 3
                width: parent.width * 0.5 - 5
                spacing: 10
                // Finger 1
                Text { text: "Finger 1:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                TextField {
                    id: inputH_0; text: "0"; width: 80;
                    validator: IntValidator {
                            bottom: 0
                            top: 100
                        }
                    background:Rectangle{
                    border.color: inputH_0.acceptableInput ? "#333" : "#FF4444"
                    border.width: 2
                     }
                }
                Text { id: feedbackH_0; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                // Finger 2
                Text { text: "Finger 2:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                TextField {
                    id: inputH_1; text: "0"; width: 80;
                    validator: IntValidator {
                            bottom: 0
                            top: 100
                        }
                    background:Rectangle{
                    border.color: inputH_1.acceptableInput ? "#333" : "#FF4444"
                    border.width: 2
                     }
                }
                Text { id: feedbackH_1; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                // Finger 3
                Text { text: "Finger 3:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                TextField {
                    id: inputH_2; text: "0"; width: 80;
                    validator: IntValidator {
                            bottom: 0
                            top: 100
                        }
                    background:Rectangle{
                    border.color: inputH_2.acceptableInput ? "#333" : "#FF4444"
                    border.width: 2
                     }
                }
                Text { id: feedbackH_2; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                // Finger 4
                Text { text: "Finger 4:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                TextField {
                    id: inputH_3; text: "0"; width: 80;
                    validator: IntValidator {
                            bottom: 0
                            top: 100
                        }
                   background:Rectangle{
                   border.color: inputH_3.acceptableInput ? "#333" : "#FF4444"
                   border.width: 2
                    }
                }
                Text { id: feedbackH_3; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                // Finger 5
                Text { text: "Finger 5:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                TextField {
                    id: inputH_4; text: "0"; width: 80;
                    validator: IntValidator {
                            bottom: 0
                            top: 100
                        }
                   background:Rectangle{
                   border.color: inputH_4.acceptableInput ? "#333" : "#FF4444"
                   border.width: 2
                    }
                }
                Text { id: feedbackH_4; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }

                // Finger 6
                Text { text: "Finger 6:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                TextField {
                    id: inputH_5; text: "0"; width: 80;
                    validator: IntValidator {
                            bottom: 0
                            top: 100
                        }
                   background:Rectangle{
                   border.color: inputH_5.acceptableInput ? "#333" : "#FF4444"
                   border.width: 2
                    }
                }
                Text { id: feedbackH_5; text: "0"; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
        }
}
        Text{
                 id:rangeError
                 text: ""
                 font.pixelSize:14
                 color:"red"
                 anchors.horizontalCenter: parent.horizontalCenter
                 y:110
                 visible: false
                 z:100
        }
        Timer{
                 id:validationCheck
                 interval:100
                 running: true
                 repeat: true
        onTriggered: {
                   //把每个输入存入一个数组变量
                   var allInputs = [   input_0, input_1, input_2, input_3, input_4, input_5,
                                       input_6, input_7, input_8, input_9, input_10,
                                       inputH_0, inputH_1, inputH_2, inputH_3, inputH_4, inputH_5]
                   //引入新变量用于判断错误
                   var hasError = false;
                   for (var i = 0; i < allInputs.length; i++) {
                                       // 只要有一个输入框的状态不是 "Acceptable" (合法)，就标记为有错误
                                      if (!allInputs[i].acceptableInput) {
                                                      hasError = true;
                                                      break;
                                                  }
                   }
                   rangeError.visible = hasError;
                   rangeError.text = hasError ? "输入有误，请检查数值范围和格式！" : "";
        }
}
        Button {
            text: "发送全部(机械臂部分)"
                       width: parent.width
                       height: 40
                       onClicked: {
                   if(!root.checkServoReady())return;
                   if(!input_0.acceptableInput||
                      !input_1.acceptableInput||
                      !input_2.acceptableInput||
                      !input_3.acceptableInput||
                      !input_4.acceptableInput||
                      !input_5.acceptableInput||
                      !input_6.acceptableInput||
                      !input_7.acceptableInput||
                      !input_8.acceptableInput||
                      !input_9.acceptableInput||
                      !input_10.acceptableInput){
                                      rangeError.text="输入数据超过范围"
                                      return;
                   }
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
                   if(!inputH_0.acceptableInput||
                   !inputH_1.acceptableInput||
                   !inputH_2.acceptableInput||
                   !inputH_3.acceptableInput||
                   !inputH_4.acceptableInput||
                   !inputH_5.acceptableInput){
                   rangeError.text="输入数据超过范围"
                   return;
                   }
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
        color: "#1a1b26"
    Item {
        id: container
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height * 0.5
    Grid{              columns: 2
                       spacing: 10
                       anchors.fill: parent
                       anchors.margins:20
                       TextField{
                           id:instruction_1 ; text:"";width: 120;height:40;
                           validator: RegularExpressionValidator {
                                   regularExpression: /^[a-zA-Z][a-zA-Z0-9_]*$/
                           }

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
    Item{
                       id:gamepadRoot
                       anchors.left: parent.left
                       anchors.right: parent.right
                       anchors.top: container.bottom
                       anchors.bottom: parent.bottom
                       property real maxLinearVel: 0.6        // m/s
                       property real maxAngularVel: 0.7       // rad/s
                       property real maxLinearAccel: 0.8      // m/s²
                       property real maxAngularAccel: 3.0    // rad/s²
                       property real linearVel: 0            // current linear velocity
                       property real angularVel: 0           // current angular velocity
                       property real joystickCenterX: 0
                       property real joystickCenterY: 0

                       function updateVelocities() {
                           // Calculate normalized joystick output [-1, 1]
                           var normX = 0
                           var normY = 0
                           if (joystickCenterX !== 0 && joystickCenterY !== 0) {
                               //计算摇杆偏离中心多少像素
                               normX = (stickKnob.x - joystickCenterX) / 25.0
                               normY = (stickKnob.y - joystickCenterY) / 25.0
                               // 变到+1到-1的比例值
                               normX = Math.max(-1, Math.min(1, normX))
                               normY = Math.max(-1, Math.min(1, normY))
                           }

                           // 目标速度
                           var targetLinear = -normY * maxLinearVel   // 线性速度，向上为正
                           var targetAngular = normX * maxAngularVel  // 角速度向，向右为正

                           // linDiff,目标速度和当前速度的差距
                           var linDiff = targetLinear - linearVel
                           var maxLinDelta = maxLinearAccel * 0.05  // 在16ms，60fps最多允许变化的速度量
                           if (Math.abs(linDiff) < maxLinDelta) {
                               linearVel = targetLinear
                           } else {
                               linearVel += Math.sign(linDiff) * maxLinDelta
                           }

                           // 角速度加速度限制
                           var angDiff = targetAngular - angularVel
                           var maxAngDelta = maxAngularAccel * 0.05
                           if (Math.abs(angDiff) < maxAngDelta) {
                               angularVel = targetAngular
                           } else {
                               angularVel += Math.sign(angDiff) * maxAngDelta
                           }
                       }

                       Timer {
                           interval: 50
                           running: true
                           repeat: true
                           onTriggered:{ gamepadRoot.updateVelocities()
                           var epsilon =0.001;
                           if (Math.abs(gamepadRoot.linearVel)>epsilon||Math.abs(gamepadRoot.angularVel)>epsilon){
                           tcpManager.sendMessage("1008:"+gamepadRoot.linearVel.toFixed(2)+","+gamepadRoot.angularVel.toFixed(2))}
                       }
}
                       Rectangle{
                       id:body_gamepad
                       anchors.fill: parent
                       color:"#1a1b26"
                       }
                       Item{
                                      id: joystickComponent
                                      anchors.centerIn: parent
                                      width: 120
                                      height: 120


                       Rectangle{
                       id:stickBase
                       anchors.centerIn: parent
                       x: (gamepadRoot.width - width) / 2
                       y: (gamepadRoot.height - height) / 2
                       width: 100
                       height: 100
                       radius: 50
                       color: "#2a2a3a"
                       border.color: "#00FFFF"
                       border.width: 2
                       }
                       Rectangle {
                                   id: stickKnob
                                   width: 50
                                   height: 50
                                   radius: 25
                                   color: "#00FFFF"
                                   x: stickBase.x + 25
                                   y: stickBase.y + 25
                                   MouseArea {
                                       anchors.fill: parent
                                       drag.target: stickKnob
                                               drag.axis: Drag.XAndYAxis
                                               drag.minimumX: stickBase.x
                                               drag.maximumX: stickBase.x + 50
                                               drag.minimumY: stickBase.y
                                               drag.maximumY: stickBase.y + 50

                                               onReleased: {
                                                   stickKnob.x = stickBase.x + 25
                                                   stickKnob.y = stickBase.y + 25
                                               }
                                   }
                               }
    }

    Component.onCompleted: {
        joystickCenterX = stickBase.x + 25
        joystickCenterY = stickBase.y + 25
    }
    }
    }
    Rectangle{
        id:settings
        color: "#1a1b26"
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
                  Column{
                  id:layoutColumn
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.left: parent.left
                  anchors.margins: 20
                  width: 280
                   height: 150
                  spacing:10
                  z:10
                  Text{
                  text: "服务器设置"
                  font.pixelSize: 16
                  color:"#E0E0E0"
                  }
                  Row{
                   width: parent.width
                   height: 30
                   spacing: 10
                  TextField{
                  id:ipInput
                  width: parent.width * 0.65
                   height: parent.height
                   placeholderText: "IP 地址"
                   font.pixelSize: 14
                  }
                  TextField {
                                  id: portInput
                                  width: parent.width * 0.30
                                  height: parent.height
                                  placeholderText: "端口"
                                  font.pixelSize: 14
                                  // 限制只能输入数字
                                  validator: IntValidator { bottom: 1; top: 65535 }
                              }
                  }
                  Button {
                                  width: (parent.width - 10) / 2
                                  height: 30
                                  text: "连接"
                                  onClicked: {
                                      var ip = ipInput.text.trim();
                                      var port = parseInt(portInput.text);
                                      if (ip === "" || isNaN(port)) return;
                                      tcpManager.connectToServer(ip, port);
                                      isServerConnected = true;
                                  }
                              }
                  Button {
                                  width: (parent.width - 10) / 2
                                  height: 30
                                  text: "断开"
                                  onClicked: {
                                      tcpManager.disconnectFromServer();
                                      isServerConnected= false;
                                  }
                              }
                  }
        }
    Rectangle{
                   id: imagePage
                   color: "#1a1b26"
                   property real currentAngle: 0
                   property bool updatingQz: false
                   property bool updatingQw: false
                   function checkAndUpdateMarker() {
                       if (!inputX.acceptableInput || !inputY.acceptableInput ||
                           !inputQz.acceptableInput || !inputQw.acceptableInput) {
                           return;
                       }
                       updateMarker();
                   }
                   function updateMarker() {
                       var worldX = parseFloat(inputX.text);
                       var worldY = parseFloat(inputY.text);
                       var qz = parseFloat(inputQz.text);
                       var qw = parseFloat(inputQw.text);
                       
                       // 世界坐标转像素坐标
                       var pixelX = (worldX - mapOriginX) / mapResolution;
                       var pixelY = (imageItem.sourceSize.height - (worldY - mapOriginY) / mapResolution);
                       
                       // 像素坐标转显示坐标
                       var scaleFactor = imageItem.paintedWidth / imageItem.sourceSize.width;
                       var paintedX = (imageItem.width - imageItem.paintedWidth) / 2;
                       var paintedY = (imageItem.height - imageItem.paintedHeight) / 2;
                       
                       var displayX = paintedX + pixelX * scaleFactor;
                       var displayY = paintedY + pixelY * scaleFactor;
                       
                       // 四元数转角度
                       var angleRad = 2 * Math.atan2(qz, qw);
                       var angleDeg = angleRad * 180 / Math.PI;
                       
                       marker.x = displayX - marker.width / 2;
                       marker.y = displayY - marker.height / 2;
                       marker.visible = true;
                       
                       imagePage.currentAngle = angleDeg;
                       arrow.x = displayX;
                       arrow.y = displayY - arrow.height / 2;
                       arrow.rotation = angleDeg;
                       arrow.visible = true;
                   }
                   Component.onCompleted: {
                       targetPos = Qt.point(0, 0)
                   }

                   // 外层 RowLayout：左边输入框，右边地图
                   RowLayout {
                       anchors.top: parent.top
                       anchors.left: parent.left
                       anchors.right: parent.right
                       anchors.bottom: parent.bottom
                       anchors.topMargin: 10
                       anchors.leftMargin: 10
                       anchors.rightMargin: 10
                       anchors.bottomMargin: 10
                       spacing: 10

                       // 左边：输入框区域（垂直排列）
                       ColumnLayout {
                           id: inputArea
                           spacing: 10
                           Layout.preferredWidth: 180

                           // X 输入框
                           Row {
                               spacing: 5
                               Text { text: "X:"; width: 30; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                               TextField {
                                   id: inputX; text: "0"; width: 130
                                   validator: DoubleValidator {
                                       bottom: -3.8
                                       top: 13.6
                                   }
                                   background: Rectangle {
                                       border.color: inputX.acceptableInput ? "white" : "red"
                                       border.width: 2
                                   }
                                   onTextChanged: {
                                       imagePage.checkAndUpdateMarker();
                                   }
                               }
                           }

                           // Y 输入框
                           Row {
                               spacing: 5
                               Text { text: "Y:"; width: 30; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                               TextField {
                                   id: inputY; text: "0"; width: 130
                                   validator: DoubleValidator {
                                       bottom: -5.55
                                       top: 7.35
                                   }
                                   background: Rectangle {
                                       border.color: inputY.acceptableInput ? "white" : "red"
                                       border.width: 2
                                   }
                                   onTextChanged: {
                                       imagePage.checkAndUpdateMarker();
                                   }
                               }
                           }

                           // qz 输入框
                           Row {
                               spacing: 5
                               Text { text: "qz:"; width: 30; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                               TextField {
                                   id: inputQz; text: "0"; width: 130
                                   validator: DoubleValidator {
                                       bottom: -1
                                       top: 1
                                   }
                                   background: Rectangle {
                                       border.color: inputQz.acceptableInput ? "white" : "red"
                                       border.width: 2
                                   }
                                   onTextChanged: {
                                       if (imagePage.updatingQz) return;
                                       var qzVal = parseFloat(inputQz.text);
                                       if (isNaN(qzVal)) return;
                                       if (qzVal > 1) qzVal = 1;
                                       if (qzVal < -1) qzVal = -1;
                                       var qwVal = Math.sqrt(1 - qzVal * qzVal);
                                       imagePage.updatingQw = true;
                                       inputQw.text = qwVal.toFixed(4);
                                       imagePage.updatingQw = false;
                                       imagePage.checkAndUpdateMarker();
                                   }
                               }
                           }

                           // qw 输入框
                           Row {
                               spacing: 5
                               Text { text: "qw:"; width: 30; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                               TextField {
                                   id: inputQw; text: "1"; width: 130
                                   validator: DoubleValidator {
                                       bottom: -1
                                       top: 1
                                   }
                                   background: Rectangle {
                                       border.color: inputQw.acceptableInput ? "white" : "red"
                                       border.width: 2
                                   }
                                   onTextChanged: {
                                       if (imagePage.updatingQw) return;
                                       var qwVal = parseFloat(inputQw.text);
                                       if (isNaN(qwVal)) return;
                                       if (qwVal > 1) qwVal = 1;
                                       if (qwVal < -1) qwVal = -1;
                                       var qzVal = Math.sqrt(1 - qwVal * qwVal);
                                       imagePage.updatingQz = true;
                                       inputQz.text = qzVal.toFixed(4);
                                       imagePage.updatingQz = false;
                                       imagePage.checkAndUpdateMarker();
                                   }
                               }
                           }

                           // 发送按钮
                           Button {
                               text: "发送"
                               width: 160
                               onClicked: {
                                   if (!root.checkServoReady()) return;
                                   if (!inputX.acceptableInput || !inputY.acceptableInput ||
                                       !inputQz.acceptableInput || !inputQw.acceptableInput) {
                                       return;
                                   }

                                   var worldX = parseFloat(inputX.text);
                                   var worldY = parseFloat(inputY.text);
                                   var qz = parseFloat(inputQz.text);
                                   var qw = parseFloat(inputQw.text);

                                   var messageLocation = worldX.toFixed(3) + "," +
                                                       worldY.toFixed(3) + "," +
                                                       qz.toFixed(4) + "," +
                                                       qw.toFixed(4);
                                   tcpManager.sendMessage("1007:" + messageLocation);
                               }
                           }

                           // 选择图片按钮
                           Button {
                               text: "选择图片"
                               width: 160
                               onClicked: {
                                   openFileDialog.open()
                               }
                           }

                           // SSH下载图片按钮
                           Button {
                               text: "SSH下载图片"
                               width: 160
                               onClicked: {
                                   sshManager.startDownload()
                               }
                           }
                       }

                       // 右边：地图容器
                       Rectangle {
                           id: mapContainer
                           color: "#E0E0E0"
                           Layout.fillHeight: true
                           Layout.fillWidth: true
                           Image {
                               id: imageItem
                               anchors.fill: parent // 填满容器
                               fillMode: Image.PreserveAspectFit
                               MouseArea {
                                      anchors.fill: parent
                                      property bool isValidTarget: true
                                      property point startPos: Qt.point(0, 0)  // 存储起始点击位置
                                      property point currentPos: Qt.point(0, 0) // 存储当前鼠标位置
                                      onPressed:function(mouse){
                                      isValidTarget = true;
                                      if(!root.checkServoReady()) return;
                                      var paintedX = (imageItem.width - imageItem.paintedWidth) / 2;//容器宽度减去图片显示宽度，等于左右留白
                                      var paintedY = (imageItem.height - imageItem.paintedHeight) / 2;

                                      if (mouse.x < paintedX || mouse.x > paintedX + imageItem.paintedWidth ||
                                      mouse.y < paintedY || mouse.y > paintedY + imageItem.paintedHeight) {
                                      marker.visible = false;
                                      arrow.visible = false;
                                      return;
                                      }
                                      //图片边界检测，paintedX左边界，paintedX+Width右边界，paintedY上边界，paintedY+width下边界
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

                                      var grabX = mouse.x - paintedX;
                                      //在图片上的具体横坐标
                                      var grabY = mouse.y - paintedY;
                                      //在图片上的具体纵坐标
                                      var scaleFactor = imageItem.paintedWidth / imageItem.sourceSize.width;
                                      var x = Math.floor(grabX/scaleFactor);
                                      var y = Math.floor(grabY/scaleFactor);
                                      if (!mapProcessor.isOccupied(x, y)) {
                                              console.log("是白色区域，允许点击！");
                                          } else {
                                             marker.visible=false;
                                             arrow.visible = false;
                                             isValidTarget = false;
                                             return;
                                          }

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
                                      var localPixelX = startPos.x - paintedX;
                                      var localPixelY = startPos.y - paintedY;
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
                                      if (!isValidTarget) {
                                              return; // 直接退出，不发送任何数据
                                          }
                                      tcpManager.sendMessage("1007:"+messageLocation);
                                      }
                                       }
                               asynchronous: true  // 异步加载，避免大图卡顿
                           }

                           // marker 和 arrow 在 mapContainer 内部
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
                               source:"qrc:/arrow.png"
                               visible:false
                               z:20
                               transformOrigin: Item.Left
                               rotation: imagePage.currentAngle
                           }
                       } // 关闭 mapContainer
                   } // 关闭外层 RowLayout

                   // 文件选择对话框
                   FileDialog {
                       id: openFileDialog
                       title: "选择地图图片"
                       nameFilters: [
                           "PNG 图片 (*.png)",
                           "所有文件 (*)"
                       ]
                       onAccepted: {
                           var filePath = openFileDialog.selectedFile.toString()
                           imageItem.source = filePath
                           if (filePath.startsWith("file:///")) {
                               filePath = filePath.substring(8)
                           }
                           mapProcessor.loadMap(filePath)
                       }
                   }
    }
    Rectangle{
                   id: page5
                   color: "#1a1b26"
                   property string loadedImagePath: ""
                   property string penColor: "black"
                   Button{
                   id:loadbtn_1
                   text: "加载图片"
                   anchors.top:parent.top
                   anchors.horizontalCenter: parent.horizontalCenter
                   anchors.topMargin: 20
                   onClicked: {
                            page5FileDialog.open()
                   }
                   }
                   Image{
                            id:imageItem_1
                            anchors.top: loadbtn_1.bottom
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right:parent.right
                            anchors.margins: 30
                            fillMode: Image.PreserveAspectFit

                            // 坐标转换函数：将鼠标坐标转换为图片像素坐标
                            function mouseToPixel(mouseX, mouseY) {
                                // 计算图片显示区域的偏移（留白）
                                var offsetX = (imageItem_1.width - imageItem_1.paintedWidth) / 2
                                var offsetY = (imageItem_1.height - imageItem_1.paintedHeight) / 2

                                // 计算缩放因子
                                var scale = imageItem_1.sourceSize.width / imageItem_1.paintedWidth
                                if (scale <= 0) scale = 1

                                // 转换为图片像素坐标
                                var pixelX = (mouseX - offsetX) * scale
                                var pixelY = (mouseY - offsetY) * scale

                                return { x: pixelX, y: pixelY }
                            }
                            function pixelToWorld(pixelX, pixelY) {
                                // X 轴转换
                                var worldX = mapOriginX + (pixelX * mapResolution);

                                // Y 轴转换 (注意：图片Y轴向下，地图Y轴向上，需要翻转)
                                // imageItem_1.sourceSize.height 是图片原始高度
                                var worldY = mapOriginY + ((imageItem_1.sourceSize.height - pixelY) * mapResolution);

                                return { x: worldX, y: worldY };
                            }
                            MouseArea {
                                        id: mouseArea
                                        anchors.fill: parent
                                        enabled: imageItem_1.source !== ""

                                        property real startX: 0
                                        property real startY: 0
                                        property bool isDrawing: false
                                        property real currentWorldX: 0
                                        property real currentWorldY: 0
                                        onPressed: function(mouse) {
                                            var pos = imageItem_1.mouseToPixel(mouse.x, mouse.y)
                                            startX = pos.x
                                            startY = pos.y
                                            isDrawing = true
                                        }

                                        onPositionChanged: function(mouse) {
                                            if (isDrawing) {
                                                var pos = imageItem_1.mouseToPixel(mouse.x, mouse.y)
                                                var worldPos = imageItem_1.pixelToWorld(pos.x, pos.y);
                                                currentWorldX = Number(worldPos.x.toFixed(2));
                                                currentWorldY = Number(worldPos.y.toFixed(2));
                                                mapProvider.drawLine(
                                                    startX, startY,
                                                    pos.x, pos.y,
                                                    2,
                                                    page5.penColor
                                                )
                                                startX = pos.x
                                                startY = pos.y
                                                imageItem_1.source = ""
                                                imageItem_1.source = "image://mapProvider?" + Math.random()
                                            }
                                        }

                                        onReleased: function(mouse) {
                                            isDrawing = false
                                        }
                   }

                            }

                   Text{
                                      id:coordiateText
                                      anchors.right:parent.right
                                      anchors.top: parent.top
                                      anchors.topMargin: 30
                                      anchors.rightMargin: 30
                                      text: "横坐标X: " + mouseArea.currentWorldX + "横坐标Y: " + mouseArea.currentWorldY
                                      font.pixelSize: 16
                                      color:"#E0E0E0"
                                      z:10
                             }
                            Button {
                                text: "清空画布"
                                id:loadbtn_2
                                anchors.top: loadbtn_1.bottom
                                anchors.leftMargin: 20
                                anchors.topMargin: 20
                                onClicked: {
                                    if (page5.loadedImagePath !== "") {
                                        mapProvider.loadFromPng(page5.loadedImagePath)
                                        imageItem_1.source = ""
                                        imageItem_1.source = "image://mapProvider"
                                    }
                                }
                            }
                            Button{
                                text:"保存画布"
                                id:loadbtn_3
                                anchors.top:loadbtn_2.bottom
                                anchors.leftMargin: 20
                                anchors.topMargin:20
                                onClicked: saveDialog.open()
                            }
                            Button{
                                text:"灰色画笔"
                                id:loadbtn_4
                                anchors.top:loadbtn_3.bottom
                                anchors.leftMargin: 20
                                anchors.topMargin:20
                                onClicked: {
                                    page5.penColor = "#BFBFBF"
                                }
                            }
                            Button{
                                text:"黑色画笔"
                                id:loadbtn_5
                                anchors.top:loadbtn_4.bottom
                                anchors.leftMargin: 20
                                anchors.topMargin:20
                                onClicked: {
                                    page5.penColor = "black"
                                }
                            }

                            // 第5页面的文件选择对话框
                            FileDialog {
                                id: page5FileDialog
                                title: "选择图片"
                                nameFilters: [
                                    "PNG 图片 (*.png)",
                                    "所有文件 (*)"
                                ]
                                onAccepted: {
                                var filePath = page5FileDialog.selectedFile.toString()
                                if (filePath.startsWith("file:///")) {
                                    filePath = filePath.substring(8)
                                }
                                page5.loadedImagePath = filePath
                                mapProvider.loadFromPng(filePath)
                                imageItem_1.source = ""
                                imageItem_1.source = "image://mapProvider"
                                }
                            }
                   }
    }

    // ---- Page Indicator ----
    Row {
        id: pageIndicator
        anchors.bottom: bottomNavBar.top
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8
        Repeater {
            model: 5
            Rectangle {
                width: swipeView.currentIndex === index ? 16 : 8
                height: 8
                radius: 4
                color: swipeView.currentIndex === index ? "#00FFFF" : "#40FFFFFF"
                Behavior on width { NumberAnimation { duration: 200 } }
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }

    // ---- Floating Capsule Bottom Nav ----
    Rectangle {
        id: bottomNavBar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 32
        height: 64
        radius: 32
        color: "#D91E1E1E"
        border.color: "#00FFFF"
        border.width: 1
        clip: true
        layer.enabled: true
        layer.effect: MultiEffect { shadowColor: "#00FFFF"; shadowBlur: 1.0; shadowHorizontalOffset: 0; shadowVerticalOffset: 0 }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 0
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "指令"
                onClicked: { currentPageIndex = 0; swipeView.currentIndex = 0 }
                background: Rectangle {
                    radius: 12
                    color: (currentPageIndex === 0) ? "#1A00FFFF" : "transparent"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                contentItem: Column {
                    spacing: 2
                    anchors.centerIn: parent
                    Image {
                        id: icon0
                        source: "qrc:/Robotics_1.png"
                        width: 24; height: 24
                        fillMode: Image.PreserveAspectFit
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    MultiEffect {
                        anchors.fill: icon0
                        source: icon0
                        colorizationColor: (currentPageIndex === 0) ? "#00FFFF" : "#666666"
                        colorization: 1.0
                    }
                    Text {
                        text: parent.parent.text
                        color: (currentPageIndex === 0) ? "#00FFFF" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 11
                    }
                }
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "控制"
                onClicked: { currentPageIndex = 1; swipeView.currentIndex = 1 }
                background: Rectangle {
                    radius: 12
                    color: (currentPageIndex === 1) ? "#1A00FFFF" : "transparent"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                contentItem: Column {
                    spacing: 2
                    anchors.centerIn: parent
                    Image {
                        id: icon1
                        source: "qrc:/Joystick_1.png"
                        width: 24; height: 24
                        fillMode: Image.PreserveAspectFit
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    MultiEffect {
                        anchors.fill: icon1
                        source: icon1
                        colorizationColor: (currentPageIndex === 1) ? "#00FFFF" : "#666666"
                        colorization: 1.0
                    }
                    Text {
                        text: parent.parent.text
                        color: (currentPageIndex === 1) ? "#00FFFF" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 11
                    }
                }
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "设置"
                onClicked: { currentPageIndex = 2; swipeView.currentIndex = 2 }
                background: Rectangle {
                    radius: 12
                    color: (currentPageIndex === 2) ? "#1A00FFFF" : "transparent"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                contentItem: Column {
                    spacing: 2
                    anchors.centerIn: parent
                    Image {
                        id: icon2
                        source: "qrc:/setting_1.png"
                        width: 24; height: 24
                        fillMode: Image.PreserveAspectFit
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    MultiEffect {
                        anchors.fill: icon2
                        source: icon2
                        colorizationColor: (currentPageIndex === 2) ? "#00FFFF" : "#666666"
                        colorization: 1.0
                    }
                    Text {
                        text: parent.parent.text
                        color: (currentPageIndex === 2) ? "#00FFFF" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 11
                    }
                }
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "导航"
                onClicked: { currentPageIndex = 3; swipeView.currentIndex = 3 }
                background: Rectangle {
                    radius: 12
                    color: (currentPageIndex === 3) ? "#1A00FFFF" : "transparent"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                contentItem: Column {
                    spacing: 2
                    anchors.centerIn: parent
                    Image {
                        id: icon3
                        source: "qrc:/History.png"
                        width: 24; height: 24
                        fillMode: Image.PreserveAspectFit
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    MultiEffect {
                        anchors.fill: icon3
                        source: icon3
                        colorizationColor: (currentPageIndex === 3) ? "#00FFFF" : "#666666"
                        colorization: 1.0
                    }
                    Text {
                        text: parent.parent.text
                        color: (currentPageIndex === 3) ? "#00FFFF" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 11
                    }
                }
            }
            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                text: "作图"
                onClicked: { currentPageIndex = 4; swipeView.currentIndex = 4 }
                background: Rectangle {
                    radius: 12
                    color: (currentPageIndex === 4) ? "#1A00FFFF" : "transparent"
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                contentItem: Column {
                    spacing: 2
                    anchors.centerIn: parent
                    Image {
                        id: icon4
                        source: "qrc:/map_1.png"
                        width: 24; height: 24
                        fillMode: Image.PreserveAspectFit
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    MultiEffect {
                        anchors.fill: icon4
                        source: icon4
                        colorizationColor: (currentPageIndex === 4) ? "#00FFFF" : "#666666"
                        colorization: 1.0
                    }
                    Text {
                        text: parent.parent.text
                        color: (currentPageIndex === 4) ? "#00FFFF" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
    Popup{
            id: modePopup

            // 关键配置
            modal: false
            focus: true
            // closePolicy: Popup.CloseOnPressOutside
            background: Item {}
    // 菜单内容

            Rectangle {
                width: 170
                height: 190
                color: "#1a1e2e"
                border.color: "#00FFFF"
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
    ImageProcessor {
        id: mapReader
    }

    Component.onCompleted: {
        var path = "qrc:/lab_7.6.png";
        var success = mapReader.loadMap(path);
    }

    FileDialog {
        id: saveDialog
        title: "选择保存位置"
        fileMode: FileDialog.SaveFile
        nameFilters: [
            "PNG 图片 (*.png)",
            "所有文件 (*)"
        ]
        defaultSuffix: "png"

        onAccepted: {
            var path = selectedFile.toString()
            if (path.startsWith("file:///")) {
                path = path.substring(8)
            }
            mapProvider.saveAsPng(path)
        }
    }
}
