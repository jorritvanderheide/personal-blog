// Copy buttons on a post's page: an icon in the top right corner of each
// code block and of the citation, and "Copy BibTeX" in place of the cite
// row's "Click to select". The page needs none of this: without it, the
// citation still selects whole at a click, to copy by hand, and the BibTeX
// entry is in cite.bib. The entry is also in the page, hidden, for its
// button: the site's policy lets a page fetch nothing.
(() => {
  const article = document.querySelector("article");
  if (!article || !navigator.clipboard) return;

  const icon = {
    copy: '<svg viewBox="0 0 24 24" aria-hidden="true"><rect x="9" y="9" width="11" height="11" rx="2"/><path d="M15 9V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v7a2 2 0 0 0 2 2h3"/></svg>',
    done: '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
  };

  // copy puts text on the clipboard, and html beside it where the browser
  // can, so a citation pasted into a document keeps its italics.
  const copy = async (text, html) => {
    if (html && window.ClipboardItem) {
      await navigator.clipboard.write([
        new ClipboardItem({
          "text/html": new Blob([html], { type: "text/html" }),
          "text/plain": new Blob([text], { type: "text/plain" }),
        }),
      ]);
    } else {
      await navigator.clipboard.writeText(text);
    }
  };

  // button copies what what() gives, and says for two seconds whether it
  // did: in words, or as an icon, a tick when done, with its label as its
  // name and tooltip.
  const button = (label, what, iconic) => {
    const b = document.createElement("button");
    b.type = "button";
    b.className = iconic ? "copy-icon" : "copy";
    const say = (words, shape) => {
      if (iconic) {
        b.innerHTML = icon[shape];
        b.setAttribute("aria-label", words);
        b.title = words;
      } else {
        b.textContent = words;
      }
    };
    say(label, "copy");
    b.addEventListener("click", async () => {
      try {
        await copy(...what());
        say("Copied", "done");
      } catch {
        say("Couldn’t copy", "copy");
      }
      setTimeout(() => say(label, "copy"), 2000);
    });
    return b;
  };

  // corner puts an icon button in the top right corner of el. Both go in a
  // box of their own, so the icon stays put when a long line of code
  // scrolls sideways.
  const corner = (el, label, what) => {
    const box = document.createElement("div");
    box.className = "copyable";
    el.before(box);
    box.append(el, button(label, what, true));
  };

  for (const pre of article.querySelectorAll("pre:not([hidden])")) {
    corner(pre, "Copy code", () => [pre.textContent.replace(/\n$/, "")]);
  }

  const cite = article.querySelector('section[aria-labelledby="cite"]');
  const citation = cite.querySelector("p.citation");
  corner(citation, "Copy citation", () => [citation.textContent.trim(), citation.innerHTML]);
  const bibtex = cite.querySelector("pre.bibtex");
  cite
    .querySelector(".select-hint")
    .replaceWith(button("Copy BibTeX", () => [bibtex.textContent.trim()], false));
})();
