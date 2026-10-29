# Changelog

What changed on the site, newest first. Every push to `main` goes live, so
there are no releases: changes collect under Unreleased until the site first
goes live, and from then on each heading is the date a change went live.

## Unreleased

- A new site, built by one Go program instead of Hugo: the home page, the
  log by year, each post with its references, "Linked from" and "Cite this
  post", threads, works, pages, a full-text Atom feed and a sitemap.
- Every post has a `cite.bib`, and the tags Google Scholar and Zotero read.
- A citation links to its reference, in the post's own list, with the reference
  as its tooltip; the reference links on to every post that cites the work.
- A post's own page gives its exact date, and when it was updated; the
  lists keep their seasons.
- Every heading in a post can be linked to, as `/log/<slug>/#<heading>`.
- A post can have a DOI, which its citation, `cite.bib` and citation tags
  then give.
- The author's ORCID iD, in the feed, the page's metadata and at the foot of
  every page; the feed also has each post's threads and the licence.
- Pages print well, or save as PDF: without the menu, with web links'
  addresses written out.
- A thread exists while a post uses it: publishing a post with a new one
  makes it, without editing `threads.toml`, which now only describes, orders
  or keeps a thread.
- A withdrawn post keeps its text, as a retracted article does, under a
  notice saying when it was withdrawn, and why.
- A post can be a draft first: at its address, but in none of the lists,
  the feed or the sitemap, until In the Open publishes it.
- The program is built on small-press, a library other sites share, with
  this site's own pages on top; the site it builds is the same, to the byte.
- "Cite this post" is a citation on a tint, selected whole at a click,
  ready to copy, with `cite.bib` and the BibTeX entry in one row under it,
  and buttons that copy the citation and the entry, where JavaScript runs.
- Code stands out from the text, on a tint of its own, and wraps on paper
  rather than being cut off.
- An image with a caption is a figure, the caption right under it.
- On paper, a reference and the citation give their addresses once.
- Under each post, links to the older and the newer one.
- A post with three sections or more has a table of contents: folded above
  the text, or fixed in place beside it on a wide screen.
- A reference's tooltip and citation tags keep its DOI.
