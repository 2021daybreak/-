import re

path = "C:/Users/sz/Documents/server_test/Main.qml"
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

# Replace 1: RowLayout header -> contentArea Item + StackLayout
p1 = re.compile(
    r'    RowLayout\{\n.*?//.*?\n.*?anchors\.top: topNavBar\.bottom\n.*?//.*?\n.*?anchors\.bottom: parent\.bottom\n.*?//.*?\n.*?width: parent\.width\n.*?//.*?\n.*?spacing: 0',
    re.DOTALL
)
r1 = (
    '    // content area: between topNavBar and bottomNavBar\n'
    '    Item {\n'
    '        id: contentArea\n'
    '        anchors.top: topNavBar.bottom\n'
    '        anchors.bottom: bottomNavBar.top\n'
    '        width: parent.width\n'
    '\n'
    '        StackLayout {\n'
    '            anchors.fill: parent\n'
    '\n'
    '            // bind to currentPageIndex\n'
    '            currentIndex: currentPageIndex'
)
content = p1.sub(r1, content, count=1)
print("Replace 1 done, contentArea:", content.count("contentArea"))

# Replace 2: Remove left sidebar Rectangle (from "    Rectangle//..." to "    StackLayout {")
p2 = re.compile(
    r'\n    Rectangle//.*?\n    \{\n.*?Layout\.preferredWidth: 100.*?\n.*?Layout\.fillHeight: true.*?\n\n.*?color: "#87cefa"\n    ColumnLayout \{\n.*?anchors\.fill: parent.*?\n.*?spacing: 0.*?Button.*?text:.*?onClicked:currentPageIndex = 0.*?\}\n.*?Button.*?text:.*?onClicked: currentPageIndex = 1.*?\}\n.*?Button.*?text:.*?onClicked: currentPageIndex = 2.*?\}\n.*?Button.*?text:.*?onClicked: currentPageIndex = 3.*?\}\n.*?Button.*?text:.*?onClicked: currentPageIndex = 4.*?\}\n.*?\n                   \}\n                   \}\n    StackLayout \{',
    re.DOTALL
)
content = p2.sub('\n    StackLayout {', content, count=1)
print("Replace 2 done, StackLayout:", content.count("StackLayout"))

# Replace 3: Remove old Layout.fillWidth/fillHeight + comment before currentIndex
old_layout = '        Layout.fillWidth: true\n        Layout.fillHeight: true\n\n        //'
idx = content.find(old_layout)
if idx != -1:
    end_idx = content.find('currentIndex: currentPageIndex', idx)
    if end_idx != -1:
        content = content[:idx] + '        currentIndex: currentPageIndex' + content[end_idx + len('currentIndex: currentPageIndex'):]
        print("Replace 3 done")
    else:
        print("WARN: end marker not found")
else:
    print("WARN: old_layout not found")

# Replace 4: Insert bottomNavBar
bn = '''    }

    // Bottom Navigation Bar
    Rectangle {
        id: bottomNavBar
        width: parent.width
        height: 60
        color: "#87cefa"
        anchors.bottom: parent.bottom

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "\u6307\u4ee4"
                onClicked: currentPageIndex = 0
                background: Rectangle {
                    color: (currentPageIndex === 0) ? "#3498db" : "transparent"
                    Rectangle {
                        height: 4; width: parent.width; color: "#2980b9"
                        visible: (currentPageIndex === 0)
                        anchors.top: parent.top
                    }
                }
                contentItem: Text {
                    text: parent.text
                    color: (currentPageIndex === 0) ? "white" : "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "\u63a7\u5236"
                onClicked: currentPageIndex = 1
                background: Rectangle {
                    color: (currentPageIndex === 1) ? "#3498db" : "transparent"
                    Rectangle {
                        height: 4; width: parent.width; color: "#2980b9"
                        visible: (currentPageIndex === 1)
                        anchors.top: parent.top
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
                Layout.fillHeight: true
                text: "\u8bbe\u7f6e"
                onClicked: currentPageIndex = 2
                background: Rectangle {
                    color: (currentPageIndex === 2) ? "#3498db" : "transparent"
                    Rectangle {
                        height: 4; width: parent.width; color: "#2980b9"
                        visible: (currentPageIndex === 2)
                        anchors.top: parent.top
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
                Layout.fillHeight: true
                text: "\u5bfc\u822a"
                onClicked: currentPageIndex = 3
                background: Rectangle {
                    color: (currentPageIndex === 3) ? "#3498db" : "transparent"
                    Rectangle {
                        height: 4; width: parent.width; color: "#2980b9"
                        visible: (currentPageIndex === 3)
                        anchors.top: parent.top
                    }
                }
                contentItem: Text {
                    text: parent.text
                    color: (currentPageIndex === 3) ? "white" : "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "\u4f5c\u56fe"
                onClicked: currentPageIndex = 4
                background: Rectangle {
                    color: (currentPageIndex === 4) ? "#3498db" : "transparent"
                    Rectangle {
                        height: 4; width: parent.width; color: "#2980b9"
                        visible: (currentPageIndex === 4)
                        anchors.top: parent.top
                    }
                }
                contentItem: Text {
                    text: parent.text
                    color: (currentPageIndex === 4) ? "white" : "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }'''

old_end = "\n    }\n    }\n    Popup{"
new_end = "\n        } // close StackLayout\n    } // close contentArea\n\n" + bn + "\n\n    Popup{"
content = content.replace(old_end, new_end, 1)
print("Replace 4 done, bottomNavBar:", content.count("bottomNavBar"))

# Verify
for key in ["bottomNavBar", "contentArea", "currentPageIndex", "topNavBar", "StackLayout"]:
    c = content.count(key)
    print(f"  {key} = {c} {'OK' if c > 0 else 'MISSING!'}")

# Write with UTF-8 BOM
with open(path, "wb") as f:
    f.write(b'\xef\xbb\xbf')
    f.write(content.encode('utf-8'))

print("Done. Written with UTF-8 BOM.")
