# Maintainer: thek4n

pkgname='bkp'
pkgver=0.1.1
pkgrel=1
pkgdesc=""
arch=('any')
license=('MIT')
depends=(
  'git'
  'gnupg'
  'rsync'
  'tree'
)
makedepends=('git')
url='https://github.com/thek4n/bkp'
conflicts=('bkp')
source=("$pkgname::git+https://github.com/thek4n/bkp.git#branch=master")
sha256sums=('SKIP')

package() {
    cd "$srcdir"/"$pkgname"
    make DESTDIR="$pkgdir" PREFIX="/usr" install
}
