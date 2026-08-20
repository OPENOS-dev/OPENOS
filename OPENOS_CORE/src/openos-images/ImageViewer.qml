import QtQuick 2.15; import QtQuick.Window 2.15; import QtQuick.Controls 2.15
/* OPENOS 图片查看器 (独立应用, OPENUI)
 * 支持: 缩略图网格浏览, 单图预览, 缩放/平移, 幻灯片放映, 基本信息显示
 */
Window { id: win; width: 720; height: 520; minimumWidth: 400; minimumHeight: 300; flags: Qt.FramelessWindowHint; title: "图片查看器"; color: "transparent"
  property bool gridMode: true; property int currentIndex: -1; property int zoomLevel: 100; property bool slideshow: false
  property var images: [
    {name:"示例 1 - 日出", size:"1.2 MB", dim:"1920x1080", color:"#E65100"},
    {name:"示例 2 - 海洋", size:"0.8 MB", dim:"2560x1440", color:"#00695C"},
    {name:"示例 3 - 森林", size:"1.5 MB", dim:"3840x2160", color:"#1B5E20"},
    {name:"示例 4 - 城市", size:"0.9 MB", dim:"1920x1200", color:"#37474F"},
    {name:"示例 5 - 星空", size:"2.1 MB", dim:"3840x2160", color:"#1A237E"},
    {name:"示例 6 - 花朵", size:"0.6 MB", dim:"1080x1080", color:"#AD1457"},
    {name:"示例 7 - 山川", size:"1.8 MB", dim:"2560x1600", color:"#33691E"},
    {name:"示例 8 - 极光", size:"2.3 MB", dim:"3840x2160", color:"#0D47A1"},
    {name:"示例 9 - 沙漠", size:"1.1 MB", dim:"1920x1080", color:"#BF360C"},
    {name:"示例 10 - 雪景", size:"0.7 MB", dim:"1920x1080", color:"#263238"}
  ]
  Timer { id: slideshowTimer; interval: 3000; running: slideshow; repeat: true; onTriggered: { currentIndex = (currentIndex + 1) % images.length; gridMode = false } }

  Rectangle { anchors.fill: parent; anchors.margins: 1; radius: OpenUI.shapeLg
    color: Qt.rgba(OpenUI.neutral0.r,OpenUI.neutral0.g,OpenUI.neutral0.b,0.92); border.color: OpenUI.outlineVariant; border.width: 1; clip: true

    // 工具栏
    Rectangle { anchors.top: parent.top; anchors.topMargin: 0; anchors.left: parent.left; anchors.right: parent.right; height: 36; color: "transparent"
      Row { anchors.fill: parent; anchors.margins: OpenUI.sp2; spacing: OpenUI.sp2; verticalAlignment: Text.AlignVCenter
        Text { text: images.length + " 张图片"; anchors.verticalCenter: parent.verticalCenter; color: OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeLabelM }
        Item { width: parent.width - 360; height: 1 }
        // 模式切换
        Rectangle { width: 28; height: 28; radius: OpenUI.shapeXs; color: gh.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,OpenUI.hoverAlpha) : "transparent"; anchors.verticalCenter: parent.verticalCenter
          ThemedIcon { anchors.centerIn: parent; name: "view-grid"; ctx: "Actions"; size: 14; color: gridMode ? OpenUI.primary : OpenUI.onSurfaceVariant }
          MouseArea { id: gh; anchors.fill: parent; hoverEnabled: true; onClicked: gridMode = true } }
        Rectangle { width: 28; height: 28; radius: OpenUI.shapeXs; color: ph.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,OpenUI.hoverAlpha) : "transparent"; anchors.verticalCenter: parent.verticalCenter
          ThemedIcon { anchors.centerIn: parent; name: "image-viewer"; ctx: "Apps"; size: 14; color: !gridMode ? OpenUI.primary : OpenUI.onSurfaceVariant }
          MouseArea { id: ph; anchors.fill: parent; hoverEnabled: true; onClicked: gridMode = false } }
        Rectangle { width: 28; height: 28; radius: OpenUI.shapeXs; color: sh.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,OpenUI.hoverAlpha) : "transparent"; anchors.verticalCenter: parent.verticalCenter
          ThemedIcon { anchors.centerIn: parent; name: "media-playback-start"; ctx: "Actions"; size: 14; color: slideshow ? OpenUI.primary : OpenUI.onSurfaceVariant }
          MouseArea { id: sh; anchors.fill: parent; hoverEnabled: true; onClicked: { slideshow = !slideshow; if (slideshow && currentIndex < 0) { currentIndex = 0; gridMode = false } } } }
        // 缩放 (仅预览模式)
        Rectangle { width: 28; height: 28; radius: OpenUI.shapeXs; color: zoh.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,OpenUI.hoverAlpha) : "transparent"; anchors.verticalCenter: parent.verticalCenter; visible: !gridMode
          ThemedIcon { anchors.centerIn: parent; name: "zoom-in"; ctx: "Actions"; size: 16; color: OpenUI.onSurfaceVariant }
          MouseArea { id: zoh; anchors.fill: parent; hoverEnabled: true; onClicked: zoomLevel = Math.min(400, zoomLevel + 25) } }
        Rectangle { width: 28; height: 28; radius: OpenUI.shapeXs; color: zch.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,OpenUI.hoverAlpha) : "transparent"; anchors.verticalCenter: parent.verticalCenter; visible: !gridMode
          ThemedIcon { anchors.centerIn: parent; name: "zoom-out"; ctx: "Actions"; size: 16; color: OpenUI.onSurfaceVariant }
          MouseArea { id: zch; anchors.fill: parent; hoverEnabled: true; onClicked: zoomLevel = Math.max(10, zoomLevel - 25) } }
        Text { text: zoomLevel + "%"; anchors.verticalCenter: parent.verticalCenter; color: OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeLabelS; visible: !gridMode } } }

    // 缩略图网格
    GridView { id: grid; visible: gridMode; anchors.top: parent.top; anchors.topMargin: 40; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; anchors.margins: OpenUI.sp3
      model: images; cellWidth: 140; cellHeight: 140; interactive: true
      delegate: Rectangle { width: 120; height: 120; radius: OpenUI.shapeMd; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.15); border.color: currentIndex === index ? OpenUI.primary : "transparent"; border.width: 2
        Column { anchors.centerIn: parent; spacing: 4
          Rectangle { width: 64; height: 64; radius: OpenUI.shapeSm; anchors.horizontalCenter: parent.horizontalCenter; color: modelData.color
            ThemedIcon { anchors.centerIn: parent; name: "image-missing"; ctx: "Status"; size: 24; color: Qt.rgba(1,1,1,0.5) } }
          Text { text: modelData.name; anchors.horizontalCenter: parent.horizontalCenter; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeLabelS; elide: Text.ElideRight; width: 100; horizontalAlignment: Text.AlignHCenter }
          Text { text: modelData.dim; anchors.horizontalCenter: parent.horizontalCenter; color: OpenUI.onSurfaceVariant; font.pixelSize: 10 } }
        MouseArea { anchors.fill: parent; hoverEnabled: true; onClicked: { currentIndex = index; gridMode = false; zoomLevel = 100 } } } }

    // 单图预览
    Item { visible: !gridMode; anchors.top: parent.top; anchors.topMargin: 40; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right
      // 上一张
      Rectangle { anchors.left: parent.left; anchors.leftMargin: 8; anchors.verticalCenter: parent.verticalCenter; width: 32; height: 32; radius: 16; color: prev.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,0.2) : Qt.rgba(0,0,0,0.4); z: 2
        ThemedIcon { anchors.centerIn: parent; name: "go-previous"; ctx: "Navigation"; size: 16; color: OpenUI.onSurface }
        MouseArea { id: prev; anchors.fill: parent; hoverEnabled: true; onClicked: { currentIndex = (currentIndex - 1 + images.length) % images.length; zoomLevel = 100 } } }
      // 下一张
      Rectangle { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; width: 32; height: 32; radius: 16; color: nxt.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,0.2) : Qt.rgba(0,0,0,0.4); z: 2
        ThemedIcon { anchors.centerIn: parent; name: "go-next"; ctx: "Navigation"; size: 16; color: OpenUI.onSurface }
        MouseArea { id: nxt; anchors.fill: parent; hoverEnabled: true; onClicked: { currentIndex = (currentIndex + 1) % images.length; zoomLevel = 100 } } }
      // 图片显示
      Flickable { anchors.fill: parent; contentWidth: imgContainer.width; contentHeight: imgContainer.height; clip: true; interactive: true; boundsBehavior: Flickable.StopAtBounds
        Rectangle { id: imgContainer; width: Math.max(parent.width, imgView.width * zoomLevel / 100); height: Math.max(parent.height, imgView.height * zoomLevel / 100)
          Rectangle { id: imgView; width: 320; height: 240; radius: OpenUI.shapeSm; anchors.centerIn: parent; color: currentIndex >= 0 ? images[currentIndex].color : OpenUI.surfaceDim
            transform: Scale { originX: 160; originY: 120; xScale: zoomLevel / 100; yScale: zoomLevel / 100 }
            ThemedIcon { anchors.centerIn: parent; name: "image-missing"; ctx: "Status"; size: 80; color: Qt.rgba(1,1,1,0.3) } } } }
      // 底部信息
      Rectangle { anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; height: 32; color: Qt.rgba(0,0,0,0.5)
        Row { anchors.fill: parent; anchors.margins: OpenUI.sp2; spacing: OpenUI.sp4; verticalAlignment: Text.AlignVCenter
          Text { text: currentIndex >= 0 ? (currentIndex + 1) + " / " + images.length : ""; anchors.verticalCenter: parent.verticalCenter; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeLabelM }
          Text { text: currentIndex >= 0 ? images[currentIndex].name : ""; anchors.verticalCenter: parent.verticalCenter; color: OpenUI.onSurfaceVariant; font.pixelSize: OpenUI.typeLabelM }
          Text { text: currentIndex >= 0 ? images[currentIndex].dim + "  " + images[currentIndex].size : ""; anchors.verticalCenter: parent.verticalCenter; color: OpenUI.onSurfaceDisabled; font.pixelSize: OpenUI.typeLabelS } } } } } }