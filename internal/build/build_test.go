package build

import (
	"bytes"
	"image"
	"image/color"
	"image/png"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"
	"time"

	"codeberg.org/BW20/personal-blog/internal/content"
	"codeberg.org/BW20/personal-blog/internal/site"
	"codeberg.org/BW20/personal-blog/web"
)

func photo(t *testing.T) []byte {
	img := image.NewRGBA(image.Rect(0, 0, 1200, 600))
	for y := range 600 {
		for x := range 1200 {
			img.Set(x, y, color.RGBA{uint8(x / 5), 120, 80, 255})
		}
	}
	var buf bytes.Buffer
	if err := png.Encode(&buf, img); err != nil {
		t.Fatal(err)
	}
	return buf.Bytes()
}

// sample is a small site: two posts up, one older than a year, one
// withdrawn, a page, a thread, a work, an alias and an image.
func sample(t *testing.T) *site.Site {
	c := &content.Site{
		Config: content.Config{
			Title: "BW20", URL: "https://bw20.nl", Description: "A small, finite website.",
			Author: content.Author{Given: "Jorrit", Family: "van der Heide"},
			Menu:   []content.MenuItem{{Name: "log", Link: "/log/"}, {Name: "about", Link: "/about/"}},
		},
		Threads: []content.Thread{{Name: "tech", Description: "Notes on NixOS."}},
		Works:   []content.Work{{Key: "marsh2020", Text: "Marsh, Ann. 2020. *Archives & Readers*.", URL: "https://doi.org/10.1/x"}},
		Pages:   []content.Page{{Name: "about", Title: "About", Body: []byte("Who, why.")}},
		Posts: []content.Post{
			{Slug: "quiet", Title: "The NixOS module system is a quiet revolution", Summary: "Why it matters.",
				Date: time.Date(2026, 3, 15, 10, 0, 0, 0, time.UTC), Threads: []string{"tech"}, Aliases: []string{"nixos"},
				References: []string{"marsh2020"},
				Body:       []byte("As [(Marsh 2020, 12)](/works/marsh2020/) says, and [before](/log/older/).\n\n![A raised bed](bed.jpg)\n\n## More"),
				Images:     map[string][]byte{"bed.jpg": photo(t)}},
			{Slug: "older", Title: "Older", Summary: "From before.", Date: time.Date(2025, 1, 5, 10, 0, 0, 0, time.UTC),
				Body: []byte("Old words.")},
			{Slug: "gone", Title: "Gone", Summary: "Not any more.", Date: time.Date(2026, 2, 1, 10, 0, 0, 0, time.UTC),
				Withdrawn: time.Date(2026, 4, 1, 10, 0, 0, 0, time.UTC), Body: []byte("Secret words.")},
		},
	}
	s, err := site.New(c)
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func build(t *testing.T) Files {
	files, err := Site(sample(t), web.Files, Options{Build: 42})
	if err != nil {
		t.Fatal(err)
	}
	return files
}

func contains(t *testing.T, files Files, name string, want ...string) {
	t.Helper()
	f, ok := files[name]
	if !ok {
		t.Errorf("no %s", name)
		return
	}
	for _, w := range want {
		if !strings.Contains(string(f), w) {
			t.Errorf("%s: no %q in\n%s", name, w, f)
		}
	}
}

func lacks(t *testing.T, files Files, name string, not ...string) {
	t.Helper()
	for _, n := range not {
		if strings.Contains(string(files[name]), n) {
			t.Errorf("%s: %q in it", name, n)
		}
	}
}

func TestPost(t *testing.T) {
	files := build(t)
	contains(t, files, "log/quiet/index.html",
		"<title>The NixOS module system is a quiet revolution · BW20</title>",
		`<link rel="canonical" href="https://bw20.nl/log/quiet/">`,
		`<link rel="stylesheet" href="/static/site.css?v=`,
		`<a href="/log/" aria-current="page">log</a>`,
		`<time datetime="2026-03-15">early spring 2026</time>`,
		`in <a href="/threads/tech/">tech</a>`,
		`<a href="/works/marsh2020/" title="Marsh, Ann. 2020. Archives &amp; Readers.">(Marsh 2020, 12)</a>`,
		`<img src="bed.png" alt="A raised bed">`,
		`<li id="ref-marsh2020">Marsh, Ann. 2020. <em>Archives &amp; Readers</em>. <a href="https://doi.org/10.1/x">`,
		`van der Heide, Jorrit. 2026. “The NixOS module system is a quiet revolution.” <em>BW20</em>, 15 March.`,
		"@online{quiet,",
		`<meta name="citation_title" content="The NixOS module system is a quiet revolution">`,
		`<meta name="citation_author" content="van der Heide, Jorrit">`,
		`<meta name="citation_publication_date" content="2026/03/15">`,
		`<meta name="citation_reference" content="Marsh, Ann. 2020. Archives &amp; Readers.">`,
		`<script type="application/ld+json">`, `"@type":"BlogPosting"`,
		`<meta property="og:type" content="article">`,
		"Build 42.",
	)
	// Linked from the newer post.
	contains(t, files, "log/older/index.html", "Linked from", `<a href="/log/quiet/">`)
	lacks(t, files, "log/quiet/index.html", "Linked from")
}

func TestCiteBib(t *testing.T) {
	contains(t, build(t), "log/quiet/cite.bib",
		"@online{quiet,\n",
		"  author = {van der Heide, Jorrit},\n",
		"  title = {{The NixOS module system is a quiet revolution}},\n",
		"  date = {2026-03-15},\n",
		"  url = {https://bw20.nl/log/quiet/},\n",
	)
	if got := bibEscape(`50% & $5_#{x}`); got != `50\% \& \$5\_\#\{x\}` {
		t.Errorf("bibEscape = %q", got)
	}
}

func TestWithdrawn(t *testing.T) {
	files := build(t)
	contains(t, files, "log/gone/index.html", `<meta name="robots" content="noindex">`, "withdrawn in", `<time datetime="2026-04-01">mid spring 2026</time>`)
	lacks(t, files, "log/gone/index.html", "Secret words", `rel="canonical"`)
	contains(t, files, "log/gone/cite.bib", "@online{gone,")
	// Off every list.
	for _, name := range []string{"index.html", "log/index.html", "threads/tech/index.html", "feed.xml", "sitemap.xml"} {
		lacks(t, files, name, "/log/gone/")
	}
}

func TestLists(t *testing.T) {
	files := build(t)
	contains(t, files, "index.html", "<title>BW20</title>", "A small, finite website.", `<a href="/log/quiet/">`, `<a class="name" href="/" aria-current="page">`)
	contains(t, files, "log/index.html", "<h2>2026</h2>", "<h2>2025</h2>")
	contains(t, files, "threads/tech/index.html", "<h1>tech</h1>", "Notes on NixOS.", `<a href="/log/quiet/">`)
	contains(t, files, "works/marsh2020/index.html", "<em>Archives &amp; Readers</em>", "Cited in", `<a href="/log/quiet/">`)
	contains(t, files, "about/index.html", "<h1>About</h1>", "<p>Who, why.</p>", `<a href="/about/" aria-current="page">about</a>`)
	contains(t, files, "404.html", `<meta name="robots" content="noindex">`, "Not here")
}

func TestFeeds(t *testing.T) {
	files := build(t)
	contains(t, files, "feed.xml",
		`<feed xmlns="http://www.w3.org/2005/Atom">`,
		"<id>https://bw20.nl/log/quiet/</id>",
		`<content type="html" xml:base="https://bw20.nl/log/quiet/">`,
		"&lt;img src=&#34;bed.png&#34;",
		// As new as the newest post, not the build.
		"<updated>2026-03-15T10:00:00Z</updated>",
	)
	contains(t, files, "sitemap.xml", "<loc>https://bw20.nl/log/quiet/</loc>", "<lastmod>2026-03-15</lastmod>", "<loc>https://bw20.nl/works/marsh2020/</loc>")
}

func TestServerFiles(t *testing.T) {
	files := build(t)
	contains(t, files, "robots.txt", "User-agent: *\nAllow: /\n", "User-agent: GPTBot\nDisallow: /\n", "Sitemap: https://bw20.nl/sitemap.xml")
	contains(t, files, "nginx/location/crawlers.conf", `if ($http_user_agent ~* "(GPTBot|ChatGPT-User|`, "return 403;")
	contains(t, files, "nginx/server/aliases.conf", "location = /log/nixos/ {\n    return 301 /log/quiet/;\n}\n")
	contains(t, files, "static/site.css", ":root")
	if _, err := png.DecodeConfig(bytes.NewReader(files["log/quiet/bed.png"])); err != nil {
		t.Errorf("log/quiet/bed.png: %v", err)
	}
}

func TestTime(t *testing.T) {
	for _, tt := range []struct {
		month time.Month
		want  string
	}{{time.January, "mid winter 2026"}, {time.March, "early spring 2026"}, {time.August, "late summer 2026"}, {time.December, "early winter 2026"}} {
		if got := season(time.Date(2026, tt.month, 10, 0, 0, 0, 0, time.UTC)); got != tt.want {
			t.Errorf("season(%v) = %q, want %q", tt.month, got, tt.want)
		}
	}
}

func TestCrawlers(t *testing.T) {
	if _, err := crawlers([]byte("GPTBot\nBad Bot\n")); err == nil {
		t.Error("a name with a space went into nginx's configuration")
	}
}

// A template that fails makes no site at all, not one without that page.
func TestSiteTemplateError(t *testing.T) {
	assets := fstest.MapFS{"static/site.css": {}, "crawlers.txt": {Data: []byte("GPTBot")}}
	for _, kind := range kinds {
		assets["templates/"+kind+".html"] = &fstest.MapFile{Data: []byte(`{{define "main"}}{{end}}`)}
	}
	assets["templates/posts.html"] = &fstest.MapFile{}
	assets["templates/base.html"] = &fstest.MapFile{Data: []byte(`{{define "base"}}{{.Missing}}{{end}}`)}
	files, err := Site(sample(t), assets, Options{})
	if err == nil || !strings.Contains(err.Error(), "log/quiet/index.html") {
		t.Fatalf("err = %v, want one naming log/quiet/index.html", err)
	}
	if files != nil {
		t.Errorf("files = %v, want none", files)
	}
}

func TestWrite(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "site")
	if err := Write(dir, Files{"log/quiet/index.html": []byte("page")}); err != nil {
		t.Fatal(err)
	}
	got, err := os.ReadFile(filepath.Join(dir, "log", "quiet", "index.html"))
	if err != nil || string(got) != "page" {
		t.Fatalf("got %q, %v", got, err)
	}
	// Never over another site.
	if err := Write(dir, Files{"index.html": []byte("other")}); err == nil {
		t.Fatal("wrote over a site")
	}
}

// A site with no posts yet builds, and says so.
func TestNoPosts(t *testing.T) {
	c := &content.Site{
		Config:  content.Config{Title: "BW20", URL: "https://bw20.nl", Description: "A site.", Author: content.Author{Given: "J", Family: "H"}},
		Threads: []content.Thread{{Name: "tech", Description: "Tech."}},
	}
	s, err := site.New(c)
	if err != nil {
		t.Fatal(err)
	}
	files, err := Site(s, web.Files, Options{})
	if err != nil {
		t.Fatal(err)
	}
	contains(t, files, "index.html", "No posts yet.")
	contains(t, files, "log/index.html", "No posts yet.")
	contains(t, files, "threads/tech/index.html", "No posts in this thread yet.")
	contains(t, files, "feed.xml", "<updated>1970-01-01T00:00:00Z</updated>")
	lacks(t, files, "index.html", "Newest")
}
