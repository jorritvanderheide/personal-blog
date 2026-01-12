+++
title = '{{ replace .File.ContentBaseName "-" " " | title }}'
summary = ''
date = '{{ .Date }}'
lastmod = '{{ .Date }}'
draft = true
cover = 'cover.jpg'
categories = []
tags = ['article']

[author]
  name = '{{ site.Params.author | default "Author" }}'
+++

<!--more-->
