const { MarkdownView, Plugin } = require("obsidian");

const CHORD_MS = 1000;

function typingTarget(target) {
  if (!(target instanceof HTMLElement)) return false;
  return Boolean(
    target.closest("input, textarea, select, [contenteditable='true']")
  );
}

function scrollBy(el, top, left) {
  el?.scrollBy({ top, left });
}

function scrollPage(el, direction) {
  if (!el) return;
  el.scrollBy({ top: el.clientHeight * direction });
}

function scrollEdge(el, top) {
  el?.scrollTo({ top });
}

module.exports = class ReadingVimPlugin extends Plugin {
  onload() {
    this.chord = "";
    this.timer = null;
    const onKeydown = (evt) => this.onKeydown(evt);
    window.addEventListener("keydown", onKeydown, true);
    this.register(() => window.removeEventListener("keydown", onKeydown, true));
  }

  clearChord() {
    this.chord = "";
    if (this.timer) window.clearTimeout(this.timer);
    this.timer = null;
  }

  armChord(chord) {
    this.chord = chord;
    if (this.timer) window.clearTimeout(this.timer);
    this.timer = window.setTimeout(() => this.clearChord(), CHORD_MS);
  }

  surface() {
    const view = this.app.workspace.activeLeaf?.view;
    if (!view) return null;
    if (view instanceof MarkdownView && view.getMode() === "preview") {
      return view.previewMode?.containerEl ?? null;
    }
    if (view.getViewType?.() === "hearth-home-view") {
      const remembered = view.scrollEl;
      if (remembered?.isConnected) return remembered;
      return view.containerEl?.querySelector(".hearth-scroll") ?? view.containerEl ?? null;
    }
    return null;
  }

  run(id) {
    this.app.commands.executeCommandById(id);
  }

  terminalView(evt) {
    const view = this.app.workspace.activeLeaf?.view;
    if (!view?.containerEl?.contains(evt.target)) return null;
    const type = String(view.getViewType?.() ?? "");
    if (type.toLowerCase().includes("terminal")) return view;
    if (evt.target instanceof Element && evt.target.closest(".xterm")) return view;
    return null;
  }

  leaveTerminal(direction) {
    const active = document.activeElement;
    if (active instanceof HTMLElement) active.blur();
    this.run(`editor:focus-${direction}`);
  }

  onTerminalKey(evt) {
    const key = evt.key;
    if (this.chord === "C-q") {
      const direction = { h: "left", j: "bottom", k: "top", l: "right" }[key];
      this.clearChord();
      if (!direction) return;
      evt.preventDefault();
      evt.stopPropagation();
      this.leaveTerminal(direction);
      return;
    }
    if (evt.ctrlKey && key.toLowerCase() === "q") {
      evt.preventDefault();
      evt.stopPropagation();
      this.armChord("C-q");
    }
  }

  onKeydown(evt) {
    if (evt.metaKey || evt.altKey || evt.isComposing || evt.repeat) return;
    if (this.terminalView(evt)) {
      this.onTerminalKey(evt);
      return;
    }
    if (typingTarget(evt.target)) return;
    const scroll = this.surface();
    if (!scroll) return;

    const key = evt.key;
    if (this.chord === "C-q") {
      const direction = { h: "left", j: "bottom", k: "top", l: "right" }[key];
      this.clearChord();
      if (!direction) return;
      evt.preventDefault();
      evt.stopPropagation();
      this.run(`editor:focus-${direction}`);
      return;
    }
    if (this.chord === "g") {
      this.clearChord();
      if (key === "g") {
        evt.preventDefault();
        evt.stopPropagation();
        scrollEdge(scroll, 0);
        return;
      }
      if (key === "t" || key === "T") {
        evt.preventDefault();
        evt.stopPropagation();
        this.run(key === "t" ? "workspace:next-tab" : "workspace:previous-tab");
        return;
      }
      return;
    }
    if (this.chord === " ") {
      const command = {
        " ": "switcher:open",
        "/": "global-search:open",
        t: "workspace:new-tab",
        q: "workspace:close",
        Q: "workspace:undo-close-pane",
      }[key];
      this.clearChord();
      if (!command) return;
      evt.preventDefault();
      evt.stopPropagation();
      this.run(command);
      return;
    }

    if (evt.ctrlKey && key.toLowerCase() === "q") {
      evt.preventDefault();
      evt.stopPropagation();
      this.armChord("C-q");
      return;
    }
    if (evt.ctrlKey) {
      const distance = { d: 0.5, u: -0.5, f: 1, b: -1 }[key.toLowerCase()];
      if (distance) {
        evt.preventDefault();
        evt.stopPropagation();
        scrollPage(scroll, distance);
        return;
      }
      if (key.toLowerCase() === "o" || key.toLowerCase() === "i") {
        evt.preventDefault();
        evt.stopPropagation();
        this.run(key.toLowerCase() === "o" ? "app:go-back" : "app:go-forward");
      }
      return;
    }
    if (key === "g" || key === " ") {
      evt.preventDefault();
      evt.stopPropagation();
      this.armChord(key);
      return;
    }
    if (key === "j" || key === "k" || key === "h" || key === "l") {
      evt.preventDefault();
      evt.stopPropagation();
      const step = 64;
      if (key === "j") scrollBy(scroll, step, 0);
      if (key === "k") scrollBy(scroll, -step, 0);
      if (key === "h") scrollBy(scroll, 0, -step);
      if (key === "l") scrollBy(scroll, 0, step);
      return;
    }
    if (key === "G") {
      evt.preventDefault();
      evt.stopPropagation();
      scrollEdge(scroll, scroll.scrollHeight);
    }
  }
};
