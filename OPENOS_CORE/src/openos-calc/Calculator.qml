import QtQuick 2.15; import QtQuick.Window 2.15
/* OPENOS 计算器 (独立应用, OPENUI)
 * macOS 计算器风格: 圆形按钮, 基本/科学模式, 计算历史
 * 窗口装饰由合成器 (SSD) 统一提供: 悬浮标题栏 + 右侧 Windows 控制按钮
 */
Window { id: calcWin; width: 280; height: 420; minimumWidth: 260; minimumHeight: 380; flags: Qt.FramelessWindowHint; title: "计算器"; color: "transparent"
  property string display: "0"; property string prevValue: ""; property string op: ""; property bool clearNext: false; property bool scientificMode: false; property var history: []
  function digit(d) { if (clearNext) { display = ""; clearNext = false } display = display === "0" ? d : display + d }
  function operator(o) { if (display !== "") { prevValue = display; op = o; clearNext = true } }
  function equals() { if (op === "" || display === "" || prevValue === "") return; var a = parseFloat(prevValue), b = parseFloat(display); var r = 0
    switch (op) { case "+": r = a + b; break; case "-": r = a - b; break; case "\u00D7": r = a * b; break; case "\u00F7": r = b !== 0 ? a / b : 0; break }
    history.push(prevValue + " " + op + " " + display + " = " + r); display = String(r); op = ""; clearNext = true }
  function clearAll() { display = "0"; prevValue = ""; op = ""; clearNext = false }
  function percent() { display = String(parseFloat(display) / 100) }
  function negate() { display = String(-parseFloat(display)) }

  // 圆形按钮组件
  Component { id: btnCmp; Rectangle { id: b; property string label: "0"; property string val: "0"; property color bc: Qt.rgba(0.2,0.2,0.2,0.6); property color tc: OpenUI.onSurface; signal clicked()
    width: (parent.width - 12) / 4; height: 48; radius: 24; color: bh.hovered ? Qt.rgba(bc.r + 0.1, bc.g + 0.1, bc.b + 0.1, bc.a) : bc; scale: bh.pressed ? 0.92 : 1.0
    Behavior on scale { NumberAnimation { duration: 80 } }
    Text { anchors.centerIn: parent; text: label; color: tc; font.pixelSize: 20 }
    MouseArea { id: bh; anchors.fill: parent; hoverEnabled: true; onClicked: clicked() } } }

  // 窗口阴影
  Rectangle { anchors.fill: parent; anchors.margins: -8; radius: OpenUI.shapeLg + 8; color: Qt.rgba(0,0,0,0.3); z: -1; opacity: 0.6 }

  // 主容器
  Rectangle { anchors.fill: parent; anchors.margins: 1; radius: OpenUI.shapeLg; color: Qt.rgba(OpenUI.neutral0.r,OpenUI.neutral0.g,OpenUI.neutral0.b,0.92); border.color: OpenUI.outlineVariant; border.width: 1; clip: true
    Column { anchors.fill: parent; anchors.margins: OpenUI.sp3; spacing: OpenUI.sp2
      // 模式切换
      Row { width: parent.width; spacing: OpenUI.sp1
        Text { text: "基本"; color: !scientificMode ? OpenUI.primary : OpenUI.onSurfaceVariant; font.pixelSize: 11; font.bold: !scientificMode; verticalAlignment: Text.AlignVCenter }
        Rectangle { width: 32; height: 16; radius: 8; anchors.verticalCenter: parent.verticalCenter; color: scientificMode ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.4) : Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.3)
          Behavior on color { ColorAnimation { duration: 150 } }
          Rectangle { width: 12; height: 12; radius: 6; x: scientificMode ? 18 : 2; y: 2; color: scientificMode ? OpenUI.primary : OpenUI.onSurfaceVariant; Behavior on x { NumberAnimation { duration: 150 } } }
          MouseArea { anchors.fill: parent; onClicked: scientificMode = !scientificMode } }
        Text { text: "科学"; color: scientificMode ? OpenUI.primary : OpenUI.onSurfaceVariant; font.pixelSize: 11; font.bold: scientificMode; verticalAlignment: Text.AlignVCenter } }
      // 显示屏
      Rectangle { width: parent.width; height: 52; radius: OpenUI.shapeXs; color: Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.15)
        Text { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: display; color: OpenUI.onSurface; font.pixelSize: 34; font.weight: Font.Light }
        Text { anchors.left: parent.left; anchors.leftMargin: 8; anchors.top: parent.top; anchors.topMargin: 4; text: "="; color: OpenUI.onSurfaceDisabled; font.pixelSize: 10; visible: history.length > 0 } }
      // 科学模式扩展行
      Row { visible: scientificMode; width: parent.width; spacing: 3
        Repeater { model: ["sin","cos","tan","log","ln","sqrt","x\u00B2","x\u00B3"]
          Rectangle { width: (parent.width - 21) / 8; height: 36; radius: 18; color: sciH.hovered ? Qt.rgba(OpenUI.primary.r,OpenUI.primary.g,OpenUI.primary.b,0.25) : Qt.rgba(OpenUI.surfaceBright.r,OpenUI.surfaceBright.g,OpenUI.surfaceBright.b,0.1); scale: sciH.pressed ? 0.92 : 1.0; Behavior on scale { NumberAnimation { duration: 60 } }
            Text { anchors.centerIn: parent; text: modelData; color: OpenUI.primary; font.pixelSize: 11 }; MouseArea { id: sciH; anchors.fill: parent; hoverEnabled: true; onClicked: { display = modelData + "(" + display + ")"; clearNext = true } } } } }
      // 按钮网格
      Column { width: parent.width; spacing: 4
        Row { width: parent.width; spacing: 4; Repeater { model: [{l:"C",v:"C",c:Qt.rgba(0.5,0.5,0.5,0.5),tc:OpenUI.onSurface},{l:"\u00B1",v:"\u00B1",c:Qt.rgba(0.5,0.5,0.5,0.5),tc:OpenUI.onSurface},{l:"%",v:"%",c:Qt.rgba(0.5,0.5,0.5,0.5),tc:OpenUI.onSurface},{l:"\u00F7",v:"\u00F7",c:Qt.rgba(1.0,0.6,0.0,0.8),tc:"#FFFFFF"}]
          Loader { sourceComponent: btnCmp; onLoaded: { item.label = modelData.l; item.val = modelData.v; item.bc = modelData.c; item.tc = modelData.tc; item.clicked.connect(function() { if (item.val === "C") clearAll(); else if (item.val === "\u00B1") negate(); else if (item.val === "%") percent(); else operator(item.val) }) } } } }
        Row { width: parent.width; spacing: 4; Repeater { model: [{l:"7",v:"7"},{l:"8",v:"8"},{l:"9",v:"9"},{l:"\u00D7",v:"\u00D7",c:Qt.rgba(1.0,0.6,0.0,0.8),tc:"#FFFFFF"}]
          Loader { sourceComponent: btnCmp; onLoaded: { item.label = modelData.l; item.val = modelData.v; item.bc = modelData.c || Qt.rgba(0.2,0.2,0.2,0.6); item.tc = modelData.tc || OpenUI.onSurface; item.clicked.connect(function() { if (["+","-","\u00D7","\u00F7"].indexOf(item.val) >= 0) operator(item.val); else digit(item.val) }) } } } }
        Row { width: parent.width; spacing: 4; Repeater { model: [{l:"4",v:"4"},{l:"5",v:"5"},{l:"6",v:"6"},{l:"-",v:"-",c:Qt.rgba(1.0,0.6,0.0,0.8),tc:"#FFFFFF"}]
          Loader { sourceComponent: btnCmp; onLoaded: { item.label = modelData.l; item.val = modelData.v; item.bc = modelData.c || Qt.rgba(0.2,0.2,0.2,0.6); item.tc = modelData.tc || OpenUI.onSurface; item.clicked.connect(function() { if (["+","-","\u00D7","\u00F7"].indexOf(item.val) >= 0) operator(item.val); else digit(item.val) }) } } } }
        Row { width: parent.width; spacing: 4; Repeater { model: [{l:"1",v:"1"},{l:"2",v:"2"},{l:"3",v:"3"},{l:"+",v:"+",c:Qt.rgba(1.0,0.6,0.0,0.8),tc:"#FFFFFF"}]
          Loader { sourceComponent: btnCmp; onLoaded: { item.label = modelData.l; item.val = modelData.v; item.bc = modelData.c || Qt.rgba(0.2,0.2,0.2,0.6); item.tc = modelData.tc || OpenUI.onSurface; item.clicked.connect(function() { if (["+","-","\u00D7","\u00F7"].indexOf(item.val) >= 0) operator(item.val); else digit(item.val) }) } } } }
        Row { width: parent.width; spacing: 4
          Rectangle { width: (parent.width - 12) / 4 * 2 + 4; height: 48; radius: 24; color: b0h.hovered ? Qt.rgba(0.2,0.2,0.2,0.8) : Qt.rgba(0.2,0.2,0.2,0.6); scale: b0h.pressed ? 0.94 : 1.0; Behavior on scale { NumberAnimation { duration: 60 } }
            Text { anchors.centerIn: parent; text: "0"; color: OpenUI.onSurface; font.pixelSize: 20 }; MouseArea { id: b0h; anchors.fill: parent; hoverEnabled: true; onClicked: digit("0") } }
          Rectangle { width: (parent.width - 12) / 4; height: 48; radius: 24; color: dh.hovered ? Qt.rgba(0.2,0.2,0.2,0.8) : Qt.rgba(0.2,0.2,0.2,0.6); scale: dh.pressed ? 0.94 : 1.0; Behavior on scale { NumberAnimation { duration: 60 } }
            Text { anchors.centerIn: parent; text: "."; color: OpenUI.onSurface; font.pixelSize: 20 }; MouseArea { id: dh; anchors.fill: parent; hoverEnabled: true; onClicked: digit(".") } }
          Rectangle { width: (parent.width - 12) / 4; height: 48; radius: 24; color: eqh.hovered ? Qt.rgba(1.0,0.7,0.0,0.9) : Qt.rgba(1.0,0.6,0.0,0.8); scale: eqh.pressed ? 0.92 : 1.0; Behavior on scale { NumberAnimation { duration: 60 } }
            Text { anchors.centerIn: parent; text: "="; color: "#FFFFFF"; font.pixelSize: 22 }; MouseArea { id: eqh; anchors.fill: parent; hoverEnabled: true; onClicked: equals() } } } }
      // 历史记录
      Rectangle { width: parent.width; height: 18; visible: history.length > 0; color: "transparent"
        Text { anchors.left: parent.left; text: history[history.length - 1]; color: OpenUI.onSurfaceDisabled; font.pixelSize: 10; elide: Text.ElideRight; width: parent.width } } } } }