# Use Debian Chromium 32bit in Fedora

As there is no 32bit Linux version of Chrome (since March 2016) &
Fedora doesn't provide 32bit Chromium build, we can download .deb
package & convert it to rpm-format.

This makefile (you're not supposed to understand how it works)
*automatically detects* the latest pkg version in all official Debian
repos, fetches it & does the conversion.

## Requirements

	# dnf install alien dpkg curl rpm-build

(We don't need any of `apt` utils!)

## Usage

Clone the repo, then run:

	$ make

If you're only interested in the .deb url, type:

	$ make url

If everything was ok:

	$ sudo rpm -i --nodeps build/fedora/chromium/chromium-48.0.2564.116-1~deb8u1.i686.rpm

In Fedora 23 you'll also need:

	# dnf install libsrtp speech-dispatcher
	# cd /usr/lib
	# ln -s libsrtp.so.1.0.0 libsrtp.so.0

## Configuration

You can run `make NAME=some-package-name`, it should work too. For
Debian release & arch see `conf.mk`.

## License

MIT.
