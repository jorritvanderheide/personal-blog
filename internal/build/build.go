// Package build makes the site from what package site put together: every
// page, the feed, the sitemap, each post's cite.bib and images, the
// stylesheet, and the files nginx includes. Everything is rendered into
// memory first, and written to disk only when all of it is, so an error never
// leaves half a site behind.
package build

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"html/template"
	"io/fs"
	"os"
	"path"
	"path/filepath"
	"strings"
	"time"

	"codeberg.org/BW20/personal-blog/internal/dither"
	"codeberg.org/BW20/personal-blog/internal/render"
	"codeberg.org/BW20/personal-blog/internal/site"
)

// Files is the site: each file's path, relative to the site's root, and its
// contents.
type Files map[string][]byte

// Options are what a build takes besides the content.
type Options struct {
	// Build is the build number at the foot of every page, the commit count.
	// 0 leaves it out.
	Build int
}

// ImageWidth is the widest an image is written.
const ImageWidth = 800

// The templates each kind of page is made of, in web/templates/, on top of
// base.html and posts.html.
var kinds = []string{"home", "log", "post", "thread", "work", "page", "404"}

// page is what a template gets: the site, the page's own facts, and the
// fields of its kind.
type page struct {
	Site        *site.Site
	Path        string // where the page is, for its canonical link and the menu
	Title       string // without the site's name; "" on the home page
	Description string
	NoIndex     bool
	Build       int
	CSS         string // the stylesheet's address, with its hash

	Posts      []*site.Post
	Years      []year
	Post       *site.Post
	Text       template.HTML
	References []reference
	Cite       template.HTML
	BibTeX     string
	JSONLD     map[string]any
	Thread     *site.Thread
	Work       *site.Work
	WorkText   template.HTML
	WorkURL    string // where the work is, when its reference doesn't say
	Page       *site.Page
}

type year struct {
	Year  int
	Posts []*site.Post
}

type reference struct {
	Key   string
	Text  template.HTML
	Plain string
	URL   string
}

// Site builds every file, with the templates, stylesheet and crawler list in
// assets (package web, or web/ on disk in development).
func Site(s *site.Site, assets fs.FS, o Options) (Files, error) {
	files := Files{}
	var errs []error
	fail := func(name string, err error) { errs = append(errs, fmt.Errorf("%s: %w", name, err)) }

	css, err := fs.ReadFile(assets, "static/site.css")
	if err != nil {
		return nil, err
	}
	files["static/site.css"] = css
	sum := sha256.Sum256(css)
	cssPath := "/static/site.css?v=" + hex.EncodeToString(sum[:4])

	list, err := fs.ReadFile(assets, "crawlers.txt")
	if err != nil {
		return nil, err
	}
	names, err := crawlers(list)
	if err != nil {
		return nil, err
	}
	files["robots.txt"] = robots(s, names)
	files["nginx/location/crawlers.conf"] = crawlerBlock(names)
	if len(s.Aliases) > 0 {
		files["nginx/server/aliases.conf"] = aliasRedirects(s)
	}

	funcs := template.FuncMap{
		"season": season,
		"iso":    func(t time.Time) string { return t.Format("2006-01-02") },
		// The exact date, on a post's own page, where a reader citing it needs it.
		"date":  func(t time.Time) string { return t.Format("2 January 2006") },
		"stamp": func(t time.Time) string { return t.Format(stamp) },
		"abs":   func(p string) string { return s.Config.URL + p },
		// A menu entry is the current one on its page and the pages under
		// it: the log's on every post.
		"current": func(link, at string) bool { return link == at || link != "/" && strings.HasPrefix(at, link) },
	}
	templates := map[string]*template.Template{}
	for _, kind := range kinds {
		t, err := template.New(kind).Funcs(funcs).ParseFS(assets, "templates/base.html", "templates/posts.html", "templates/"+kind+".html")
		if err != nil {
			return nil, err
		}
		templates[kind] = t
	}
	write := func(name, kind string, p page) {
		p.Site, p.Build, p.CSS = s, o.Build, cssPath
		var buf bytes.Buffer
		if err := templates[kind].ExecuteTemplate(&buf, "base", p); err != nil {
			fail(name, err)
			return
		}
		files[name] = buf.Bytes()
	}

	var live []*site.Post
	for _, p := range s.Posts {
		if p.Live() {
			live = append(live, p)
		}
	}
	write("index.html", "home", page{Path: "/", Description: s.Config.Description, Posts: live[:min(len(live), 5)]})
	write("log/index.html", "log", page{Path: "/log/", Title: "Log", Description: "Every post, newest first.", Years: byYear(live)})
	write("404.html", "404", page{Path: "/404.html", Title: "Not here", Description: s.Config.Description, NoIndex: true})

	for _, p := range s.Posts {
		dir := path.Join("log", p.Slug)
		files[path.Join(dir, "cite.bib")] = []byte(bibtex(s.Config, p))
		images, err := writeImages(files, dir, p)
		if err != nil {
			fail(path.Join(dir, "index.md"), err)
			continue
		}
		text, err := postText(s, p, images)
		if err != nil {
			fail(path.Join(dir, "index.md"), err)
			continue
		}
		var refs []reference
		for _, w := range p.Works {
			html, err := render.Inline(w.Text)
			if err != nil {
				fail("works/"+w.Key+".toml", err)
				continue
			}
			refs = append(refs, reference{Key: w.Key, Text: html, Plain: plainReference(w), URL: workURL(w)})
		}
		write(path.Join(dir, "index.html"), "post", page{
			Path: p.Path(), Title: p.Title, Description: p.Summary, NoIndex: !p.Live(), Post: p, Text: text, References: refs,
			Cite: citation(s.Config, p), BibTeX: bibtex(s.Config, p), JSONLD: jsonLD(s.Config, p),
		})
	}

	for _, t := range s.Threads {
		write(path.Join("threads", t.Name, "index.html"), "thread", page{Path: t.Path(), Title: t.Name, Description: t.Description, Thread: t, Posts: t.Posts})
	}
	for _, w := range s.Works {
		html, err := render.Inline(w.Text)
		if err != nil {
			fail("works/"+w.Key+".toml", err)
			continue
		}
		write(path.Join("works", w.Key, "index.html"), "work", page{Path: w.Path(), Title: plainReference(w), Description: "A work cited here, and the posts that cite it.", Work: w, WorkText: html, WorkURL: workURL(w), Posts: w.CitedBy})
	}
	for _, pg := range s.Pages {
		text, err := pg.Doc.HTML(render.Options{Link: s.Local})
		if err != nil {
			fail("pages/"+pg.Name+".md", err)
			continue
		}
		write(path.Join(pg.Name, "index.html"), "page", page{Path: pg.Path(), Title: pg.Title, Description: s.Config.Description, Page: pg, Text: text})
	}

	if f, err := feed(s, func(p *site.Post) (string, error) {
		html, err := postText(s, p, imageNames(p))
		return string(html), err
	}); err != nil {
		fail("feed.xml", err)
	} else {
		files["feed.xml"] = f
	}
	if m, err := sitemap(s); err != nil {
		fail("sitemap.xml", err)
	} else {
		files["sitemap.xml"] = m
	}

	if err := errors.Join(errs...); err != nil {
		return nil, err
	}
	return files, nil
}

