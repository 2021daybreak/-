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
    width: 800
    height: 1200
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
    // 各关节当前值（由各面板 TextField onTextChanged 实时同步）
    property var headValues: ["0", "0"]                     // Head 1-2
    property var bodyValues: ["0", "0", "0", "0"]           // Body 1-4
    property var leftArmValues: ["0","0","0","0","0","0","0"]  // LA 1-7
    property var rightArmValues: ["0","0","0","0","0","0","0"] // RA 1-7
    property var leftHandValues: ["0","0","0","0","0","0"]     // LH 1-6
    property var rightHandValues: ["0","0","0","0","0","0"]    // RH 1-6

    // 各关节反馈值（由 TCP 接收处理函数写入，fb_xxx Text 绑定读取）
    property var headFeedback: ["0", "0"]
    property var bodyFeedback: ["0", "0", "0", "0"]
    property var leftArmFeedback: ["0","0","0","0","0","0","0"]
    property var rightArmFeedback: ["0","0","0","0","0","0","0"]
    property var leftHandFeedback: ["0","0","0","0","0","0"]
    property var rightHandFeedback: ["0","0","0","0","0","0"]

    property int controlVelocity: 1   // 步进倍率，被所有 +/- 按钮引用
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

    // 全局发送全部关节数据（从根级别数组读取，不跨 Component 作用域）
    function sendAllJoints() {
        if(!checkServoReady()) return
        tcpManager.sendMessage("1111:" + headValues.join(","))
        tcpManager.sendMessage("2222:" + bodyValues.join(","))
        tcpManager.sendMessage("3333:" + leftArmValues.join(","))
        tcpManager.sendMessage("4444:" + rightArmValues.join(","))
        tcpManager.sendMessage("5555:" + leftHandValues.join(","))
        tcpManager.sendMessage("6666:" + rightHandValues.join(","))
    }

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
        interactive: false

        currentIndex: currentPageIndex
    Rectangle //主页面
    {
        id: mainPage
        color: "#1a1b26"
    Column {
        anchors.fill: parent
    RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            // ========== 左侧区域 70%（所有原有内容） ==========
            ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 70
                    spacing: 6
                    // ========== Tab 导航栏 ==========
                    RowLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        
                        property int currentTab: 0
                        
                        // Tab 1: 头部与躯干
                        Item {
                            Layout.preferredWidth: 44
                            Layout.fillWidth: false
                            Layout.preferredHeight: 40
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: parent.parent.currentTab === 0 ? "#00FFFF" : "#2a2a3a"
                                border.width: parent.parent.currentTab === 0 ? 2 : 1
                                radius: 4
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                Image { source: "qrc:/Body.png"; width: 24; height: 24; fillMode: Image.PreserveAspectFit; anchors.centerIn: parent }
                            }
                            MouseArea { anchors.fill: parent; onClicked: { parent.parent.currentTab = 0; mainPanelLoader.sourceComponent = headBodyPanel } }
                        }
                        // Tab 2: 左臂与右臂
                        Item {
                            Layout.preferredWidth: 44
                            Layout.fillWidth: false
                            Layout.preferredHeight: 40
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: parent.parent.currentTab === 1 ? "#00FFFF" : "#2a2a3a"
                                border.width: parent.parent.currentTab === 1 ? 2 : 1
                                radius: 4
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                Image { source: "qrc:/Arm.png"; width: 24; height: 24; fillMode: Image.PreserveAspectFit; anchors.centerIn: parent }
                            }
                            MouseArea { anchors.fill: parent; onClicked: { parent.parent.currentTab = 1; mainPanelLoader.sourceComponent = armPanel } }
                        }
                        // Tab 3: 左手与右手
                        Item {
                            Layout.preferredWidth: 44
                            Layout.fillWidth: false
                            Layout.preferredHeight: 40
                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: parent.parent.currentTab === 2 ? "#00FFFF" : "#2a2a3a"
                                border.width: parent.parent.currentTab === 2 ? 2 : 1
                                radius: 4
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                Image { source: "qrc:/Hand.png"; width: 24; height: 24; fillMode: Image.PreserveAspectFit; anchors.centerIn: parent }
                            }
                            MouseArea { anchors.fill: parent; onClicked: { parent.parent.currentTab = 2; mainPanelLoader.sourceComponent = handPanel } }
                        }
                        // 弹性空间填满剩余区域
                        Item { Layout.fillWidth: true }
                    }
                    
                    // ========== 面板内容区（Loader 动态切换） ==========
                    Loader {
                        id: mainPanelLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        sourceComponent: headBodyPanel
                    }
                    
                    // ========== 错误提示 ==========
                    Text {
                        id: rangeError
                        text: ""
                        font.pixelSize: 14
                        color: "red"
                        visible: false
                        Layout.alignment: Qt.AlignHCenter
                    }
                    
                    // ========== 输入验证（在各组件发送按钮处检查，避免跨 Component 作用域访问） ==========
                    
                    // TCP 错误显示
                    Text {
                        id: errorText
                        text: ""
                        font.pixelSize: 14
                        color: "red"
                        visible: false
                        Layout.alignment: Qt.AlignHCenter
                    }
            }


            // 分隔线
            Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: "#00FFFF"
                    opacity: 0.3
            }
            // ========== 右侧区域 30%：Control Velocity ==========
            Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 180
                    Layout.minimumWidth: 180
                    radius: 10
                    border.color: "#2a2a3a"
                    border.width: 1
                    color: "#161720"
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: "Control Velocity"
                            color: "#00FFFF"
                            font.pixelSize: 14
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#00FFFF"; opacity: 0.2 }

                        RowLayout {
                            spacing: 6
                            Text { text: "Value:"; color: "#E0E0E0"; font.pixelSize: 12 }
                            TextField {
                                id: velocityInput
                                text: "1"
                                Layout.preferredWidth: 60
                                validator: IntValidator { bottom: 1; top: 100 }
                                color: "#E0E0E0"
                                background: Rectangle { radius: 4; color: "#1a1e2e"; border.color: velocityInput.acceptableInput ? "#00FFFF" : "#FF4444"; border.width: 1 }
                                onTextChanged: {
                                    if (acceptableInput && text !== "") {
                                        root.controlVelocity = parseInt(text)
                                        velocitySlider.value = root.controlVelocity
                                    }
                                }
                            }
                        }

                        Text {
                            text: "Drag to adjust step size"
                            color: "#666666"
                            font.pixelSize: 10
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Slider {
                            id: velocitySlider
                            Layout.fillWidth: true
                            from: 1; to: 100; stepSize: 1
                            value: root.controlVelocity
                            onMoved: {
                                root.controlVelocity = Math.round(value)
                                velocityInput.text = root.controlVelocity.toString()
                            }
                        }

                        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: "#00FFFF"; opacity: 0.2 }

                        Text {
                            text: "Step: ±" + root.controlVelocity
                            color: "#00FFFF"
                            font.pixelSize: 13
                            font.bold: true
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "All +/- buttons now change\nby this value per click"
                            color: "#555555"
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Item { Layout.fillHeight: true }
                    }
            }
    }
                // ========== 面板组件定义 ==========

                Component {
                    id: headBodyPanel
                    ColumnLayout {
                        spacing: 6
                        Layout.fillWidth: true
                        
                        // --- 头部控制 ---
                        Text { text: "头部控制 (Head)"; color: "#00FFFF"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        Grid {
                            columns: 5; spacing: 8
                            Layout.fillWidth: true
                            Text { text: "Head 1:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: head1; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { headValues[0] = text } background: Rectangle { border.color: head1.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_head1; text: root.headFeedback[0]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(head1.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); head1.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(head1.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); head1.text = v.toString() } } }
                            Text { text: "Head 2:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: head2; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { headValues[1] = text } background: Rectangle { border.color: head2.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_head2; text: root.headFeedback[1]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(head2.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); head2.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(head2.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); head2.text = v.toString() } } }
                        }
                        
                        // --- 躯干控制 ---
                        Text { text: "躯干控制 (Body)"; color: "#00FFFF"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        Grid {
                            columns: 5; spacing: 8
                            Layout.fillWidth: true
                            Text { text: "Body 1:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: body1; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { bodyValues[0] = text } background: Rectangle { border.color: body1.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_body1; text: root.bodyFeedback[0]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(body1.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); body1.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(body1.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); body1.text = v.toString() } } }
                            Text { text: "Body 2:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: body2; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { bodyValues[1] = text } background: Rectangle { border.color: body2.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_body2; text: root.bodyFeedback[1]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(body2.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); body2.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(body2.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); body2.text = v.toString() } } }
                            Text { text: "Body 3:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: body3; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { bodyValues[2] = text } background: Rectangle { border.color: body3.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_body3; text: root.bodyFeedback[2]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(body3.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); body3.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(body3.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); body3.text = v.toString() } } }
                            Text { text: "Body 4:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: body4; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { bodyValues[3] = text } background: Rectangle { border.color: body4.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_body4; text: root.bodyFeedback[3]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(body4.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); body4.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(body4.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); body4.text = v.toString() } } }
                        }
                        
                        // --- 按钮 ---
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Button {
                                Layout.fillWidth: true; text: "发送头部控制"
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"; border.color: "#00FFFF"; border.width: 1 }
                                contentItem: Text { text: parent.text; color: "#E0E0E0"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { if(!root.checkServoReady())return; tcpManager.sendMessage("1111:"+head1.text+","+head2.text) }
                            }
                            Button {
                                Layout.fillWidth: true; text: "发送躯干控制"
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"; border.color: "#00FFFF"; border.width: 1 }
                                contentItem: Text { text: parent.text; color: "#E0E0E0"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { if(!root.checkServoReady())return; tcpManager.sendMessage("2222:"+body1.text+","+body2.text+","+body3.text+","+body4.text) }
                            }
                            Button {
                                Layout.fillWidth: true; text: "发送全部"
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"; border.color: "#00FFFF"; border.width: 1 }
                                contentItem: Text { text: parent.text; color: "#E0E0E0"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { root.sendAllJoints() }
                            }
                        }
                    }
                }
                
                Component {
                    id: armPanel
                    ColumnLayout {
                        spacing: 6
                        Layout.fillWidth: true
                        
                        // --- 左臂控制 ---
                        Text { text: "左臂控制 (Left Arm)"; color: "#00FFFF"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        Grid {
                            columns: 5; spacing: 8
                            Layout.fillWidth: true
                            Text { text: "LA 1:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: la1; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { leftArmValues[0] = text } background: Rectangle { border.color: la1.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_la1; text: root.leftArmFeedback[0]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la1.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); la1.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la1.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); la1.text = v.toString() } } }
                            Text { text: "LA 2:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: la2; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { leftArmValues[1] = text } background: Rectangle { border.color: la2.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_la2; text: root.leftArmFeedback[1]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la2.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); la2.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la2.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); la2.text = v.toString() } } }
                            Text { text: "LA 3:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: la3; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { leftArmValues[2] = text } background: Rectangle { border.color: la3.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_la3; text: root.leftArmFeedback[2]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la3.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); la3.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la3.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); la3.text = v.toString() } } }
                            Text { text: "LA 4:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: la4; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { leftArmValues[3] = text } background: Rectangle { border.color: la4.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_la4; text: root.leftArmFeedback[3]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la4.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); la4.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la4.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); la4.text = v.toString() } } }
                            Text { text: "LA 5:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: la5; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { leftArmValues[4] = text } background: Rectangle { border.color: la5.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_la5; text: root.leftArmFeedback[4]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la5.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); la5.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la5.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); la5.text = v.toString() } } }
                            Text { text: "LA 6:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: la6; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { leftArmValues[5] = text } background: Rectangle { border.color: la6.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_la6; text: root.leftArmFeedback[5]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la6.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); la6.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la6.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); la6.text = v.toString() } } }
                            Text { text: "LA 7:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: la7; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { leftArmValues[6] = text } background: Rectangle { border.color: la7.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_la7; text: root.leftArmFeedback[6]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la7.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); la7.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(la7.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); la7.text = v.toString() } } }
                        }
                        
                        // --- 右臂控制 ---
                        Text { text: "右臂控制 (Right Arm)"; color: "#00FFFF"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        Grid {
                            columns: 5; spacing: 8
                            Layout.fillWidth: true
                            Text { text: "RA 1:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: ra1; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { rightArmValues[0] = text } background: Rectangle { border.color: ra1.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_ra1; text: root.rightArmFeedback[0]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra1.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); ra1.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra1.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); ra1.text = v.toString() } } }
                            Text { text: "RA 2:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: ra2; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { rightArmValues[1] = text } background: Rectangle { border.color: ra2.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_ra2; text: root.rightArmFeedback[1]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra2.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); ra2.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra2.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); ra2.text = v.toString() } } }
                            Text { text: "RA 3:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: ra3; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { rightArmValues[2] = text } background: Rectangle { border.color: ra3.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_ra3; text: root.rightArmFeedback[2]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra3.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); ra3.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra3.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); ra3.text = v.toString() } } }
                            Text { text: "RA 4:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: ra4; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { rightArmValues[3] = text } background: Rectangle { border.color: ra4.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_ra4; text: root.rightArmFeedback[3]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra4.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); ra4.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra4.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); ra4.text = v.toString() } } }
                            Text { text: "RA 5:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: ra5; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { rightArmValues[4] = text } background: Rectangle { border.color: ra5.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_ra5; text: root.rightArmFeedback[4]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra5.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); ra5.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra5.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); ra5.text = v.toString() } } }
                            Text { text: "RA 6:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: ra6; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { rightArmValues[5] = text } background: Rectangle { border.color: ra6.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_ra6; text: root.rightArmFeedback[5]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra6.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); ra6.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra6.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); ra6.text = v.toString() } } }
                            Text { text: "RA 7:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: ra7; text: "0"; width: 80; validator: DoubleValidator { bottom: -360; top: 360 } onTextChanged: { rightArmValues[6] = text } background: Rectangle { border.color: ra7.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_ra7; text: root.rightArmFeedback[6]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra7.text)||0; v = Math.min(360, Math.max(-360, v + root.controlVelocity)); ra7.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseFloat(ra7.text)||0; v = Math.min(360, Math.max(-360, v - root.controlVelocity)); ra7.text = v.toString() } } }
                        }
                        
                        // --- 按钮 ---
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Button {
                                Layout.fillWidth: true; text: "发送左臂控制"
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"; border.color: "#00FFFF"; border.width: 1 }
                                contentItem: Text { text: parent.text; color: "#E0E0E0"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { if(!root.checkServoReady())return; tcpManager.sendMessage("3333:"+la1.text+","+la2.text+","+la3.text+","+la4.text+","+la5.text+","+la6.text+","+la7.text) }
                            }
                            Button {
                                Layout.fillWidth: true; text: "发送右臂控制"
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"; border.color: "#00FFFF"; border.width: 1 }
                                contentItem: Text { text: parent.text; color: "#E0E0E0"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { if(!root.checkServoReady())return; tcpManager.sendMessage("4444:"+ra1.text+","+ra2.text+","+ra3.text+","+ra4.text+","+ra5.text+","+ra6.text+","+ra7.text) }
                            }
                            Button {
                                Layout.fillWidth: true; text: "发送全部"
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"; border.color: "#00FFFF"; border.width: 1 }
                                contentItem: Text { text: parent.text; color: "#E0E0E0"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { root.sendAllJoints() }
                            }
                        }
                    }
                }
                
                Component {
                    id: handPanel
                    ColumnLayout {
                        spacing: 6
                        Layout.fillWidth: true
                        
                        // --- 左手控制 ---
                        Text { text: "左手控制 (Left Hand)"; color: "#00FFFF"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        Grid {
                            columns: 5; spacing: 8
                            Layout.fillWidth: true
                            Text { text: "LH 1:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: lh1; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { leftHandValues[0] = text } background: Rectangle { border.color: lh1.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_lh1; text: root.leftHandFeedback[0]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh1.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); lh1.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh1.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); lh1.text = v.toString() } } }
                            Text { text: "LH 2:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: lh2; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { leftHandValues[1] = text } background: Rectangle { border.color: lh2.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_lh2; text: root.leftHandFeedback[1]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh2.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); lh2.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh2.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); lh2.text = v.toString() } } }
                            Text { text: "LH 3:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: lh3; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { leftHandValues[2] = text } background: Rectangle { border.color: lh3.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_lh3; text: root.leftHandFeedback[2]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh3.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); lh3.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh3.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); lh3.text = v.toString() } } }
                            Text { text: "LH 4:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: lh4; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { leftHandValues[3] = text } background: Rectangle { border.color: lh4.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_lh4; text: root.leftHandFeedback[3]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh4.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); lh4.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh4.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); lh4.text = v.toString() } } }
                            Text { text: "LH 5:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: lh5; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { leftHandValues[4] = text } background: Rectangle { border.color: lh5.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_lh5; text: root.leftHandFeedback[4]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh5.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); lh5.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh5.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); lh5.text = v.toString() } } }
                            Text { text: "LH 6:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: lh6; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { leftHandValues[5] = text } background: Rectangle { border.color: lh6.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_lh6; text: root.leftHandFeedback[5]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh6.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); lh6.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(lh6.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); lh6.text = v.toString() } } }
                        }
                        
                        // --- 右手控制 ---
                        Text { text: "右手控制 (Right Hand)"; color: "#00FFFF"; font.pixelSize: 13; font.bold: true; Layout.alignment: Qt.AlignHCenter }
                        Grid {
                            columns: 5; spacing: 8
                            Layout.fillWidth: true
                            Text { text: "RH 1:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: rh1; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { rightHandValues[0] = text } background: Rectangle { border.color: rh1.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_rh1; text: root.rightHandFeedback[0]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh1.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); rh1.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh1.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); rh1.text = v.toString() } } }
                            Text { text: "RH 2:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: rh2; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { rightHandValues[1] = text } background: Rectangle { border.color: rh2.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_rh2; text: root.rightHandFeedback[1]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh2.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); rh2.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh2.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); rh2.text = v.toString() } } }
                            Text { text: "RH 3:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: rh3; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { rightHandValues[2] = text } background: Rectangle { border.color: rh3.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_rh3; text: root.rightHandFeedback[2]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh3.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); rh3.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh3.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); rh3.text = v.toString() } } }
                            Text { text: "RH 4:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: rh4; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { rightHandValues[3] = text } background: Rectangle { border.color: rh4.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_rh4; text: root.rightHandFeedback[3]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh4.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); rh4.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh4.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); rh4.text = v.toString() } } }
                            Text { text: "RH 5:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: rh5; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { rightHandValues[4] = text } background: Rectangle { border.color: rh5.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_rh5; text: root.rightHandFeedback[4]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh5.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); rh5.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh5.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); rh5.text = v.toString() } } }
                            Text { text: "RH 6:"; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                            TextField { id: rh6; text: "0"; width: 80; validator: IntValidator { bottom: 0; top: 100 } onTextChanged: { rightHandValues[5] = text } background: Rectangle { border.color: rh6.acceptableInput ? "#333" : "#FF4444"; border.width: 2 } }
                            Text { id: fb_rh6; text: root.rightHandFeedback[5]; verticalAlignment: Text.AlignVCenter; color: "#00FFFF" }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/plus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh6.text)||0; v = Math.min(100, Math.max(0, v + root.controlVelocity)); rh6.text = v.toString() } } }
                            Rectangle { width: 22; height: 22; radius: 4; color: "#1a1e2e"; border.color: "#00FFFF"; border.width: 1; opacity: 0.5; Image { anchors.centerIn: parent; source: "qrc:/minus.png"; width: 11; height: 11; fillMode: Image.PreserveAspectFit } MouseArea { anchors.fill: parent; onClicked: { var v = parseInt(rh6.text)||0; v = Math.min(100, Math.max(0, v - root.controlVelocity)); rh6.text = v.toString() } } }
                        }
                        
                        // --- 按钮 ---
                        RowLayout {
                            Layout.fillWidth: true; spacing: 8
                            Button {
                                Layout.fillWidth: true; text: "发送左手控制"
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"; border.color: "#00FFFF"; border.width: 1 }
                                contentItem: Text { text: parent.text; color: "#E0E0E0"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { if(!root.checkServoReady())return; tcpManager.sendMessage("5555:"+lh1.text+","+lh2.text+","+lh3.text+","+lh4.text+","+lh5.text+","+lh6.text) }
                            }
                            Button {
                                Layout.fillWidth: true; text: "发送右手控制"
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"; border.color: "#00FFFF"; border.width: 1 }
                                contentItem: Text { text: parent.text; color: "#E0E0E0"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { if(!root.checkServoReady())return; tcpManager.sendMessage("6666:"+rh1.text+","+rh2.text+","+rh3.text+","+rh4.text+","+rh5.text+","+rh6.text) }
                            }
                            Button {
                                Layout.fillWidth: true; text: "发送全部"
                                background: Rectangle { radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"; border.color: "#00FFFF"; border.width: 1 }
                                contentItem: Text { text: parent.text; color: "#E0E0E0"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                onClicked: { root.sendAllJoints() }
                            }
                        }
                    }
                }
}
    Connections {        target: tcpManager
        function onHeadDataReceived(values) {
            if (!values || values.length !== 2) { errorText.text = "头部数据格式错误"; errorText.visible = true; return }
            errorText.visible = false
            headFeedback = [values[0], values[1]]
        }
        function onBodyDataReceived(values) {
            if (!values || values.length !== 4) { errorText.text = "躯干数据格式错误"; errorText.visible = true; return }
            errorText.visible = false
            bodyFeedback = [values[0], values[1], values[2], values[3]]
        }
        function onLeftArmDataReceived(values) {
            if (!values || values.length !== 7) { errorText.text = "左臂数据格式错误"; errorText.visible = true; return }
            errorText.visible = false
            leftArmFeedback = [values[0], values[1], values[2], values[3], values[4], values[5], values[6]]
        }
        function onRightArmDataReceived(values) {
            if (!values || values.length !== 7) { errorText.text = "右臂数据格式错误"; errorText.visible = true; return }
            errorText.visible = false
            rightArmFeedback = [values[0], values[1], values[2], values[3], values[4], values[5], values[6]]
        }
        function onLeftHandDataReceived(values) {
            if (!values || values.length !== 6) { errorText.text = "左手数据格式错误"; errorText.visible = true; return }
            errorText.visible = false
            leftHandFeedback = [values[0], values[1], values[2], values[3], values[4], values[5]]
        }
        function onRightHandDataReceived(values) {
            if (!values || values.length !== 6) { errorText.text = "右手数据格式错误"; errorText.visible = true; return }
            errorText.visible = false
            rightHandFeedback = [values[0], values[1], values[2], values[3], values[4], values[5]]
        }
        function onErrorMessage(msg) {
            errorText.text = msg; errorText.visible = true
        }
        function onConnectionStatusChanged(status) {
            statusText.text = status; errorText.visible = false
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
                  spacing: 20
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
                   property string activeMode: ""        // "" = 隐藏, "handing" = 手绘航点, "math" = 录制航点, "points" = 航点列表
                   property real pendingWorldX: 0
                   property real pendingWorldY: 0
                   property real pendingQz: 0
                   property real pendingQw: 0
                   property bool hasPendingPoint: false
                   property int selectedSavedIndex: -1
                   property ListModel savedPoints: ListModel {}
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

                   // 外层布局：地图全屏 + 左侧面板浮动叠加
                   Item {
                       anchors.top: parent.top
                       anchors.left: parent.left
                       anchors.right: parent.right
                       anchors.bottom: parent.bottom
                       anchors.topMargin: 10
                       anchors.leftMargin: 10
                       anchors.rightMargin: 10
                       anchors.bottomMargin: 10

                        // ========== 左侧浮动控制区（参照 page5） ==========
                        Rectangle {
                                id: leftControl
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: imagePage.activeMode === "" ? 52 : 180
                                color: "#1a1e2e"
                                radius: 10
                                border.color: "#2a2a3a"
                                border.width: 1
                                z: 100

                                Behavior on width {
                                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                                }

                                ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 4
                                        spacing: 6

                                // ---- 图标按钮（垂直单列，参照 page5） ----
                                Button {
                                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                                        Layout.alignment: Qt.AlignHCenter
                                        background: Rectangle {
                                            radius: 8; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"
                                            border.color: "#00FFFF"; border.width: 1
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        contentItem: Image {
                                            source: "qrc:/Mapchoose.png"; width: 24; height: 24
                                            fillMode: Image.PreserveAspectFit; anchors.centerIn: parent
                                        }
                                        onClicked: openFileDialog.open()
                                }
                                Button {
                                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                                        Layout.alignment: Qt.AlignHCenter
                                        background: Rectangle {
                                            radius: 8; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"
                                            border.color: "#00FFFF"; border.width: 1
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        contentItem: Image {
                                            source: "qrc:/server.png"; width: 24; height: 24
                                            fillMode: Image.PreserveAspectFit; anchors.centerIn: parent
                                        }
                                        onClicked: sshManager.startDownload()
                                }
                                Button {
                                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                                        Layout.alignment: Qt.AlignHCenter
                                        background: Rectangle {
                                            radius: 8
                                            color: imagePage.activeMode === "points" ? "#1A00FFFF" : (parent.hovered ? "#2a2a3a" : "#1a1e2e")
                                            border.color: imagePage.activeMode === "points" ? "#00FFFF" : "#2a2a3a"
                                            border.width: imagePage.activeMode === "points" ? 2 : 1
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        contentItem: Image {
                                            source: "qrc:/navigator.png"; width: 24; height: 24
                                            fillMode: Image.PreserveAspectFit; anchors.centerIn: parent
                                        }
                                        onClicked: { imagePage.activeMode = imagePage.activeMode === "points" ? "" : "points" }
                                }
                                Button {
                                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                                        Layout.alignment: Qt.AlignHCenter
                                        background: Rectangle {
                                            radius: 8
                                            color: imagePage.activeMode === "handing" ? "#1A00FFFF" : (parent.hovered ? "#2a2a3a" : "#1a1e2e")
                                            border.color: imagePage.activeMode === "handing" ? "#00FFFF" : "#2a2a3a"
                                            border.width: imagePage.activeMode === "handing" ? 2 : 1
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        contentItem: Image {
                                            source: "qrc:/Handing.png"; width: 24; height: 24
                                            fillMode: Image.PreserveAspectFit; anchors.centerIn: parent
                                        }
                                        onClicked: { imagePage.activeMode = imagePage.activeMode === "handing" ? "" : "handing" }
                                }
                                Button {
                                        Layout.preferredWidth: 40; Layout.preferredHeight: 40
                                        Layout.alignment: Qt.AlignHCenter
                                        background: Rectangle {
                                            radius: 8
                                            color: imagePage.activeMode === "math" ? "#1A00FFFF" : (parent.hovered ? "#2a2a3a" : "#1a1e2e")
                                            border.color: imagePage.activeMode === "math" ? "#00FFFF" : "#2a2a3a"
                                            border.width: imagePage.activeMode === "math" ? 2 : 1
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }
                                        contentItem: Image {
                                            source: "qrc:/Math.png"; width: 24; height: 24
                                            fillMode: Image.PreserveAspectFit; anchors.centerIn: parent
                                        }
                                        onClicked: { imagePage.activeMode = imagePage.activeMode === "math" ? "" : "math" }
                                }
                                
                                // ========== 手绘航点面板 ==========
                                ColumnLayout {
                                        visible: imagePage.activeMode === "handing"
                                        spacing: 6
                                        Layout.fillWidth: true
                                        
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "手绘航点"; color: "#00FFFF"; font.pixelSize: 14; font.bold: true
                                        }
                                        Rectangle { width: parent.width; height: 1; color: "#2a2a3a" }
                                        
                                        // 实时坐标显示
                                        Column {
                                                spacing: 4
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                Text { text: "World X: " + (imagePage.hasPendingPoint ? imagePage.pendingWorldX.toFixed(3) : "--"); color: "#E0E0E0"; font.pixelSize: 11 }
                                                Text { text: "World Y: " + (imagePage.hasPendingPoint ? imagePage.pendingWorldY.toFixed(3) : "--"); color: "#E0E0E0"; font.pixelSize: 11 }
                                                Text { text: "qz: " + (imagePage.hasPendingPoint ? imagePage.pendingQz.toFixed(4) : "--"); color: "#E0E0E0"; font.pixelSize: 11 }
                                                Text { text: "qw: " + (imagePage.hasPendingPoint ? imagePage.pendingQw.toFixed(4) : "--"); color: "#E0E0E0"; font.pixelSize: 11 }
                                        }
                                        
                                        // 保存并上传按钮
                                        Button {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "保存并上传"
                                                enabled: imagePage.hasPendingPoint
                                                background: Rectangle {
                                                    radius: 6; color: parent.enabled ? (parent.hovered ? "#2a2a3a" : "#1a1e2e") : "#151720"
                                                    border.color: parent.enabled ? "#00FFFF" : "#333333"; border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }
                                                contentItem: Text {
                                                    text: parent.text; color: parent.enabled ? "#E0E0E0" : "#555555"; font.pixelSize: 12
                                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                                }
                                                onClicked: {
                                                    if (!root.checkServoReady()) return;
                                                    if (!imagePage.hasPendingPoint) return;
                                                    var msg = "1007:" + imagePage.pendingWorldX.toFixed(3) + "," +
                                                              imagePage.pendingWorldY.toFixed(3) + "," +
                                                              imagePage.pendingQz.toFixed(4) + "," +
                                                              imagePage.pendingQw.toFixed(4);
                                                    tcpManager.sendMessage(msg);
                                                    // 计算显示坐标并持久化到列表
                                                    var ppx = (imagePage.pendingWorldX - mapOriginX) / mapResolution;
                                                    var ppy = imageItem.sourceSize.height - (imagePage.pendingWorldY - mapOriginY) / mapResolution;
                                                    var psf = imageItem.paintedWidth / imageItem.sourceSize.width;
                                                    var ppdX = (imageItem.width - imageItem.paintedWidth) / 2;
                                                    var ppdY = (imageItem.height - imageItem.paintedHeight) / 2;
                                                    var dspX = ppdX + ppx * psf;
                                                    var dspY = ppdY + ppy * psf;
                                                    imagePage.savedPoints.append({
                                                        name: "点" + (imagePage.savedPoints.count + 1),
                                                        worldX: imagePage.pendingWorldX,
                                                        worldY: imagePage.pendingWorldY,
                                                        qz: imagePage.pendingQz,
                                                        qw: imagePage.pendingQw,
                                                        displayX: dspX,
                                                        displayY: dspY,
                                                        angleDeg: imagePage.currentAngle
                                                    });
                                                    imagePage.hasPendingPoint = false;
                                                }
                                        }
                                }

                                // ========== 航点列表面板 ==========
                                ColumnLayout {
                                        visible: imagePage.activeMode === "points"
                                        spacing: 6
                                        Layout.fillWidth: true

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "航点列表"; color: "#00FFFF"; font.pixelSize: 14; font.bold: true
                                        }
                                        Rectangle { width: parent.width; height: 1; color: "#2a2a3a" }

                                        // 删除按钮行
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 8
                                            Button {
                                                width: 36; height: 36
                                                enabled: imagePage.selectedSavedIndex >= 0
                                                background: Rectangle {
                                                    radius: 6; color: parent.enabled ? (parent.hovered ? "#3a2020" : "#2a1a1a") : "#151720"
                                                    border.color: parent.enabled ? "#FF4444" : "#333333"; border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }
                                                contentItem: Image {
                                                    source: "qrc:/TrashCan.png"; width: 20; height: 20
                                                    fillMode: Image.PreserveAspectFit; anchors.centerIn: parent
                                                }
                                                onClicked: {
                                                    if (imagePage.selectedSavedIndex >= 0 && imagePage.selectedSavedIndex < imagePage.savedPoints.count) {
                                                        imagePage.savedPoints.remove(imagePage.selectedSavedIndex)
                                                        // 重新编号
                                                        for (var i = 0; i < imagePage.savedPoints.count; i++) {
                                                            imagePage.savedPoints.setProperty(i, "name", "点" + (i + 1))
                                                        }
                                                        imagePage.selectedSavedIndex = -1
                                                    }
                                                }
                                            }
                                        }

                                        ListView {
                                            id: savedPointsList
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            clip: true
                                            model: imagePage.savedPoints
                                            delegate: Rectangle {
                                                width: savedPointsList.width
                                                height: 40
                                                color: imagePage.selectedSavedIndex === index ? "#1A00FFFF" : "transparent"
                                                radius: 3
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                                Column {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.leftMargin: 8
                                                    Text {
                                                        text: name
                                                        color: imagePage.selectedSavedIndex === index ? "#00FFFF" : "#E0E0E0"
                                                        font.pixelSize: 12
                                                        font.bold: imagePage.selectedSavedIndex === index
                                                    }
                                                    Text {
                                                        text: "坐标: " + worldX.toFixed(2) + ", " + worldY.toFixed(2) + ", " + qz.toFixed(3) + ", " + qw.toFixed(3)
                                                        color: imagePage.selectedSavedIndex === index ? "#FFAA00" : "#888888"
                                                        font.pixelSize: 10
                                                    }
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    onClicked: {
                                                        imagePage.selectedSavedIndex = index
                                                    }
                                                }
                                            }
                                        }
                                }

                                // ========== 录制航点面板 ==========
                                ColumnLayout {
                                        visible: imagePage.activeMode === "math"
                                        spacing: 6
                                        Layout.fillWidth: true
                                        
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "录制航点"; color: "#00FFFF"; font.pixelSize: 14; font.bold: true
                                        }
                                        Rectangle { width: parent.width; height: 1; color: "#2a2a3a" }
                                        
                                        // X 输入框
                                        Row {
                                                spacing: 5
                                                Text { text: "X:"; width: 30; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                                                TextField {
                                                    id: inputX; text: "0"; width: 130
                                                    validator: DoubleValidator { bottom: -3.8; top: 13.6 }
                                                    background: Rectangle { border.color: inputX.acceptableInput ? "white" : "red"; border.width: 2 }
                                                    onTextChanged: { imagePage.checkAndUpdateMarker(); }
                                                }
                                        }
                                        
                                        // Y 输入框
                                        Row {
                                                spacing: 5
                                                Text { text: "Y:"; width: 30; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                                                TextField {
                                                    id: inputY; text: "0"; width: 130
                                                    validator: DoubleValidator { bottom: -5.55; top: 7.35 }
                                                    background: Rectangle { border.color: inputY.acceptableInput ? "white" : "red"; border.width: 2 }
                                                    onTextChanged: { imagePage.checkAndUpdateMarker(); }
                                                }
                                        }
                                        
                                        // qz 输入框
                                        Row {
                                                spacing: 5
                                                Text { text: "qz:"; width: 30; verticalAlignment: Text.AlignVCenter; color: "#E0E0E0" }
                                                TextField {
                                                    id: inputQz; text: "0"; width: 130
                                                    validator: DoubleValidator { bottom: -1; top: 1 }
                                                    background: Rectangle { border.color: inputQz.acceptableInput ? "white" : "red"; border.width: 2 }
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
                                                    validator: DoubleValidator { bottom: -1; top: 1 }
                                                    background: Rectangle { border.color: inputQw.acceptableInput ? "white" : "red"; border.width: 2 }
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
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                text: "发送"
                                                width: 160
                                                background: Rectangle {
                                                    radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"
                                                    border.color: "#00FFFF"; border.width: 1
                                                    Behavior on color { ColorAnimation { duration: 150 } }
                                                }
                                                contentItem: Text {
                                                    text: parent.text; color: "#E0E0E0"; font.pixelSize: 12
                                                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                                                }
                                                onClicked: {
                                                    if (!root.checkServoReady()) return;
                                                    if (!inputX.acceptableInput || !inputY.acceptableInput ||
                                                        !inputQz.acceptableInput || !inputQw.acceptableInput) { return; }
                                                    var worldX = parseFloat(inputX.text);
                                                    var worldY = parseFloat(inputY.text);
                                                    var qz = parseFloat(inputQz.text);
                                                    var qw = parseFloat(inputQw.text);
                                                    var messageLocation = worldX.toFixed(3) + "," +
                                                                        worldY.toFixed(3) + "," +
                                                                        qz.toFixed(4) + "," + qw.toFixed(4);
                                                    tcpManager.sendMessage("1007:" + messageLocation);
                                                    // 持久化到地图和列表（与手绘航点-保存并上传逻辑完全对齐）
                                                    imagePage.savedPoints.append({
                                                        name: "点" + (imagePage.savedPoints.count + 1),
                                                        worldX: worldX,
                                                        worldY: worldY,
                                                        qz: qz,
                                                        qw: qw,
                                                        displayX: marker.x + marker.width / 2,
                                                        displayY: marker.y + marker.height / 2,
                                                        angleDeg: imagePage.currentAngle
                                                    });
                                                    // 持久化后标记点保持可见（已在 updateMarker 中设置 marker.visible = true）
                                                }
                                        }
                                }
                                } // 关闭 inner ColumnLayout
                        } // 关闭 leftControl Rectangle

                       // 地图图片（参照 page5，Image 直接在布局内）
                       Image {
                           id: imageItem
                           anchors.fill: parent
                           fillMode: Image.PreserveAspectFit
                           z: 0
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
                                  imagePage.hasPendingPoint = false;
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
                                         imagePage.hasPendingPoint = false;
                                         return;
                                      }

                                      // 计算并存储世界坐标（复用 onReleased 中的公式）
                                      var lpX = startPos.x - paintedX;
                                      var lpY = startPos.y - paintedY;
                                      var opX = lpX / scaleFactor;
                                      var opY = lpY / scaleFactor;
                                      imagePage.pendingWorldX = mapOriginX + (opX * mapResolution);
                                      imagePage.pendingWorldY = mapOriginY + ((imageItem.sourceSize.height - opY) * mapResolution);
                                      imagePage.pendingQz = 0;
                                      imagePage.pendingQw = 1;
                                      imagePage.hasPendingPoint = true;

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
                                  // 实时更新四元数
                                  imagePage.pendingQz = Math.sin(rad / 2.0);
                                  imagePage.pendingQw = Math.cos(rad / 2.0);
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
                                  // 存入待上传坐标，上传逻辑已移至"保存并上传"按钮
                                  imagePage.pendingWorldX = worldX;
                                  imagePage.pendingWorldY = worldY;
                                  imagePage.pendingQz = qz;
                                  imagePage.pendingQw = qw;
                                  imagePage.hasPendingPoint = true;
                                  if (!isValidTarget) {
                                          imagePage.hasPendingPoint = false;
                                          return;
                                      }
                                  }
                                   }
                           asynchronous: true  // 异步加载，避免大图卡顿
                       }

                       // marker 和 arrow（浮在地图上方，z 高于 Image）
                       Rectangle {
                           id: marker
                           width: 10; height: 10
                           radius: 5
                           color: "black"
                           visible: false
                           z: 10
                       }
                       Image{
                           id:arrow
                           width: 40
                           height: 40
                           source:"qrc:/arrow.png"
                           visible: false
                           z: 20
                           transformOrigin: Item.Left
                           rotation: imagePage.currentAngle
                       }

                       // 已保存航点的持久化标记（Repeater，浮在地图上方）
                       Repeater {
                           model: imagePage.savedPoints
                           delegate: Item {
                               z: 8
                               // 标记点
                               Rectangle {
                                   x: displayX - 5; y: displayY - 5
                                   width: 10; height: 10; radius: 5
                                   color: imagePage.selectedSavedIndex === index ? "#FF4444" : "#00FFFF"
                                   visible: true
                                   z: 5
                               }
                               // 选中高亮外圈
                               Rectangle {
                                   x: displayX - 8; y: displayY - 8
                                   width: 16; height: 16; radius: 8
                                   color: "transparent"
                                   border.color: "#FF4444"
                                   border.width: 2
                                   visible: imagePage.selectedSavedIndex === index
                                   z: 6
                               }
                               // 方向箭头
                               Image {
                                   x: displayX; y: displayY - 20
                                   width: 40; height: 40
                                   source: "qrc:/arrow.png"
                                   visible: true
                                   z: 4
                                   transformOrigin: Item.Left
                                   rotation: angleDeg
                               }
                           }
                       }
                   } // 关闭外层 Item

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
    Rectangle {
        id: page5
        color: "#1a1b26"
        property string loadedImagePath: ""
        property var currentPoints: []
        property int wallCount: 0
        property string activeList: ""  // "" = 隐藏, "markers" = 标记点列表, "walls" = 墙体列表
        property int currentMarkerIndex: -1       // 当前选中的标记点索引
        property int currentWallIndex: -1         // 当前选中的墙体索引

        // ---- 中文数字转换 ----
        function toChineseNum(n) {
            var nums = ["一","二","三","四","五","六","七","八","九","十",
                        "十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]
            return n < nums.length ? nums[n] : String(n + 1)
        }

        // ---- 刷新列表 ----
        function refreshMarkerList() {
            markerListModel.clear()
            var count = mapProvider.getCurrentPointCount()
            var srcH = imageItem_1.sourceSize.height
            for (var i = 0; i < count; i++) {
                // 获取 C++ 中存储的源图像素坐标
                var px = mapProvider.getCurrentWallPointX(i)
                var py = mapProvider.getCurrentWallPointY(i)
                // 复用 imagePage 坐标计算逻辑（第1117-1125行）：
                // originPixelX/Y 即 mouseToPixel 的输出 → 直接套用 world 公式
                var worldX = mapOriginX + (px * mapResolution)
                var worldY = mapOriginY + ((srcH - py) * mapResolution)
                var coordStr = "(" + worldX.toFixed(3) + ", " + worldY.toFixed(3) + ")"
                markerListModel.append({ name: "标记点" + (i + 1), coord: coordStr })
            }
        }
        function refreshWallList() {
            wallListModel.clear()
            var count = mapProvider.getWallCount()
            for (var i = 0; i < count; i++) {
                wallListModel.append({ name: "墙体" + toChineseNum(i) })
            }
        }

        // ---- 列表模型 ----
        ListModel { id: markerListModel }
        ListModel { id: wallListModel }

        // ---- 主布局 ----
        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            // ========== 左侧导航侧边栏 ==========
            Rectangle {
                id: sidebar
                Layout.preferredWidth: page5.activeList === "" ? 48 : 210
                Layout.fillHeight: true
                color: "#1a1e2e"
                radius: 10
                border.color: "#2a2a3a"
                border.width: 1

                Behavior on Layout.preferredWidth {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 6

                    // 标记点按钮 (navigator.png)
                    Button {
                        id: markerBtn
                        width: 40; height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        background: Rectangle {
                            radius: 8
                            color: page5.activeList === "markers" ? "#1A00FFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        contentItem: Image {
                            source: "qrc:/navigator.png"
                            width: 24; height: 24
                            fillMode: Image.PreserveAspectFit
                            anchors.centerIn: parent
                        }
                        onClicked: {
                            if (page5.activeList === "markers") {
                                page5.activeList = ""
                            } else {
                                page5.activeList = "markers"
                                page5.refreshMarkerList()
                            }
                        }
                    }

                    // 墙体按钮 (wall.png)
                    Button {
                        id: wallBtn
                        width: 40; height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        background: Rectangle {
                            radius: 8
                            color: page5.activeList === "walls" ? "#1A00FFFF" : "transparent"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        contentItem: Image {
                            source: "qrc:/wall.png"
                            width: 24; height: 24
                            fillMode: Image.PreserveAspectFit
                            anchors.centerIn: parent
                        }
                        onClicked: {
                            if (page5.activeList === "walls") {
                                page5.activeList = ""
                            } else {
                                page5.activeList = "walls"
                                page5.refreshWallList()
                            }
                        }
                    }

                    // 删除按钮 (TrashCan.png)
                    Button {
                        id: deleteBtn
                        width: 40; height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        background: Rectangle {
                            radius: 8
                            color: "transparent"
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                        contentItem: Image {
                            source: "qrc:/TrashCan.png"
                            width: 24; height: 24
                            fillMode: Image.PreserveAspectFit
                            anchors.centerIn: parent
                        }
                        onClicked: {
                            if (page5.activeList === "markers") {
                                if (page5.currentMarkerIndex >= 0) {
                                    mapProvider.deleteCurrentWallPoint(page5.currentMarkerIndex)
                                    // 同步移除 QML 中的跟踪数据
                                    if (page5.currentMarkerIndex < page5.currentPoints.length) {
                                        var arr = page5.currentPoints
                                        arr.splice(page5.currentMarkerIndex, 1)
                                        page5.currentPoints = arr
                                    }
                                    page5.currentMarkerIndex = -1
                                    page5.refreshImage()
                                }
                            } else if (page5.activeList === "walls") {
                                if (page5.currentWallIndex >= 0) {
                                    mapProvider.deleteWall(page5.currentWallIndex)
                                    page5.wallCount = mapProvider.getWallCount()
                                    page5.currentWallIndex = -1
                                    page5.refreshImage()
                                }
                            }
                        }
                    }

                    // 列表面板
                    Rectangle {
                        id: listPanel
                        visible: page5.activeList !== ""
                        width: parent.width - 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: parent.height - 100
                        color: "transparent"

                        Column {
                            anchors.fill: parent
                            spacing: 6
                            anchors.topMargin: 8

                            // 列表标题
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: page5.activeList === "markers" ? "标记点列表" : "墙体列表"
                                color: "#00FFFF"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Rectangle {
                                width: parent.width
                                height: 1
                                color: "#2a2a3a"
                            }

                            // 标记点列表
                            ListView {
                                id: markerListView
                                visible: page5.activeList === "markers"
                                width: parent.width
                                height: parent.height - 30
                                clip: true
                                model: markerListModel
                                delegate: Rectangle {
                                    width: markerListView.width
                                    height: 44
                                    color: page5.currentMarkerIndex === index ? "#1A00FFFF" : "transparent"
                                    radius: 3
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 6
                                        spacing: 4
                                        Text {
                                            text: name
                                            color: page5.currentMarkerIndex === index ? "#00FFFF" : "#E0E0E0"
                                            font.pixelSize: 12
                                            font.bold: page5.currentMarkerIndex === index
                                            verticalAlignment: Text.AlignVCenter
                                            height: parent.height
                                            width: Math.min(implicitWidth + 6, parent.width * 0.38)
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: coord
                                            color: page5.currentMarkerIndex === index ? "#FFAA00" : "#888888"
                                            font.pixelSize: 11
                                            verticalAlignment: Text.AlignVCenter
                                            height: parent.height
                                            Layout.fillWidth: true - parent.children[0].width - 8
                                            elide: Text.ElideRight
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            page5.currentMarkerIndex = index
                                            mapProvider.selectCurrentWallPoint(index)
                                            page5.refreshImage()
                                        }
                                    }
                                }
                            }

                            // 墙体列表
                            ListView {
                                id: wallListView
                                visible: page5.activeList === "walls"
                                width: parent.width
                                height: parent.height - 30
                                clip: true
                                model: wallListModel
                                delegate: Rectangle {
                                    width: wallListView.width
                                    height: 30
                                    color: page5.currentWallIndex === index ? "#1A00FFFF" : "transparent"
                                    radius: 3
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Text {
                                        text: name
                                        color: page5.currentWallIndex === index ? "#00FFFF" : "#E0E0E0"
                                        font.pixelSize: 12
                                        font.bold: page5.currentWallIndex === index
                                        leftPadding: 12
                                        verticalAlignment: Text.AlignVCenter
                                        anchors.fill: parent
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            page5.currentWallIndex = index
                                            mapProvider.selectWall(index)
                                            page5.refreshImage()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ========== 右侧内容区域 ==========
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                // ---- 顶部工具栏 ----
                Row {
                    id: wallToolbar
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 8
                    Button {
                        text: "加载图片"
                        background: Rectangle {
                            radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"
                            border.color: "#00FFFF"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        contentItem: Text {
                            text: parent.text; color: "#E0E0E0"; font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: page5FileDialog.open()
                    }
                    Button {
                        text: "完成墙体"
                        enabled: page5.currentPoints.length >= 2
                        background: Rectangle {
                            radius: 6; color: parent.enabled ? (parent.hovered ? "#2a2a3a" : "#1a1e2e") : "#151720"
                            border.color: parent.enabled ? "#00FFFF" : "#333333"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        contentItem: Text {
                            text: parent.text; color: parent.enabled ? "#E0E0E0" : "#555555"; font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            mapProvider.finishCurrentWall()
                            page5.currentPoints = []
                            page5.wallCount = page5.wallCount + 1
                            page5.refreshImage()
                            page5.refreshMarkerList()
                            page5.refreshWallList()
                        }
                    }
                    Button {
                        text: "撤销"
                        enabled: page5.currentPoints.length > 0
                        background: Rectangle {
                            radius: 6; color: parent.enabled ? (parent.hovered ? "#2a2a3a" : "#1a1e2e") : "#151720"
                            border.color: parent.enabled ? "#00FFFF" : "#333333"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        contentItem: Text {
                            text: parent.text; color: parent.enabled ? "#E0E0E0" : "#555555"; font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            mapProvider.clearCurrentWall()
                            page5.currentPoints = []
                            page5.refreshImage()
                            page5.refreshMarkerList()
                        }
                    }
                    Button {
                        text: "清空全部"
                        background: Rectangle {
                            radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"
                            border.color: "#00FFFF"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        contentItem: Text {
                            text: parent.text; color: "#E0E0E0"; font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            mapProvider.clearAllWalls()
                            page5.currentPoints = []
                            page5.wallCount = 0
                            page5.refreshImage()
                            page5.refreshMarkerList()
                            page5.refreshWallList()
                        }
                    }
                    Button {
                        text: "保存地图"
                        background: Rectangle {
                            radius: 6; color: parent.hovered ? "#2a2a3a" : "#1a1e2e"
                            border.color: "#00FFFF"; border.width: 1
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                        contentItem: Text {
                            text: parent.text; color: "#E0E0E0"; font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: page5SaveDialog.open()
                    }
                }

                // ---- 地图图片区域 ----
                Image {
                    id: imageItem_1
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    fillMode: Image.PreserveAspectFit

                    function mouseToPixel(mouseX, mouseY) {
                        var offsetX = (imageItem_1.width - imageItem_1.paintedWidth) / 2
                        var offsetY = (imageItem_1.height - imageItem_1.paintedHeight) / 2
                        var scale = imageItem_1.sourceSize.width / imageItem_1.paintedWidth
                        if (scale <= 0) scale = 1
                        return { x: (mouseX - offsetX) * scale, y: (mouseY - offsetY) * scale }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: imageItem_1.source !== ""
                        onClicked: function(mouse) {
                            // 边界检测：判断点击是否在图片有效范围内
                            var paintedX = (imageItem_1.width - imageItem_1.paintedWidth) / 2
                            var paintedY = (imageItem_1.height - imageItem_1.paintedHeight) / 2
                            if (mouse.x < paintedX || mouse.x > paintedX + imageItem_1.paintedWidth ||
                                mouse.y < paintedY || mouse.y > paintedY + imageItem_1.paintedHeight) {
                                console.log("点击位置在地图区域外，已忽略")
                                return
                            }

                            var pos = imageItem_1.mouseToPixel(mouse.x, mouse.y)

                            // 边界检测：判断坐标是否在源图片有效范围内
                            if (pos.x < 0 || pos.x > imageItem_1.sourceSize.width ||
                                pos.y < 0 || pos.y > imageItem_1.sourceSize.height) {
                                console.log("坐标超出地图有效范围，已忽略")
                                return
                            }

                            mapProvider.addWallPoint(pos.x, pos.y)
                            page5.currentPoints = page5.currentPoints.concat([{x: pos.x, y: pos.y}])
                            page5.refreshImage()
                            page5.refreshMarkerList()
                        }
                    }
                }
                // ---- 底部信息栏 ----
                Rectangle {
                    id: infoBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    color: "#1a1e2e"
                    radius: 6
                    Text {
                        anchors.centerIn: parent
                        text: "当前墙点数: " + page5.currentPoints.length + "  |  已完成墙体: " + page5.wallCount
                        color: "#E0E0E0"
                        font.pixelSize: 13
                    }
                }
            }
        }

        // ---- 图片刷新 ----
        function refreshImage() {
            imageItem_1.source = ""
            imageItem_1.source = "image://mapProvider?" + Math.random()
        }

        // ---- C++ 信号连接：实时同步数据到侧边栏列表 ----
        Connections {
            target: mapProvider
            function onWallsChanged() {
                page5.refreshMarkerList()
                page5.refreshWallList()
            }
            function onImageChanged() {
                page5.refreshMarkerList()
                page5.refreshWallList()
            }
        }

        // ---- 文件选择对话框 ----
        FileDialog {
            id: page5FileDialog
            title: "选择图片"
            nameFilters: ["PNG 图片 (*.png)", "所有文件 (*)"]
            onAccepted: {
                var filePath = page5FileDialog.selectedFile.toString()
                if (filePath.startsWith("file:///")) {
                    filePath = filePath.substring(8)
                }
                page5.loadedImagePath = filePath
                mapProvider.loadFromPng(filePath)
                page5.refreshImage()
                page5.refreshMarkerList()
                page5.refreshWallList()
            }
        }

        // ---- 保存地图对话框 ----
        FileDialog {
            id: page5SaveDialog
            title: "保存地图"
            fileMode: FileDialog.SaveFile
            nameFilters: ["PNG 图片 (*.png)"]
            defaultSuffix: "png"
            onAccepted: {
                var filePath = page5SaveDialog.selectedFile.toString()
                if (filePath.startsWith("file:///")) {
                    filePath = filePath.substring(8)
                }
                mapProvider.saveMapWithWalls(filePath)
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
                        source: "qrc:/History_1.png"
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
