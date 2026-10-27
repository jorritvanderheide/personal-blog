# Architecture

This is a personal blog, in English. One Go program reads a folder of
Markdown and writes a folder of static files, which nginx serves. Posts are
written in Obsidian and arrive through the In the Open plugin, over Micropub,
with their citations already formatted; anything else in `content/` is
written by hand in the same format. [Publishing](publishing.md) describes the
receiver that takes its posts.

The site has no server program and no JavaScript. A blog only changes when
something is published, so everything a request could need is decided at
build time. The receiver is the one program that runs, and all it does is
turn a published post into a commit.

## Where things live

| Path | What it holds |
| --- | --- |
| `main.go` | Flags, and the three ways to run: build once, serve while you write, or receive posts. |
| `internal/content/` | Reading `content/`: front matter, Markdown, images. Nothing about HTML. |
| `internal/render/` | goldmark, its extensions, and the passes over each post's syntax tree. |
| `internal/site/` | The site as a whole: posts, threads, works, backlinks, and every check that needs more than one post. |
| `internal/build/` | Writing the output: pages, feed, sitemap, `cite.bib` files, images. |
| `internal/dither/` | Ordered dithering of images, as MeetINN's. |
| `internal/micropub/` | The receiver: Micropub requests in, commits out. |
| `web/` | Templates and static files, embedded with `embed.FS`. |
| `content/` | Posts and pages. The only input. |
| `flake.nix` | The two packages, `personal-blog` and `site`, and the module. |
| `nix/` | The NixOS module, and its VM test. |
| `docs/` | This, and the rest of the developer docs. |

`internal/content` and `internal/site` are pure: no filesystem except through
an `fs.FS` they are given, so every decision is tested on an in-memory site.

## Content

```
content/
  log/<slug>/index.md     a post, with its images next to it
  pages/<name>.md         about, colophon, library: pages outside the log
  works/<key>.toml        a work a post cites, formatted once
  threads.toml            each thread's name and description
  site.toml               the site's name, address, author, line and menu
```

Nothing else belongs in `content/`: anything else there fails the build, so
a file in the wrong place is found rather than left out. A slug, a page's
name and a thread's name are lowercase letters, digits and hyphens.

The directory name is the post's slug, and **a slug never changes**: people
cite the URL. A post that must move lists its old slugs under `aliases`, and
the old URL redirects to the new one for good.

A work's key is in its URL too, so **a key never changes** either. Keys are
pinned in Better BibTeX, not regenerated when a work's metadata changes.

### Front matter

TOML between `+++` lines, as on the old site.

```toml
+++
title = 'The NixOS module system is a quiet revolution'
summary = 'Why declarative configuration changes how we think about infrastructure.'
date = 2026-03-15T10:00:00Z
updated = 2026-04-02T09:00:00Z     # optional, when the text changed in substance
threads = ['tech']
aliases = []                       # optional, earlier slugs
generator = 'micropub'             # set by the receiver, absent on hand-written posts
references = ['marsh2020']         # keys of the works cited, in reference-list order
withdrawn = 2026-11-02T08:00:00Z   # optional, when the post was withdrawn
+++
```

- `title`, `summary` and `date` are required. A post without them fails the
  build, with the file and the field.
- `references` lists the key of every Zotero work the post cites, in the
  order of the reference list.
- `generator` marks what the receiver may replace or withdraw. It never
  touches a post without it.

### Works

Each work is formatted once, in `content/works/<key>.toml`, and every post
that cites it shares that one text:

```toml
text = 'Marsh, Ann. 2020. *Archives and Their Readers*. Leiden: Brill.'
url = 'https://doi.org/10.1163/example'   # optional
```

The text is formatted by pandoc's citeproc in the plugin. The site never
formats a citation itself: one style, decided where the bibliography is. The
receiver rewrites a work's file each time it takes a post that cites it, so
correcting a work in Zotero and republishing any one post corrects it
everywhere.

### The body

CommonMark with GFM tables, strikethrough and footnotes. Two kinds of link
have a meaning of their own:

- **A link to another post**, `/log/<slug>/`, is an ordinary link. The site
  reads every such link to build backlinks, so there is nothing to keep in
  step by hand.
