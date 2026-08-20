import QtQuick 2.15; import QtQuick.Window 2.15
Window { id: win; width: 480; height: 360; minimumWidth: 360; minimumHeight: 240; flags: Qt.FramelessWindowHint; title: "媒体播放器"; color: "transparent"
  property bool playing: false; property int progress: 30; property int totalTime: 180
  property var playlist: ["曲目 1 - 开场", "曲目 2 - 主题", "曲目 3 - 尾声", "曲目 4 - 安可"]
  property int currentTrack: 0
  Rectangle { anchors.fill: parent; anchors.margins: 1; radius: OpenUI.shapeLg
    color: Qt.rgba(OpenUI.neutral0.r,OpenUI.neutral0.g,OpenUI.neutral0.b,0.92); border.color: OpenUI.outlineVariant; border.width: 1; clip: true
    Column { anchors.fill: parent; anchors.margins: OpenUI.sp4; spacing: OpenUI.sp3
      // 专辑封面占位
      Rectangle { width: 120; height: 120; radius: OpenUI.shapeMd; anchors.horizontalCenter: parent.horizontalCenter; color: Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.2)
        Text { anchors.centerIn: parent; text: "\u266B"; color: OpenUI.primary; font.pixelSize: 48 } }
      // 曲目信息
      Text { text: playlist[currentTrack]; anchors.horizontalCenter: parent.horizontalCenter; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeTitle; font.bold: true }
      Text { text: "艺术家 - OPENOS"; anchors.horizontalCenter: parent.horizontalCenter; color: OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeLabelM }
      // 进度条
      Rectangle { width: parent.width; height: 4; radius: 2; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.3)
        Rectangle { width: progress / totalTime * parent.width; height: 4; radius: 2; color: OpenUI.primary } }
      Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: OpenUI.sp4
        Rectangle { width: 36; height: 36; radius: 18; color: ph.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,0.15) : "transparent"
          Text { anchors.centerIn: parent; text: "\u23EE"; color: OpenUI.onSurface; font.pixelSize: 18 }
          MouseArea { id: ph; anchors.fill: parent; hoverEnabled: true; onClicked: currentTrack = Math.max(0, currentTrack - 1) } }
        Rectangle { width: 44; height: 44; radius: 22; color: ph2.hovered ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.3) : Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.2)
          Text { anchors.centerIn: parent; text: playing ? "\u23F8" : "\u25B6"; color: OpenUI.primary; font.pixelSize: 20 }
          MouseArea { id: ph2; anchors.fill: parent; hoverEnabled: true; onClicked: playing = !playing } }
        Rectangle { width: 36; height: 36; radius: 18; color: ph3.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,0.15) : "transparent"
          Text { anchors.centerIn: parent; text: "\u23ED"; color: OpenUI.onSurface; font.pixelSize: 18 }
          MouseArea { id: ph3; anchors.fill: parent; hoverEnabled: true; onClicked: currentTrack = Math.min(playlist.length - 1, currentTrack + 1) } } }
      // 音量
      Row { width: parent.width; spacing: OpenUI.sp2; anchors.horizontalCenter: parent.horizontalCenter
        Text { text: "\uD83D\uDD0A"; color: OpenUI.onSurfaceVariant; font.pixelSize: 12; verticalAlignment: Text.AlignVCenter }
        Rectangle { width: 100; height: 4; radius: 2; anchors.verticalCenter: parent.verticalCenter; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.3)
          Rectangle { width: 0.7 * parent.width; height: 4; radius: 2; color: OpenUI.primary } } } } } }