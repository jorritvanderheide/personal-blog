# personal-blog

**A personal blog in English, written in Obsidian and built to be cited.**

One Go program reads a folder of Markdown and writes a static site, which
nginx serves. Posts are written in Obsidian and published with the
[In the Open](https://codeberg.org/BW20/obsidian-in-the-open) plugin, over
Micropub, with their citations already formatted. The program is built on
[small-press](https://codeberg.org/BW20/small-press), with this site's own
pages. See [Running it](#1-running-it).

<br/>

[![License: EUPL-1.2](https://img.shields.io/badge/license-EUPL--1.2-blue?style=flat-square)](LICENSE)

<!-- SCREENSHOT images/hero.png: a post, with its citations, references, "Linked from" and "Cite this post" -->

A blog post that cites its sources should be as easy to cite as a paper. Each
post here has its references, formatted once, in one style, and a page for
every work it cites, with every post that cites it. It carries the tags
Google Scholar and Zotero read, a BibTeX entry, and an address that never
changes.

The rest stays small. There's no JavaScript and no server program for
visitors: a blog only changes when something is published, so every page is
decided when the site is built. Images are dithered, and posts don't go
away, because a citation has to keep working.

<br/>

## 1 Running it

**On a server**, the site runs on NixOS from small-press's module:
`services.small-press.sites`, nginx serving the site, which the host builds
itself from every push. See [Deployment](docs/architecture.md#deployment).

**To work on it**, `nix develop` gives everything, and `nix run .#dev` serves
the site on <http://localhost:8080>, rebuilt on every request. See
[Running](docs/architecture.md#running).

<br/>

## 2 Publishing

Posts are written in Obsidian, and the In the Open plugin sends them to the
site's receiver, which commits them to this repository. A post is published
when the host has built that commit. A post can be sent as a draft first,
to see it on the site before anyone else does. A post can be withdrawn, but
never deleted: its address keeps working.

The plugin speaks [Micropub](https://www.w3.org/TR/micropub/), with one small
extension for references, so it isn't tied to this site. To make your own
site take its posts, see its
[Micropub](https://codeberg.org/BW20/obsidian-in-the-open/src/branch/main/docs/micropub.md)
page.

<br/>

## 3 Privacy

- **No JavaScript**, and a content security policy that allows none.
- **No cookies**, and no access log.
- **AI crawlers are kept out**, in `robots.txt` and with a 403.

<br/>

## 4 Documentation

For whoever works on the site:

- [**Architecture**](docs/architecture.md) - What is this site's own: its
  program, its pages and how they look, and how it moves to a new commit of
  small-press.
- [**small-press**](https://codeberg.org/BW20/small-press) - The rest: the
  content's format, the rules the build keeps to, the receiver that takes a
  post from In the Open, and deployment.

<br/>

## 5 License

The code is licensed under the [EUPL-1.2](LICENSE). The posts are licensed
under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

This is one person's site, public to read and reuse under those licences,
but not a project: there's no support, and issues and pull requests aren't
taken.
