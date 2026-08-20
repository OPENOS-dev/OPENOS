import QtQuick 2.15; import QtQuick.Window 2.15
/* OPENOS 便签 (独立应用, OPENUI)
 * Apple 备忘录风格: 左侧笔记列表, 右侧内容编辑区
 * 支持搜索, 格式工具栏, 文件夹分类
 * 窗口装饰由合成器 (SSD) 统一提供: 悬浮标题栏 + 右侧 Windows 控制按钮
 */
Window { id: notesWin; width: 640; height: 500; minimumWidth: 480; minimumHeight: 360; flags: Qt.FramelessWindowHint; title: "便签"; color: "transparent"
  ListModel { id: notesModel }; property int selectedNote: -1; property string searchText: ""
  function addNote() { var now = new Date(); notesModel.insert(0, {title:"新便签", content:"", date:Qt.formatDate(now,"yyyy-MM-dd"), folder:"全部"}); selectedNote = 0; noteTitleField.focus = true; noteTitleField.selectAll() }
  function deleteNote(idx) { if (idx < 0 || idx >= notesModel.count) return; notesModel.remove(idx); if (selectedNote >= notesModel.count) selectedNote = notesModel.count - 1; if (notesModel.count === 0) selectedNote = -1 }
  Component.onCompleted: { notesModel.append({title:"欢迎使用 OPENOS", content:"这是 OPENOS 便签应用。\n\n\u2022 创建新笔记\n\u2022 搜索笔记内容\n\u2022 按文件夹分类", date:"2026-08-18", folder:"全部"}); notesModel.append({title:"待办事项", content:"\u25A1 完成 OAK 初始化\n\u25A1 配置 opt 包管理器\n\u25A1 设置用户账户\n\u25A1 安装开发工具", date:"2026-08-17", folder:"全部"}); notesModel.append({title:"系统笔记", content:"OPENOS 启动命令:\n  openos-compositor  -- 启动合成器\n  openos-shell       -- 启动桌面\n  openos-welcome     -- 首次启动引导\n\n快捷键:\n  Alt+T  -- 终端\n  Alt+F  -- 文件管理器", date:"2026-08-16", folder:"技术"}); selectedNote = 0 }

  // 窗口阴影
  Rectangle { anchors.fill: parent; anchors.margins: -8; radius: OpenUI.shapeLg + 8; color: Qt.rgba(0,0,0,0.3); z: -1; opacity: 0.6 }

  // 主容器
  Rectangle { anchors.fill: parent; anchors.margins: 1; radius: OpenUI.shapeLg; color: Qt.rgba(OpenUI.neutral10.r,OpenUI.neutral10.g,OpenUI.neutral10.b,0.95); border.color: OpenUI.outlineVariant; border.width: 1; clip: true
    Row { anchors.fill: parent; anchors.margins: 0; spacing: 0
      // 左侧: 笔记列表
      Rectangle { width: 240; height: parent.height; color: Qt.rgba(OpenUI.surfaceDim.r,OpenUI.surfaceDim.g,OpenUI.surfaceDim.b,0.5)
        Column { width: parent.width; height: parent.height; spacing: 0
          Rectangle { width: parent.width; height: 40; color: "transparent"
            Row { anchors.fill: parent; anchors.margins: OpenUI.sp2; spacing: OpenUI.sp1
              Row { spacing: OpenUI.sp1; height: parent.height
                ThemedIcon { name: "accessories-notes"; ctx: "Apps"; size: 16; color: OpenUI.onSurface; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "便签"; color: OpenUI.onSurface; font.pixelSize: OpenUI.typeTitle; font.bold: true; verticalAlignment: Text.AlignVCenter }
              }
              Item { width: parent.width - 130; height: 1 }
              Rectangle { width: 28; height: 28; radius: OpenUI.shapeXs; color: addH.hovered ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.2) : "transparent"; scale: addH.pressed ? 0.9 : 1.0; Behavior on scale { NumberAnimation { duration: 60 } }
                Text { anchors.centerIn: parent; text: "+"; color: OpenUI.primary; font.pixelSize: 20 }; MouseArea { id: addH; anchors.fill: parent; hoverEnabled: true; onClicked: addNote() } } } }
          // 搜索栏
          Rectangle { width: parent.width; height: 32; color: "transparent"
            Rectangle { anchors.fill: parent; anchors.margins: OpenUI.sp1; radius: OpenUI.shapeXs; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.2)
              Row { anchors.fill: parent; anchors.margins: 6; spacing: 4
                ThemedIcon { name: "system-search"; ctx: "Apps"; size: 12; color: OpenUI.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
                TextInput { width: parent.width - 20; height: parent.height; color: OpenUI.onSurface; font.pixelSize: 12; placeholderText: "搜索"; clip: true; verticalAlignment: Text.AlignVCenter; onTextChanged: notesWin.searchText = text } } } }
          // 文件夹分类
          Rectangle { width: parent.width; height: 28; color: "transparent"
            Row { anchors.fill: parent; anchors.margins: OpenUI.sp1; spacing: 4
              Rectangle { width: 50; height: 22; radius: 11; color: Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.2); Text { anchors.centerIn: parent; text: "全部"; color: OpenUI.primary; font.pixelSize: 10 } }
              Rectangle { width: 50; height: 22; radius: 11; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.15); Text { anchors.centerIn: parent; text: "个人"; color: OpenUI.onSurfaceVariant; font.pixelSize: 10 } }
              Rectangle { width: 50; height: 22; radius: 11; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.15); Text { anchors.centerIn: parent; text: "技术"; color: OpenUI.onSurfaceVariant; font.pixelSize: 10 } } } }
          // 笔记列表
          ListView { width: parent.width; height: parent.height - 100; clip: true; model: notesModel; add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 150 } }
            delegate: Rectangle { width: parent.width; height: 60; color: selectedNote === index ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.12) : "transparent"; border.color: selectedNote === index ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.2) : "transparent"; border.width: 1
              Column { anchors.fill: parent; anchors.margins: OpenUI.sp2; spacing: 2
                Row { width: parent.width; spacing: OpenUI.sp1
                  Text { text: model.title; color: selectedNote === index ? OpenUI.primary : OpenUI.onSurface; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight; width: parent.width - 60 }
                  Text { text: model.date; color: OpenUI.onSurfaceDisabled; font.pixelSize: 10; horizontalAlignment: Text.AlignRight } }
                Text { text: model.content.replace(/\n/g, " ").substring(0, 60); color: OpenUI.onSurfaceVariant; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width } }
              MouseArea { anchors.fill: parent; onClicked: selectedNote = index }
              Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 4; width: 18; height: 18; radius: 9; visible: selectedNote === index; color: delH.hovered ? Qt.rgba(OpenUI.error.r,OpenUI.error.g,OpenUI.error.b,0.3) : "transparent"
                ThemedIcon { anchors.centerIn: parent; name: "window-close"; ctx: "Actions"; size: 12; color: OpenUI.error }; MouseArea { id: delH; anchors.fill: parent; hoverEnabled: true; onClicked: deleteNote(index) } } } } } }
      // 分隔线
      Rectangle { width: 1; height: parent.height; color: Qt.rgba(OpenUI.outlineVariant.r,OpenUI.outlineVariant.g,OpenUI.outlineVariant.b,0.3) }
      // 右侧: 内容编辑区
      Rectangle { width: parent.width - 241; height: parent.height; color: "transparent"
        Column { width: parent.width; height: parent.height; spacing: 0; anchors.margins: OpenUI.sp3
          Rectangle { width: parent.width; height: parent.height; visible: selectedNote < 0; color: "transparent"
            Column { anchors.centerIn: parent; spacing: OpenUI.sp2
              ThemedIcon { name: "accessories-notes"; ctx: "Apps"; size: 40; color: OpenUI.onSurfaceDisabled; anchors.horizontalCenter: parent.horizontalCenter }
              Text { text: "选择或创建一条笔记"; color: OpenUI.onSurfaceDisabled; font.pixelSize: OpenUI.typeBodyM; anchors.horizontalCenter: parent.horizontalCenter }
            } }
          Rectangle { width: parent.width; height: parent.height; visible: selectedNote >= 0; color: "transparent"
            Column { width: parent.width; height: parent.height; spacing: OpenUI.sp2; anchors.margins: OpenUI.sp3
              Rectangle { width: parent.width; height: 36; color: "transparent"
                TextInput { id: noteTitleField; anchors.fill: parent; text: selectedNote >= 0 ? notesModel.get(selectedNote).title : ""; color: OpenUI.onSurface; font.pixelSize: 20; font.bold: true; onTextChanged: { if (selectedNote >= 0) notesModel.setProperty(selectedNote, "title", text) } } }
              // 格式工具栏
              Row { width: parent.width; height: 28; spacing: 4
                Repeater { model: [
                    {text:"B", icon:""}, {text:"I", icon:""}, {text:"U", icon:""},
                    {text:"", icon:"view-list", ctx:"Actions"},
                    {text:"", icon:"open-menu", ctx:"Actions"},
                    {text:"", icon:"overflow-menu", ctx:"Actions"}
                  ]
                  Rectangle { width: 28; height: 28; radius: OpenUI.shapeXs; color: fh.hovered ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.15) : "transparent"; scale: fh.pressed ? 0.9 : 1.0; Behavior on scale { NumberAnimation { duration: 60 } }
                    Text { anchors.centerIn: parent; text: modelData.text; color: OpenUI.onSurfaceVariant; font.pixelSize: 13; font.bold: modelData.text === "B"; visible: modelData.text.length > 0 }
                    ThemedIcon { anchors.centerIn: parent; name: modelData.icon; ctx: modelData.ctx; size: 14; color: OpenUI.onSurfaceVariant; visible: modelData.icon.length > 0 }
                    MouseArea { id: fh; anchors.fill: parent; hoverEnabled: true } } }
                Item { width: parent.width - 170; height: 1 }
                Text { text: selectedNote >= 0 ? notesModel.get(selectedNote).date : ""; color: OpenUI.onSurfaceDisabled; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter } }
              // 内容编辑区
              Rectangle { width: parent.width; height: parent.height - 80; radius: OpenUI.shapeXs; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.08)
                Flickable { anchors.fill: parent; anchors.margins: 2; contentWidth: ce.width; contentHeight: ce.height; clip: true
                  TextEdit { id: ce; width: Math.max(parent.width, 200); height: Math.max(parent.height, 200); text: selectedNote >= 0 ? notesModel.get(selectedNote).content : ""; color: OpenUI.onSurface; font.pixelSize: 14; wrapMode: Text.WrapAtWordBoundaryOrAnywhere; selectByMouse: true
                    onTextChanged: { if (selectedNote >= 0) notesModel.setProperty(selectedNote, "content", text) } } } } } } } } } }