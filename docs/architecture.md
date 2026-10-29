# Architecture

This is a personal blog, in English, built with
[small-press](https://codeberg.org/BW20/small-press). small-press is the
library: the content's format, every check, the addresses, the feed and
the other files that aren't pages, the receiver that takes posts from In
the Open, and the NixOS module. Its
[architecture](https://codeberg.org/BW20/small-press/src/branch/main/docs/architecture.md)
is the spec for all of that, and this site keeps its rules. This page is
what is this site's own: its program, its pages, and how they look.

## Where things live

| Path | What it holds |
| --- | --- |
| `main.go` | The program: small-press's `Main`, with this site's pages. |
| `pages.go` | The pages the site has, and what each template gets. |
| `pages_test.go` | The pages' tests, on an in-memory site. |
| `web/` | Templates and the stylesheet, embedded with `embed.FS`. |
| `content/` | Posts and pages. The only input. |
| `flake.nix` | The two packages the deploy builds, `program` and `site`. |
| `nix/` | Those two packages. |
| `docs/` | This. |

## Pages

The pages are those of small-press's example, which this site started as:
the home page with the five newest posts, the log by year, a page for each
post, thread, work and page in `content/pages/`, and the 404 page. The
lists give a post's date as a season, *early spring 2026*.

### A post

From top to bottom:

1. The title, the exact date (*15 March 2026*, in `<time datetime>`), when
   it was updated, if it was, and its threads. A reader citing it needs the
   date as it is.
2. **Contents**, for a post with three sections (`##`) or more: a link to
   the top of the page and to each section, then to References and Cite
   this post. Folded above the text, or, where the screen is wide enough,
   in a column beside it, fixed in place as the page scrolls; the page has
   both, and shows one. It isn't printed.
3. The text, with footnotes, then a thin rule, as the footnotes have above
   them, to set it apart from the sections that follow.
4. **References**: `references` in order, each with `id="ref-<key>"`, which
   the in-text citations link to, with the reference as their tooltip. Each
   links on to its work's page, with every post that cites it.
5. **Linked from**: every post whose body links to this one, newest first.
   Left out when there is none.
6. **Cite this post**, after another thin rule when References or Linked
   from come before it: one formatted citation, in a fixed author-date
   form, on a tint, and one quiet row under it: "Click to select", as the
   citation selects whole at a click, and a link to `cite.bib`, the BibTeX
   entry. With a DOI, the citation and the entry give the DOI rather than
   the address. `copy.js` puts a copy icon in the top right corner of the
   citation, which copies it formatted, so the site's name stays in
   italics, and as plain text; and "Copy BibTeX" in place of "Click to
   select", from the entry, which the page has hidden, as the site's
   policy lets a page fetch nothing.
7. **Older and newer**: links to the posts either side of it in the log,
   the older on the left. A draft or a withdrawn post isn't in the log, so
   it has none. They aren't printed.

A heading in a post can't have the id of one of the page's own sections,
`references`, `linked-from` or `cite` (`sections` in `pages.go`): the build
fails on it.

### How they look

- **JavaScript only adds.** Every page works without it: folding is
  `<details>`, dark mode is `prefers-color-scheme`. The one script,
  `web/static/copy.js`, is loaded on a post's page only, and adds copy
  buttons: an icon in the top right corner of each code block and of the
  citation, and "Copy BibTeX". Without it, code is selected by hand, the
  citation still selects whole at a click and the entry is in `cite.bib`.
  small-press's policy runs the site's own script files and nothing else.
- **CSS is written by hand**, with no build step: custom properties, mobile
  first, `:focus-visible`, `prefers-reduced-motion`, and print. A page
  prints as it should: the text, its references and how to cite it, without
  the menu, with each web link's address after it, except in the
  references and the citation, which write their addresses out already,
  and code wrapped rather than cut off.
- **Accessible by default:** a skip link, `aria-current` in the menu, a
  heading order that holds, alt text required on every image.
- **The author's ORCID iD** is linked at the foot of every page, with the
  licence, CC BY 4.0, the feed, and the build number.

## Running

```sh
nix run .#dev        # serve on localhost:8080, rebuilt on every request, templates from disk
nix build            # the site, in ./result
nix flake check      # the program, its tests, and the real content's build
./check.sh           # gofmt, go vet, go test, staticcheck, govulncheck
```

`check.sh` and `nix flake check` are what CI runs, on the Forgejo runner on
dapple. A push that only changes `content/`, as every post published from
Obsidian is, isn't checked by CI: the receiver ran the site's checks before
committing it, and the deploy builds it, alerting when it fails.

The flake builds two packages. `program` is the program, from everything
but `content/`, so a commit that only adds or changes posts finds it in the
store already and builds in seconds. `site` is that program run over
`content/`.

small-press comes as `go.mod` pins it. To work on both at once, a `go.work`
next to `go.mod`, ignored by `.gitignore`, uses `../small-press`; Nix
doesn't see it. To move to a new release of small-press, as its
[Sites](https://codeberg.org/BW20/small-press/src/branch/main/docs/sites.md)
page says: `GOWORK=off go get codeberg.org/BW20/small-press@v<version>` and
`GOWORK=off go mod tidy`, then `vendorHash` in `nix/package.nix` set to
`lib.fakeHash` and to what `nix build .#program` gives, and `./check.sh`
and `nix flake check`.

## Deployment

dapple serves the site as `services.small-press.sites.bw20`, at `bw20.nl`,
from this repository, as small-press's
[Deployment](https://codeberg.org/BW20/small-press/src/branch/main/docs/architecture.md#deployment)
describes. Every push to `main` goes live once it builds; the receiver
pushes there too, each time a post is published.
