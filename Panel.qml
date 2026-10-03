import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "paulhocker.omarchy-plugin-chuck"

  property var joke: ({ value: "", categories: [] })
  property bool loading: false

  // ─── Fetch joke from API ──────────────────────────────────────────

  Process {
    id: jokeProc
    command: ["curl", "-fsS", "--max-time", "5",
      "https://api.chucknorris.io/jokes/random"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").trim()
        root.loading = false
        if (!raw) return
        try {
          var data = JSON.parse(raw)
          root.joke = {
            value: data.value || "",
            categories: data.categories || []
          }
        } catch (e) {}
      }
    }
    onRunningChanged: {
      if (running) root.loading = true
    }
  }

  // ─── Periodic refresh (every 5 minutes) ───────────────────────────

  Timer {
    id: refreshTimer
    interval: 300000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: jokeProc.running = true
  }

  // ─── Refresh on open ──────────────────────────────────────────────

  onOpenedChanged: {
    if (opened) jokeProc.running = true
  }

  function refresh() {
    jokeProc.running = true
  }

  // ─── Bar icon (hover shows joke, click opens popup) ──────────────

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    iconComponent: Image {
      source: Qt.resolvedUrl("chuck-norris.png")
      fillMode: Image.PreserveAspectFit
      sourceSize: Qt.size(36, 36)
    }
    tooltipText: root.loading ? "Loading joke..." : (root.joke.value || "Chuck Norris")
    onPressed: function(b) {
      if (b === Qt.RightButton) root.refresh()
      else root.toggle()
    }
  }

  // ─── Popup panel ──────────────────────────────────────────────────

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    centerOnBar: true
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(column.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(dir) {}

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(14)

        Image {
          source: Qt.resolvedUrl("chuck-norris.png")
          width: Style.space(48)
          height: Style.space(48)
          fillMode: Image.PreserveAspectFit
          sourceSize: Qt.size(96, 96)
          anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
          text: {
            if (root.loading) return "Loading..."
            if (root.joke.value) return root.joke.value
            return "No joke loaded. Click to fetch one."
          }
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.title
          wrapMode: Text.Wrap
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          visible: root.joke.categories && root.joke.categories.length > 0
          text: root.joke.categories.join(", ")
          color: Qt.darker(root.bar ? root.bar.foreground : Color.foreground, 1.3)
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.body
          font.italic: true
          width: parent.width
          horizontalAlignment: Text.AlignHCenter
        }

        Text {
          text: "↻ Refresh"
          color: root.bar ? root.bar.foreground : Color.foreground
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          opacity: 0.6
          width: parent.width
          horizontalAlignment: Text.AlignHCenter

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.refresh()
          }
        }
      }
    }
  }
}