- **A citation** is a link to `/works/<key>/` with the in-text form as its
  words: `[(Marsh 2020, 12)](/works/marsh2020/)`. Every
  key cited in the body is in `references`, every key in `references` is
  cited and has a file in `content/works/`, or the build fails.

Every other link is just a link. Further reading, a web page that isn't
cited, goes in the body as a list of links under its own heading:
`references` is only for works the post cites.

Images are Markdown images of files in the post's folder.

## Pages and files

| URL | What it is |
| --- | --- |
| `/` | The newest posts, and what the site is. |
| `/log/` | Every post, newest first, grouped by year. |
| `/log/<slug>/` | A post: its text, references, "Linked from", and "Cite this post". |
| `/log/<slug>/cite.bib` | The post as a BibTeX entry. |
| `/threads/<thread>/` | The posts in a thread, under its description. |
| `/works/<key>/` | A work you cited: its reference, and every post that cites it. |
| `/<name>/` | A page from `content/pages/`. |
| `/feed.xml` | Atom, every post in full. |
| `/sitemap.xml`, `/robots.txt`, `/404.html` | As the names say. |

### A post

From top to bottom:

1. The title, the date as a season (*early spring 2026*, the exact date in
   `<time datetime>`), and its threads.
2. The text, with footnotes.
3. **References**: `references` in order, each with an `id` the in-text
   citations' tooltips and the works page can point to.
4. **Linked from**: every post whose body links to this one, newest first.
   Left out when there is none.
5. **Cite this post**: one formatted citation, in a fixed author-date form,
   and the BibTeX entry in a `<details>`, with a link to `cite.bib`.

### A withdrawn post

A post is withdrawn, never deleted: other posts link to it, and people may
have cited it. A withdrawn post keeps its URL and its `cite.bib`, but its
page shows only the title, the date, and when it was withdrawn, with
`noindex` for search engines. It is served as any page is, with `200`: a
DOI's landing page has to keep answering, as a journal's tombstone page
does. It leaves `/log/`, its threads, the feed, the sitemap, and every
"Linked from" and works page. Links to it still build, and lead to that
page.

Taking a post down for good, for legal or privacy reasons, is done by hand:
delete its folder, and the build names every post that still links to it.

### Being cited

Making a post easy to cite is a feature of every page, not a page of its own.

- **Citation tags in the head:** `citation_title`, `citation_author`,
  `citation_publication_date`, `citation_public_url` and the rest of the
  Highwire set, which Google Scholar reads and Zotero's connector saves with
  one click, with Jorrit van der Heide as the author. Also schema.org
  `BlogPosting` as JSON-LD, and Open Graph.
