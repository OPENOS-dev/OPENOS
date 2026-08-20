import QtQuick 2.15; import QtQuick.Window 2.15
/* OPENOS 终端 (独立应用, OPENUI)
 * Windows Terminal 风格: 多标签管理, 每个标签独立会话
 * 窗口装饰由合成器 (SSD) 统一提供: 悬浮标题栏 + 右侧 Windows 控制按钮
 */
Window { id: termWin; width: 760; height: 500; minimumWidth: 400; minimumHeight: 240; flags: Qt.FramelessWindowHint; title: "终端"; color: "transparent"
  ListModel { id: tabModel }; property int activeTab: 0; property string cmdInput: ""

  function addTab(name) { tabModel.append({name: name || "shell", history: "", input: ""}); activeTab = tabModel.count - 1; cmdInput = ""; cmdField.focus = true }
  function closeTab(idx) { if (tabModel.count <= 1) return; tabModel.remove(idx); if (activeTab >= tabModel.count) activeTab = tabModel.count - 1 }
  function curTab() { return activeTab >= 0 && activeTab < tabModel.count ? tabModel.get(activeTab) : null }
  function execCmd(cmd) { var tab = curTab(); if (!tab) return; var result = ""; var parts = cmd.trim().split(/\s+/)
    switch (parts[0]) {
    case "help": result = "可用命令: help, echo, date, whoami, clear, pwd, ls, uname, cat, neofetch, cal, uptime, free, ps, hostname, df, du, ip, openos"; break
    case "echo": result = parts.slice(1).join(" "); break; case "date": result = new Date().toString(); break; case "whoami": result = "user"; break; case "pwd": result = "/home/user"; break
    case "ls": result = "Documents  Downloads  Desktop  notes.md  config.json  projects"; break; case "uname": result = "OPENOS DEV2026.1 x86_64 GNU/Linux"; break; case "hostname": result = "openos-dev"; break
    case "neofetch": result = "user@openos-dev\nOS: OPENOS DEV2026.1\nKernel: Linux 7.1.8\nShell: bash 5.3\nTerminal: openos-terminal\nCPU: x86_64\nMemory: 2048MiB / 8192MiB"; break
    case "cal": result = "    August 2026\nMo Tu We Th Fr Sa Su\n                1  2\n 3  4  5  6  7  8  9\n10 11 12 13 14 15 16\n17 18 19 20 21 22 23\n24 25 26 27 28 29 30\n31"; break
    case "uptime": result = " 10:42:30 up 3 days, 2:15, 1 user, load average: 0.08, 0.03, 0.01"; break
    case "free": result = "              total        used        free      shared\nMem:          8192        2048        6144         256\nSwap:         4096           0        4096"; break
    case "ps": result = "  PID TTY          TIME CMD\n    1 ?        00:00:02 init\n  512 ?        00:00:15 openos-shell\n 1024 ?        00:00:08 openos-terminal"; break
    case "df": result = "Filesystem     1K-blocks    Used Available Use% Mounted on\n/dev/sda1       25600000 18700000   6900000  73% /\n/dev/sda2       51200000 21400000  29800000  42% /home"; break
    case "openos": result = "OPENOS - 构建你自己的操作系统\n  openos-compositor\n  openos-shell\n  openos-welcome\n  openos-calc\n  openos-notes"; break
    default: result = cmd.trim() !== "" ? "bash: " + parts[0] + ": 命令未找到" : "" }
    tab.history += "$ " + cmd.trim() + "\n" + (result ? result + "\n" : "") + "\n"; tab.input = ""; tabModel.set(activeTab, tab); cmdInput = ""; cmdField.focus = true }
  Component.onCompleted: addTab("shell")

  Rectangle { anchors.fill: parent; anchors.margins: -8; radius: OpenUI.shapeLg + 8; color: Qt.rgba(0,0,0,0.3); z: -1; opacity: 0.6 }

  Rectangle { anchors.fill: parent; anchors.margins: 1; radius: OpenUI.shapeLg; color: Qt.rgba(0.08,0.08,0.08,0.95); border.color: OpenUI.outlineVariant; border.width: 1; clip: true
    Column { anchors.fill: parent; spacing: 0
      // 标签栏
      Rectangle { width: parent.width; height: 32; color: Qt.rgba(0.12,0.12,0.12,0.9)
        Row { anchors.fill: parent; spacing: 0
          Repeater { model: tabModel
            Rectangle { width: Math.max(80, Math.min(140, parent.width / Math.max(tabModel.count, 1) - 20)); height: 30; color: activeTab === index ? Qt.rgba(0.2,0.2,0.2,0.8) : Qt.rgba(0.12,0.12,0.12,0.9); radius: 4; border.color: activeTab === index ? OpenUI.outlineVariant : "transparent"; border.width: 1
              Row { anchors.fill: parent; anchors.margins: 4; spacing: 4
                Text { text: "\u25CF"; color: model.name === "shell" ? OpenUI.tertiary : OpenUI.primary; font.pixelSize: 8; verticalAlignment: Text.AlignVCenter }
                Text { text: model.name; color: activeTab === index ? OpenUI.onSurface : OpenUI.onSurfaceVariant; font.pixelSize: 11; elide: Text.ElideRight; width: parent.width - 30; verticalAlignment: Text.AlignVCenter }
                Rectangle { width: 14; height: 14; radius: 7; visible: tabModel.count > 1; color: tch.hovered ? Qt.rgba(OpenUI.error.r,OpenUI.error.g,OpenUI.error.b,0.3) : "transparent"
                  Text { anchors.centerIn: parent; text: "\u00D7"; color: OpenUI.onSurfaceDisabled; font.pixelSize: 10 }
                  MouseArea { id: tch; anchors.fill: parent; hoverEnabled: true; onClicked: closeTab(index) } } }
              MouseArea { anchors.fill: parent; onClicked: activeTab = index } } }
          Rectangle { width: 24; height: 24; radius: 4; color: ath.hovered ? Qt.rgba(OpenUI.onSurface.r,OpenUI.onSurface.g,OpenUI.onSurface.b,0.1) : "transparent"; anchors.verticalCenter: parent.verticalCenter
            Text { anchors.centerIn: parent; text: "+"; color: OpenUI.onSurfaceVariant; font.pixelSize: 16 }
            MouseArea { id: ath; anchors.fill: parent; hoverEnabled: true; onClicked: addTab("shell") } } } }
      // 终端输出
      Rectangle { width: parent.width; height: parent.height - 32; color: Qt.rgba(0.08,0.08,0.08,1)
        Column { width: parent.width; height: parent.height; spacing: 0
          Flickable { id: termScroll; width: parent.width; height: parent.height - 36; contentWidth: parent.width; contentHeight: termOut.height + 20; clip: true; boundsBehavior: Flickable.StopAtBounds
            Text { id: termOut; text: { var t = curTab(); return t ? t.history : "" }; color: OpenUI.onSurface; font.pixelSize: 13; font.family: "monospace"; width: parent.width; wrapMode: Text.Wrap; leftPadding: 10; topPadding: 8 }
            onContentHeightChanged: termScroll.contentY = termScroll.contentHeight - termScroll.height }
          // 输入行
          Rectangle { width: parent.width; height: 36; color: Qt.rgba(0.12,0.12,0.12,0.9)
            Row { anchors.fill: parent; anchors.margins: 4; spacing: 4
              Text { text: "$"; color: OpenUI.tertiary; font.pixelSize: 13; font.family: "monospace"; verticalAlignment: Text.AlignVCenter; font.bold: true }
              TextInput { id: cmdField; width: parent.width - 30; color: OpenUI.onSurface; font.pixelSize: 13; font.family: "monospace"; text: cmdInput; verticalAlignment: Text.AlignVCenter; focus: true; clip: true
                onTextChanged: cmdInput = text; onAccepted: execCmd(cmdInput) } } } } } } } }