// postText is a post's text as HTML: each image at the name it is written
// to, each citation with its work's reference as its tooltip, and each link to
// the site's own address made relative.
func postText(s *site.Site, p *site.Post, images map[string]string) (template.HTML, error) {
	works := map[string]*site.Work{}
	for _, w := range p.Works {
		works["#ref-"+w.Key] = w
	}
	return p.Doc.HTML(render.Options{
		Image: func(dest string) string { return images[dest] },
		Link:  s.Local,
		Title: func(dest string) string {
			if w := works[dest]; w != nil {
				return plainReference(w)
			}
			return ""
		},
	})
}

// imageNames gives each of a post's images the name it is written to: a PNG,
// as dithering makes it.
func imageNames(p *site.Post) map[string]string {
	names := map[string]string{}
	for name := range p.Images {
		names[name] = strings.TrimSuffix(name, path.Ext(name)) + ".png"
	}
	return names
}

// writeImages dithers the post's images into files, next to its page.
func writeImages(files Files, dir string, p *site.Post) (map[string]string, error) {
	names := imageNames(p)
	written := map[string]string{}
	var errs []error
	for name, out := range names {
		if other, ok := written[out]; ok {
			errs = append(errs, fmt.Errorf("images %s and %s would both be %s: rename one", other, name, out))
			continue
		}
		written[out] = name
		img, err := dither.Photo(p.Images[name], ImageWidth)
		if err != nil {
			errs = append(errs, fmt.Errorf("image %s: %w", name, err))
			continue
		}
		files[path.Join(dir, out)] = dither.PNG(img)
	}
	return names, errors.Join(errs...)
}

// byYear groups posts, newest first, by the year they were written.
func byYear(posts []*site.Post) []year {
	var years []year
	for _, p := range posts {
		if len(years) == 0 || years[len(years)-1].Year != p.Date.Year() {
			years = append(years, year{Year: p.Date.Year()})
		}
		years[len(years)-1].Posts = append(years[len(years)-1].Posts, p)
	}
	return years
}

// Write puts the files in dir, which mustn't exist yet or must be empty: a
// site is written whole, never over another one.
func Write(dir string, files Files) error {
	entries, err := os.ReadDir(dir)
	if err != nil && !errors.Is(err, fs.ErrNotExist) {
		return err
	}
	if len(entries) > 0 {
		return fmt.Errorf("%s isn't empty: the site is written to a new or empty folder", dir)
	}
	for name, data := range files {
		file := filepath.Join(dir, filepath.FromSlash(name))
		if err := os.MkdirAll(filepath.Dir(file), 0o755); err != nil {
			return err
		}
		if err := os.WriteFile(file, data, 0o644); err != nil {
			return err
		}
	}
	return nil
}