- **`cite.bib`** next to each post, and the same entry on the page.
- **Stable URLs**, by the rule above, and a canonical link on every page.
- **The feed has every post in full**, with a stable `<id>` per post, which is
  what [Rogue Scholar](https://rogue-scholar.org) needs to archive the blog
  and give each post a DOI. Joining it is a later choice; nothing here stops
  it.
- **Posts are under CC BY 4.0**, as Rogue Scholar asks. The code is
  EUPL-1.2.

## Time

A Nix build is pure, and the same inputs give the same site. So "now" is not
the clock: it is the time of the last commit, passed in with `-now` (the
flake's `lastModified`). Everything that depends on time uses it:

- **Fading.** A post more than a year older than now is *aging*, more than
  three years *faded*, as on the old site. Posts no longer expire: a citation
  has to keep working.
- **The build number** at the foot of every page is the commit count
  (`revCount`), so there is no counter file to commit.

A post fades when the site is next published, not on the day itself. That is
the price of a reproducible build, and on a blog it is a small one.

## Rules

- **No JavaScript.** Folding is `<details>`, dark mode is
  `prefers-color-scheme`, and nginx's policy (`default-src 'none'`) makes it
  stick. The one `<script>` is a post's JSON-LD, which is data: no browser
  runs it.
- **A broken site does not build.** A link to a post that does not exist, a
  citation without a reference, a reference never cited, a reference with no
  work in `content/works/`, a thread not in `threads.toml`, a duplicate slug
  or alias: each fails the build with the file it is in.
- **Rendered into memory, written at the end.** A template error never
  leaves half a site in the output.
- **Links are safe.** Only `http`, `https`, `mailto` and site-relative links
  are written; raw HTML in Markdown stays off.
- **Images are dithered at build time** into 6-grey paletted PNGs no wider
  than 800 pixels, with ordered Bayer dithering. The originals stay in
  `content/`; nothing derived is committed.
- **Assets carry their hash** (`/static/site.css?v=1a2b3c4d`) and are cached
  for a year; HTML is revalidated.
- **CSS is written by hand**, with no build step: custom properties, mobile
  first, `:focus-visible`, `prefers-reduced-motion`.
- **Accessible by default:** a skip link, `aria-current` in the menu, a
  heading order that holds, alt text required on every image.

## Running

```sh
nix run .#dev        # serve on localhost:8080, rebuilt on every request, templates from disk
nix build            # the site, in ./result
nix flake check      # the checks, the real content's build, and the VM test
./check.sh           # gofmt, go vet, go test, staticcheck, govulncheck
```

`check.sh` is what Forgejo CI runs, so a local run and CI cannot disagree.

The flake builds two packages. `personal-blog` is the program, from
everything but `content/`, so a commit that only adds or changes posts finds
it in the store already and builds in seconds. `site` is that program run
over `content/`. A Nix build is pure, so it dithers every image again each
time.

## Deployment

`nix/module.nix` is `services.personal-blog`, which the flake exports as
`nixosModules.default` for the host's own configuration to import. It needs
nothing built: it serves, and runs, what its deploy builds.

**The deploy** (`personal-blog-deploy`) builds the site on the host. A timer
asks the repository for the newest commit on `main` with `git ls-remote`, a
minute after it last looked, and when that commit is new, builds `site` and
then `personal-blog` from it, as links in `/var/lib/personal-blog`. Each link
moves in one step when its build is done; the site first, which the program
is part of, so a commit that doesn't build changes nothing.

- **Every push publishes**, from the receiver or from a laptop alike, within
  a minute and a build.
- **A broken commit never goes live.** The site already there stays, and the
  units in `deploy.onFailure` are started, once: the deploy doesn't try that
  commit again. To try it anyway, remove `/var/lib/personal-blog/failed`.
- **A forge that doesn't answer** is asked again at the next look, without a
  failure.
- **The host's configuration only changes with the module.** Posts,
  templates and the Go code all come with the build; only a change to nginx
  or systemd needs a rebuild of the host.
- **The fetch has the whole history**, so `lastModified` and `revCount` are
  always there for [Time](#time).
- **After a deploy**, nginx reads the build's includes again, and the
  receiver restarts with the program just built, so it checks posts by the
  same rules as the build that will publish them.

**nginx** serves `/var/lib/personal-blog/site` at `bw20.nl`, with the old
site's rules:

- Security headers, with a content security policy that allows no scripts.
- AI crawlers kept out twice: in `robots.txt`, and with a 403 for the same
  user agents, read from one list.
- Aliases as permanent redirects.
- No access log.
- TLS is the host's.

What depends on the content, the redirects and the crawlers' 403, the build
writes as nginx includes, in `nginx/server/` and `nginx/location/` of the
site. The module includes them by glob, so nginx starts before the first
deploy, when there is no site yet.

`services.personal-blog.receiver` adds the receiver, as
[Publishing](publishing.md) describes.

`nix/test.nix` starts it in a VM, without the network, and deploys from a
repository on the VM: a first commit, nginx serving it with its headers, a
redirect, the 403 and the 404, a commit that doesn't build and fails once,
and one that builds again. Until there is a program, the blog in it is a
stand-in (`nix/test/`) that writes what the real build will. Once there is,
the test deploys the real one, and sends the receiver a post that has to
arrive as a commit.

## What comes from where

- **From the old site:** no JavaScript, dates as seasons, fading, dithered
  images, the build number, bot blocking, the hardened nginx module and its
  VM test, threads.
- **From MeetINN:** `html/template` with `embed.FS` and templates from disk
  in development, hashed asset URLs, rendering into memory first, goldmark
  with passes over the syntax tree, safe links, the dithering, `check.sh` for
  CI and local runs alike, and docs that write the rules down.
- **New:** citations and references from the plugin, publishing over
  Micropub, works pages, backlinks, citation tags, `cite.bib`, a full-text
  feed, withdrawn posts, and slugs that never change.
