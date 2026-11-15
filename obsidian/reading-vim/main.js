const { MarkdownView, Plugin } = require("obsidian");

const CHORD_MS = 1000;

function typingTarget(target) {
  if (!(target instanceof HTMLElement)) return false;
  return Boolean(
    target.closest("input, textarea, select, [contenteditable='true']")
  );
}

function scroller(view) {
  return view.previewMode?.containerEl ?? null;
}

function scrollBy(view, top, left) {
  const el = scroller(view);
  if (!el) return;
  el.scrollBy({ top, left });
}

function scrollPage(view, direction) {
  const el = scroller(view);
  if (!el) return;
  el.scrollBy({ top: el.clientHeight * direction });
}

function scrollEdge(view, top) {
  const el = scroller(view);
  if (!el) return;
  el.scrollTo({ top });
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

  previewView() {
    const view = this.app.workspace.getActiveViewOfType(MarkdownView);
    if (!view || view.getMode() !== "preview") return null;
    return view;
  }

  run(id) {
    this.app.commands.executeCommandById(id);
  }

  onKeydown(evt) {
    if (evt.metaKey || evt.altKey || evt.isComposing || evt.repeat) return;
    if (typingTarget(evt.target)) return;
    const view = this.previewView();
    if (!view) return;

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
        scrollEdge(view, 0);
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
        scrollPage(view, distance);
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
      if (key === "j") scrollBy(view, step, 0);
      if (key === "k") scrollBy(view, -step, 0);
      if (key === "h") scrollBy(view, 0, -step);
      if (key === "l") scrollBy(view, 0, step);
      return;
    }
    if (key === "G") {
      evt.preventDefault();
      evt.stopPropagation();
      const el = scroller(view);
      if (el) scrollEdge(view, el.scrollHeight);
    }
  }
};
