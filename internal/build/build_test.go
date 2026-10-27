package build

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"testing/fstest"
	"time"

	"codeberg.org/BW20/personal-blog/internal/content"
	"codeberg.org/BW20/personal-blog/web"
)

var quiet = content.Post{
	Slug:    "quiet",
	Title:   "The NixOS module system is a quiet revolution",
	Summary: "Why declarative configuration changes how we think about infrastructure.",
	Date:    time.Date(2026, 3, 15, 10, 0, 0, 0, time.UTC),
	Body:    []byte("Most people get lost in the *syntax*."),
}

func TestSite(t *testing.T) {
	files, err := Site([]content.Post{quiet}, web.Files)
	if err != nil {
		t.Fatal(err)
	}
	page, ok := files["log/quiet/index.html"]
	if !ok {
		t.Fatalf("no log/quiet/index.html in %v", files)
	}
	for _, want := range []string{
		`<html lang="en">`,
		"<title>The NixOS module system is a quiet revolution</title>",
		`<meta name="description" content="Why declarative configuration changes how we think about infrastructure.">`,
		"<h1>The NixOS module system is a quiet revolution</h1>",
		`<time datetime="2026-03-15">15 March 2026</time>`,
		"<p>Most people get lost in the <em>syntax</em>.</p>",
	} {
		if !strings.Contains(string(page), want) {
			t.Errorf("no %q in\n%s", want, page)
		}
	}
}

// A template that fails makes no site at all, not one without that page.
func TestSiteTemplateError(t *testing.T) {
	assets := fstest.MapFS{
		"templates/base.html": {Data: []byte(`{{define "base"}}{{.Missing}}{{end}}`)},
		"templates/post.html": {Data: []byte(``)},
	}
	files, err := Site([]content.Post{quiet}, assets)
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
