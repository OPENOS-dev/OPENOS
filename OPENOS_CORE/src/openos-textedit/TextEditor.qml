import QtQuick 2.15; import QtQuick.Window 2.15
Window { id: win; width: 600; height: 450; minimumWidth: 360; minimumHeight: 240; flags: Qt.FramelessWindowHint; title: "文本编辑器"; color: "transparent"
  property string fileName: "未命名.txt"; property int dragX: 0; property int dragY: 0; property bool dragging: false
  Rectangle { anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 6; z: 10; width: 24; height: 24; radius: OpenUI.shapeFull
    color: ch.hovered ? Qt.rgba(OpenUI.error.r,OpenUI.error.g,OpenUI.error.b,0.3) : "transparent"
    Text { anchors.centerIn: parent; text: "\u00D7"; color: ch.hovered ? OpenUI.error : OpenUI.onSurfaceVariant; font.pixelSize: 16 }
    MouseArea { id: ch; anchors.fill: parent; hoverEnabled: true; onClicked: Qt.quit() } }
  Rectangle { anchors.fill: parent; anchors.margins: 1; radius: OpenUI.shapeLg
    color: Qt.rgba(OpenUI.surface6.r,OpenUI.surface6.g,OpenUI.surface6.b,OpenUI.glassMenuAlpha); border.color: OpenUI.outlineVariant; border.width: 1; clip: true
    Column { anchors.fill: parent; anchors.margins: OpenUI.sp3; spacing: OpenUI.sp2
      Rectangle { width: parent.width; height: 28; color: "transparent"
        MouseArea { anchors.fill: parent; onPressed: { dragX = mouse.x; dragY = mouse.y; dragging = true }; onMouseXChanged: { if (dragging) { win.x += mouse.x - dragX; win.y += mouse.y - dragY } }; onReleased: dragging = false } }
      Row { width: parent.width; spacing: OpenUI.sp2
        Text { text: "\u270E " + fileName; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeTitle; font.bold: true; verticalAlignment: Text.AlignVCenter }
        Item { width: parent.width - 200; height: 1 }
        Repeater { model: ["\u21B6","\u21B7","\u2212","\u002B"]
          Rectangle { width: 26; height: 26; radius: OpenUI.shapeXs; color: th.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,OpenUI.hoverAlpha) : "transparent"
            Text { anchors.centerIn: parent; text: modelData; color: OpenUI.onSurfaceVariant; font.pixelSize: 13 }
            MouseArea { id: th; anchors.fill: parent; hoverEnabled: true } } } }
      Rectangle { width: parent.width; height: parent.height - 80; radius: OpenUI.shapeXs; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.2); clip: true
        Flickable { anchors.fill: parent; anchors.margins: 2; contentWidth: ed.width; contentHeight: ed.height
          TextEdit { id: ed; width: Math.max(parent.width, 200); height: Math.max(parent.height, 200); color: OpenUI.onSurface; font.pixelSize: 13; font.family: "monospace"; wrapMode: Text.WrapAtWordBoundaryOrAnywhere; selectByMouse: true } } } } }