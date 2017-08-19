# Use Debian Chromium in Fedora

As there is no 32bit Linux version of Chrome (since Mar 2016) & Fedora
doesn't provide a 32bit Chromium build, we can download .deb package &
convert it to rpm-format.

The trick also works for the 64bit version.

This makefile (you're not supposed to understand how it works)
*automatically detects* the latest pkg version in all official Debian
repos, fetches it & does the conversion.

## Requirements

	# dnf install alien dpkg curl rpm-build

(We don't need any of `apt` utils!)

## Usage

Clone the repo, then run:

	$ make

or

	$ make index.type=binary-amd64

If you're only interested in the .deb url, type:

	$ make url

If you're building a 32bit version on a 64bit machine:

	$ make rpmbuild=--target=i686

If everything was ok:

	$ sudo rpm -i --nodeps build/fedora/chromium/chromium-60.0.3112.78-1~deb9u1.x86_64.rpm

## Configuration

You can run `make NAME=some-package-name`, it should work too. For
Debian release & arch see `conf.mk`.

## License

MIT.
