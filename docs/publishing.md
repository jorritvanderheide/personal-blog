# Publishing

Posts come from Obsidian, through the
[In the Open](https://codeberg.org/BW20/obsidian-in-the-open) plugin. What it
sends is specified in its
[`docs/micropub.md`](https://codeberg.org/BW20/obsidian-in-the-open/src/branch/main/docs/micropub.md):
Micropub, and the references extension. This page is how this site takes
it.

The receiver is the third way to run the program, in `internal/micropub/`.
It takes requests by that spec and turns each into a commit to the site's
repository. It never builds or serves the site; the repository stays the
only input, and the build stays reproducible. The host's deploy timer picks
the commit up like any other, as [Deployment](architecture.md#deployment)
describes.

For each request, one at a time:

1. Fetch the repository and reset to the remote's `main`.
2. Translate the request into files under `content/`, as the table below
   says.
3. Run the site's checks on `content/` with the change laid over it, in
   memory. A change that would break the build is refused with `400` and the
   build's own messages, and nothing is written.
4. Commit, as `publish: <slug>`, `update: <slug>`, `withdraw: <slug>` or
   `restore: <slug>`, and push. A rejected push is fetched and tried once
   more.
5. Answer: `202 Accepted` for a new post, `204 No Content` for the rest.

| Micropub | This site |
| --- | --- |
| `name` | `title` |
| `summary` | `summary`, required as for every post |
| `content` | the body of `content/log/<slug>/index.md` |
| `category` | `threads`, each one in `threads.toml` |
| `mp-slug` | the slug, else one made from the title |
| `published` | `date` |
| `updated` | `updated` |
| `references` | the keys in `references`, and each work's `text` and `url` in `content/works/<key>.toml`; `csl` is not kept |
| delete, undelete | `withdrawn` set or removed |

- **Links are made the site's own.** `#ref-<key>` becomes `/works/<key>/`, a
  link to one of the site's posts becomes `/log/<slug>/`, and an image the
  media endpoint holds moves into the post's folder and is linked by its
  file name.
- **A slug already taken**, by a post or an alias, is refused rather than
  numbered: slugs never change, so you choose.
- **A post without `generator`** is hand-written, and an update or withdrawal
  of it is `403`. Every post the receiver writes has
  `generator = 'micropub'`.
- **Requests are JSON**, as In the Open sends them, and an update replaces
  what changed (`replace`); `add` and `delete` aren't taken, nor `q=source`.
  A slug, a date and an alias never change through the receiver.
- **Uploads** are PNG or JPEG, at most 20 MB. They wait in the receiver's
  state directory, named by their hash and served at their URL, and are
  removed after a day if no post takes them. Next to its post, an image is
  named by the start of its hash.

`services.personal-blog.receiver` runs it: `enable`, `tokenFile`, `pushUrl`,
`sshKeyFile` (a deploy key for this repository only), the forge's
`knownHosts`, and the commit `author`. The token and the key reach it as
systemd credentials, so they stay out of the Nix store.

- **It runs the program the deploy built**, not one from the host's
  configuration, and restarts after each deploy. So its checks are the ones
  the build that publishes the post will run.
- **It runs as its own user**, not the deploy's, so the commits the host
  builds can't read its key.
- **nginx passes `/micropub` to it**, over a socket only nginx may open, and
  the home page gets the `Link: </micropub>; rel="micropub"` header.
