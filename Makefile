VERSION=1.5

DEBUG= -g
CFLAGS+=-DVERSION=\"${VERSION}\" $(DEBUG) -muclibc
LDFLAGS+=$(DEBUG) -lm -lrt #-muclibc -static

OBJS=error.o gpio-int-test.o main.o

all: rpi_gpio_ntp

rpi_gpio_ntp: $(OBJS)
	$(CC) -Wall -W $(OBJS) $(LDFLAGS) -o rpi_gpio_ntp

install: rpi_gpio_ntp
	cp rpi_gpio_ntp /usr/local/bin
	if [ ! -f /etc/default/rpi_gpio_ntp ]; then cp systemd/rpi_gpio_ntp.env /etc/default/rpi_gpio_ntp; fi
	if [ ! -f /etc/default/gps0         ]; then cp systemd/gps0.env         /etc/default/gps0; fi
	install --backup --mode 644 systemd/rpi_gpio_ntp.service /etc/systemd/system/
	install --backup --mode 644 systemd/gps0.service         /etc/systemd/system/
	systemctl daemon-reload

clean:
	rm -f $(OBJS) rpi_gpio_ntp

package: clean
	mkdir rpi_gpio_ntp-$(VERSION)
	cp *.c *.h Makefile readme.txt license.txt rpi_gpio_ntp-$(VERSION)
	tar czf rpi_gpio_ntp-$(VERSION).tgz rpi_gpio_ntp-$(VERSION)
	rm -rf rpi_gpio_ntp-$(VERSION)
