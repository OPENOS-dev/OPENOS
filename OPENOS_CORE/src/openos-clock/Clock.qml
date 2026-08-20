import QtQuick 2.15; import QtQuick.Window 2.15
Window { id: win; width: 360; height: 400; minimumWidth: 300; minimumHeight: 340; flags: Qt.FramelessWindowHint; title: "时钟"; color: "transparent"
  property int tab: 0
  property var alarms: [{time:"07:00", label:"起床", enabled:true},{time:"12:00", label:"午休", enabled:false},{time:"22:00", label:"睡觉", enabled:true}]
  Rectangle { anchors.fill: parent; anchors.margins: 1; radius: OpenUI.shapeLg
    color: Qt.rgba(OpenUI.neutral0.r,OpenUI.neutral0.g,OpenUI.neutral0.b,0.92); border.color: OpenUI.outlineVariant; border.width: 1; clip: true
    Column { anchors.fill: parent; anchors.margins: OpenUI.sp3; spacing: OpenUI.sp2
      // 时间显示
      Text { id: timeDisplay; text: Qt.formatTime(new Date(),"HH:mm:ss"); anchors.horizontalCenter: parent.horizontalCenter; color: OpenUI.onSurface; font.pixelSize: 48; font.weight: Font.Light
        Timer { interval: 1000; running: true; repeat: true; onTriggered: timeDisplay.text = Qt.formatTime(new Date(),"HH:mm:ss") } }
      Text { text: Qt.formatDate(new Date(),"yyyy年M月d日 dddd"); anchors.horizontalCenter: parent.horizontalCenter; color: OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeLabelM }
      // 标签切换
      Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: OpenUI.sp2
        Repeater { model: ["时钟","闹钟","计时器"]
          Rectangle { width: 60; height: 28; radius: 14; color: tab === index ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.2) : "transparent"
            Text { anchors.centerIn: parent; text: modelData; color: tab === index ? OpenUI.primary : OpenUI.onSurfaceVariant; font.pixelSize: 11 }
            MouseArea { anchors.fill: parent; onClicked: tab = index } } } }
      // 闹钟列表
      Column { visible: tab === 1; width: parent.width; spacing: OpenUI.sp1
        Repeater { model: alarms
          Rectangle { width: parent.width; height: 44; radius: OpenUI.shapeXs; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.1)
            Row { anchors.fill: parent; anchors.margins: OpenUI.sp2; spacing: OpenUI.sp2
              Column { spacing: 2; verticalAlignment: Text.AlignVCenter
                Text { text: modelData.time; color: OpenUI.onSurface; font.pixelSize: 18; font.weight: Font.Light }
                Text { text: modelData.label; color: OpenUI.onSurfaceVariant; font.pixelSize: 11 } }
              Item { width: parent.width - 140; height: 1 }
              Rectangle { width: 36; height: 20; radius: 10; anchors.verticalCenter: parent.verticalCenter; color: modelData.enabled ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.5) : Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.3)
                Rectangle { width: 16; height: 16; radius: 8; x: modelData.enabled ? 18 : 2; y: 2; color: modelData.enabled ? OpenUI.primary : OpenUI.onSurfaceVariant } } } } } }
      // 计时器
      Column { visible: tab === 2; width: parent.width; spacing: OpenUI.sp2; anchors.horizontalCenter: parent.horizontalCenter
        Text { text: "00:05:00"; anchors.horizontalCenter: parent.horizontalCenter; color: OpenUI.onSurface; font.pixelSize: 36; font.weight: Font.Light }
        Rectangle { width: 120; height: 36; radius: 18; anchors.horizontalCenter: parent.horizontalCenter; color: Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.2)
          Text { anchors.centerIn: parent; text: "开始"; color: OpenUI.primary; font.pixelSize: 13 }
          MouseArea { anchors.fill: parent; hoverEnabled: true } } } } } }