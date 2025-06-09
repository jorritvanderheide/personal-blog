+++
title = 'Going with the flow on monday'
subtitle = 'The curious journey of Ms. Kimbot and her two cats'
date = 2023-01-15T09:00:00-07:00
lead = 'Sometimes, it takes to long to write a long sentence. Why use many words if few words do job? Some questions might not be worth asking. Some questions might not be worth asking.Some questions might not be worth asking.'
draft = false
+++

Tempor proident minim aliquip reprehenderit dolor et ad anim Lorem duis sint eiusmod. Labore ut ea
duis dolor. Incididunt consectetur proident qui occaecat incididunt do nisi Lorem. Tempor do laborum
elit laboris excepteur eiusmod do. Eiusmod nisi excepteur ut amet pariatur adipisicing Lorem.

```js {title = "example.js"}
// Example of a Js code block
document.addEventListener("DOMContentLoaded", () => {
  const copyButtons = document.querySelectorAll(".copy-button")

  copyButtons.forEach(button => {
    button.addEventListener("click", () => {
      const code = button.nextElementSibling.querySelector("code")
      if (!code) return

      const text = Array.from(code.querySelectorAll(".line"))
        .map(line => line.textContent.replace(/^\s*\d+\s*/, ""))
        .join("\n")

      navigator.clipboard
        .writeText(text)
        .then(() => {
          button.textContent = "copied!"
          setTimeout(() => (button.textContent = "copy"), 1500)
        })
        .catch(() => {
          alert("Copy failed. Try manually.")
        })
    })
  })
})
```

Occaecat nulla excepteur dolore excepteur duis eiusmod ullamco officia anim in voluptate ea occaecat
officia. Cillum sint esse velit ea officia minim fugiat. Elit ea esse id aliquip pariatur cupidatat
id duis minim incididunt ea ea. Anim ut duis sunt nisi. Culpa cillum sit voluptate voluptate eiusmod
dolor. Enim nisi Lorem ipsum irure est excepteur voluptate eu in enim nisi. Nostrud ipsum Lorem anim
sint labore consequat do.

### A day in the park

Occaecat nulla excepteur dolore excepteur duis eiusmod ullamco officia anim in voluptate ea occaecat
officia. Cillum sint esse velit ea officia minim fugiat. Elit ea esse id aliquip pariatur cupidatat
id duis minim incididunt ea ea. Anim ut duis sunt nisi. Culpa cillum sit voluptate voluptate eiusmod
dolor. Enim nisi Lorem ipsum irure est excepteur voluptate eu in enim nisi. Nostrud ipsum Lorem anim
sint labore consequat do.

Tempor proident minim aliquip reprehenderit dolor et ad anim Lorem duis sint eiusmod. Labore ut ea
duis dolor. Incididunt consectetur proident qui occaecat incididunt do nisi Lorem. Tempor do laborum
elit laboris excepteur eiusmod do. Eiusmod nisi excepteur ut amet pariatur adipisicing Lorem.

![Image of the week](/images/img1.png "An optional caption")

Occaecat nulla excepteur dolore excepteur duis eiusmod ullamco officia anim in voluptate ea occaecat
officia. Cillum sint esse velit ea officia minim fugiat. Elit ea esse id aliquip pariatur cupidatat
id duis minim incididunt ea ea. Anim ut duis sunt nisi. Culpa cillum sit voluptate voluptate eiusmod
dolor. Enim nisi Lorem ipsum irure est excepteur voluptate eu in enim nisi. Nostrud ipsum Lorem anim
sint labore consequat do.

### Or a day beyond the sun I think

Tempor proident minim aliquip reprehenderit dolor et ad anim Lorem duis sint eiusmod. Labore ut ea
duis dolor. Incididunt consectetur proident qui occaecat incididunt do nisi Lorem. Tempor do laborum
elit laboris excepteur eiusmod do. Eiusmod nisi excepteur ut amet pariatur adipisicing Lorem.

Occaecat nulla excepteur dolore excepteur duis eiusmod ullamco officia anim in voluptate ea occaecat
officia. Cillum sint esse velit ea officia minim fugiat. Elit ea esse id aliquip pariatur cupidatat
id duis minim incididunt ea ea. Anim ut duis sunt nisi. Culpa cillum sit voluptate voluptate eiusmod
dolor. Enim nisi Lorem ipsum irure est excepteur voluptate eu in enim nisi. Nostrud ipsum Lorem anim
sint labore consequat do.
