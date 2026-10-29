// Copy buttons for "Cite this post", in place of the row's "Click to
// select". The page needs none of this: without it, the citation still
// selects whole at a click, to copy by hand, and the BibTeX entry is in
// cite.bib. The entry is also in the page, hidden, for its button: the
// site's policy lets a page fetch nothing.
(() => {
  const cite = document.querySelector('section[aria-labelledby="cite"]');
  if (!cite || !navigator.clipboard) return;

  // button copies el, as formatted text where the browser can, so the
  // site's name stays in italics, and as plain text otherwise. It says
  // whether it did for a moment, then goes back to its label.
  const button = (el, label, formatted) => {
    const b = document.createElement("button");
    b.type = "button";
    b.className = "copy";
    b.textContent = label;
    b.addEventListener("click", async () => {
      const text = el.textContent.trim();
      try {
        if (formatted && window.ClipboardItem) {
          await navigator.clipboard.write([
            new ClipboardItem({
              "text/html": new Blob([el.innerHTML], { type: "text/html" }),
              "text/plain": new Blob([text], { type: "text/plain" }),
            }),
          ]);
        } else {
          await navigator.clipboard.writeText(text);
        }
        b.textContent = "Copied";
      } catch {
        b.textContent = "Couldn’t copy";
      }
      setTimeout(() => (b.textContent = label), 2000);
    });
    return b;
  };

  const dot = document.createElement("span");
  dot.setAttribute("aria-hidden", "true");
  dot.textContent = "·";
  cite
    .querySelector(".select-hint")
    .replaceWith(
      button(cite.querySelector("p.citation"), "Copy citation", true),
      dot,
      button(cite.querySelector("pre.bibtex"), "Copy BibTeX", false),
    );
})();
