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
2. The text, with footnotes.
3. **References**: `references` in order, each with `id="ref-<key>"`, which
   the in-text citations link to, with the reference as their tooltip. Each
   links on to its work's page, with every post that cites it.
4. **Linked from**: every post whose body links to this one, newest first.
   Left out when there is none.
5. **Cite this post**: one formatted citation, in a fixed author-date form,
   and the BibTeX entry in a `<details>`, with a link to `cite.bib`. With
   a DOI, the citation and the entry give the DOI rather than the address.

A heading in a post can't have the id of one of the page's own sections,
`references`, `linked-from` or `cite` (`sections` in `pages.go`): the build
fails on it.

### How they look

- **No JavaScript.** Folding is `<details>`, dark mode is
  `prefers-color-scheme`.
- **CSS is written by hand**, with no build step: custom properties, mobile
  first, `:focus-visible`, `prefers-reduced-motion`, and print. A page
  prints as it should: the text, its references and how to cite it, without
  the menu, and with each web link's address after it.
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
doesn't see it. To move to a new commit of small-press, as its
[Sites](https://codeberg.org/BW20/small-press/src/branch/main/docs/sites.md)
page says: `GOWORK=off go get codeberg.org/BW20/small-press@main`, then the
`vendorHash` in `nix/package.nix` that `nix build .#program` gives.

## Deployment

dapple serves the site as `services.small-press.sites.bw20`, at `bw20.nl`,
from this repository, as small-press's
[Deployment](https://codeberg.org/BW20/small-press/src/branch/main/docs/architecture.md#deployment)
describes. Every push to `main` goes live once it builds; the receiver
pushes there too, each time a post is published.
