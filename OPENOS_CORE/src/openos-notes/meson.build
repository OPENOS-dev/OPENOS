# openos-notes — 独立便签 App
project('openos-notes', 'cpp',
  version: 'DEV2026.1',
  default_options: ['cpp_std=c++17'])
qt6 = import('qt6')
qt6_dep = dependency('qt6', modules: ['Core', 'Gui', 'Qml', 'Quick'])
qt6_res = qt6.preprocess(qresources: 'qml.qrc')
executable('openos-notes',
  sources: ['main.cpp', qt6_res],
  dependencies: [qt6_dep],
  install: true)