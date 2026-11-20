# Third-party notices

The Ruby code in this gem is MIT licensed (see `MIT-LICENSE`). The qpdf
executables in `libexec/` are separate works, distributed under their own
licenses. Each is one static executable that links the components below.
`libexec/qpdf-linux-<arch>.buildinfo` records the exact package versions used
for each build.

| Component | License | Text |
| --- | --- | --- |
| [qpdf](https://github.com/qpdf/qpdf) | Apache-2.0 | `licenses/qpdf-LICENSE.txt`, `licenses/qpdf-NOTICE.md` |
| [OpenSSL](https://www.openssl.org/) 3.x | Apache-2.0 | Same Apache License 2.0 text as `licenses/qpdf-LICENSE.txt` |
| [libjpeg-turbo](https://libjpeg-turbo.org/) | IJG, BSD-3-Clause, zlib | `licenses/libjpeg-turbo-LICENSE.md`, `licenses/libjpeg-turbo-README.ijg` |
| [zlib](https://zlib.net/) | zlib | `licenses/zlib-LICENSE.txt` |
| [musl libc](https://musl.libc.org/) | MIT | Reproduced below |
| libstdc++ and libgcc (GCC) | GPL-3.0 with the GCC Runtime Library Exception | The exception permits distributing the compiled result under any terms |

`bin/build-binaries` copies the qpdf, libjpeg-turbo and zlib texts out of the
build itself, and CI fails if they drift from the committed copies.

This software is based in part on the work of the Independent JPEG Group.

## musl libc

```
Copyright © 2005-2020 Rich Felker, et al.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
