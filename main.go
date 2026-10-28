// Command personal-blog makes the BW20 personal blog from content/: it
// writes the site to a folder (-out), as the Nix build does, or serves it
// while you write (-serve), built again on every request. With -receive it
// is the receiver, which takes posts over Micropub and commits them
// (receive.go).
//
// Reading content/ is in internal/content, putting it together and checking
// it in internal/site, Markdown in internal/render, the files in
// internal/build, and the templates and stylesheet in web.
package main

import (
	"flag"
	"fmt"
	"io/fs"
	"log"
	"mime"
	"net/http"
	"os"
	"path"
	"strings"

	"codeberg.org/BW20/personal-blog/internal/build"
	"codeberg.org/BW20/personal-blog/internal/content"
	"codeberg.org/BW20/personal-blog/internal/site"
	"codeberg.org/BW20/personal-blog/web"
)

func main() {
	fl := flag.NewFlagSet("personal-blog", flag.ExitOnError)
	fl.Usage = func() {
		fmt.Fprint(fl.Output(), "Usage: personal-blog -out <folder> | -serve <host:port> | -receive [flags]\n\nFlags:\n")
		fl.PrintDefaults()
	}
	var (
		contentDir = fl.String("content", "content", "the folder with the posts and pages")
		out        = fl.String("out", "", "write the site to this folder, which mustn't exist yet or must be empty")
		serve      = fl.String("serve", "", "serve the site on this address, such as 127.0.0.1:8080, built again on every request (development)")
		devAssets  = fl.String("dev-assets", "", "read the templates and stylesheet from web/ in this folder instead of the program, so edits show at once (development)")
		buildNum   = fl.Int("build", 0, "the build number at the foot of every page, the commit count; left out when 0")
		receive    = fl.Bool("receive", false, "be the receiver: take posts over Micropub, and commit them (the -listen, -base-url, -push-url, -branch, -author, -token-file, -ssh-key-file, -known-hosts and -state flags)")
		r          = receiverFlags(fl)
	)
	fl.Parse(os.Args[1:])
	// A wrong invocation exits with 2, as a wrong flag does.
	if *receive {
		if err := r.run(); err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(2)
		}
		return
	}
	if (*out == "") == (*serve == "") {
		fmt.Fprintln(os.Stderr, "give one of -out, -serve and -receive")
		fl.Usage()
		os.Exit(2)
	}

	var assets fs.FS = web.Files
	if *devAssets != "" {
		sub, err := fs.Sub(os.DirFS(*devAssets), "web")
		if err != nil {
			log.Fatal(err)
		}
		assets = sub
	}
	make := func() (build.Files, error) {
		c, err := content.Read(os.DirFS(*contentDir))
		if err != nil {
			return nil, err
		}
		s, err := site.New(c)
		if err != nil {
			return nil, err
		}
		return build.Site(s, assets, build.Options{Build: *buildNum})
	}

	if *out != "" {
		files, err := make()
		if err != nil {
			log.Fatal(err)
		}
		if err := build.Write(*out, files); err != nil {
			log.Fatal(err)
		}
		return
	}
	log.Printf("serving on http://%s", *serve)
	log.Fatal(http.ListenAndServe(*serve, devHandler(make)))
}

// devHandler builds the site on every request and serves the file asked
// for, or the build's error, so a change to a post or a template shows on
// reload.
func devHandler(site func() (build.Files, error)) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		files, err := site()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		name := strings.TrimPrefix(r.URL.Path, "/")
		if name == "" || strings.HasSuffix(name, "/") {
			name += "index.html"
		}
		data, ok := files[name]
		if !ok {
			http.NotFound(w, r)
			return
		}
		kind := mime.TypeByExtension(path.Ext(name))
		if kind == "" {
			kind = "text/plain; charset=utf-8" // cite.bib, the nginx includes
		}
		w.Header().Set("Content-Type", kind)
		w.Write(data)
	})
}
