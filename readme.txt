rpi_gpio_ntp
------------
Written by Folkert van Heusden (folkert@vanheusden.com).
Released under GPLv2.
Feel free to send me an e-mail if you have any questions (but first fully read this manual!).


usage
-----
In this example I connected an Adafruit GPS rx/tx to the uart on the GPIO pins and connected the PPS to GPIO pin 8.
See http://learn.adafruit.com/adafruit-ultimate-gps-on-the-raspberry-pi/using-uart-instead-of-usb for connection details.
See http://jeffskinnerbox.files.wordpress.com/2012/11/raspberry-pi-rev-1-gpio-pin-out1.jpg for a list of the physical pins and what GPIO pin they correspond to.

First, install gpsd:
	sudo apt-get install gpsd gpsd-clients
then configure it to listen on on the correct device. For that, edit /etc/default/gpsd:
	sudo vi /etc/default/gpsd
and make sure the following three lines are set (replace the originals):
	# change the options.
	START_DAEMON="true"
	GPSD_OPTIONS="-n"
	DEVICES="/dev/ttyAMA0"

Then remove the console from the serial port:
	sudo vi /etc/inittab
and remove the following line:
	T0:23:respawn:/sbin/getty -L ttyAMA0 115200 vt100
You must also instruct the kernel to not listen on the serial port:
	sudo vi /boot/cmdline.txt
and remove:
	console=ttyAMA0,115200
	kgdboc=ttyAMA0,115200

By now you have already unpacked rpi_gpio_ntp (or else you would not be able to read this file.)
At this step you must build and install the program:
	sudo make install

You probably want to let rpi_gpio_ntp start at boot.
- To change the GPIO pin for the PPS signal of your GPS (or Rubidium clock,
  or whatever), edit `/etc/default/rpio_gpio_ntp`
- To start the service at boot, run `systemctl enable --now rpi_gpio_ntp`.

The last step is configuring ntpd.
	sudo vi /etc/ntp.conf
and add (wherever you like) the following lines:
	server 127.127.28.0 minpoll 4
	fudge  127.127.28.0 time1 0.304 refid NMEA
	server 127.127.28.1 minpoll 4 maxpoll 4 prefer
	fudge  127.127.28.1 refid PPS

At this point you can reboot your Raspberry Pi.

If you would like to test first if the PPS comes in, run:
	/usr/local/bin/rpi_gpio_ntp -N 1 -g 8 -d
This will give output like this:
	1371569923.000254550] poll() GPIO 8 interrupt occurred
	1371569924.000251953] poll() GPIO 8 interrupt occurred
	1371569925.000251352] poll() GPIO 8 interrupt occurred 
The first value (before the ']') will be different as it is a timestamp and '8' will be different if you let the program "listen" on a different GPIO port.
Run
	/usr/local/bin/rpi_gpio_ntp -h
to see a list of all parameters accepted by the program. You can, for example, let it pulse an other GPIO pin when it "receives" a pulse from the GPS. If you then measure both the PPS and that "reply-pulse" with an oscilloscoop, you may be able to determine the latency of the rpi_gpio_ntp program and the Linux kernel.

If AFTER THE REBOOT OF THE RPI you would like to verify that it works, run the following command:
	ntpq -c pe -n
this will give output like this:
     remote           refid      st t when poll reach   delay   offset  jitter
==============================================================================
-192.168.64.1    192.168.64.2     3 u   33   64  377    0.544   -3.148   0.534 <--- *1
-192.168.64.100  192.168.64.2     3 u    8   64  377    0.515   -3.142   0.087 <--- *1
+192.168.62.129  194.109.20.18    3 u    5   64  377    1.048   -2.901   0.062 <--- *1
+194.109.22.18   193.67.79.202    2 u    5   64  377   17.891   -2.568   0.246 <--- *1
x127.127.28.0    .NMEA.           0 l   14   16  377    0.000  -195.80  16.917 <--- *2
*127.127.28.1    .PPS.            0 l   15   16  377    0.000    0.017   0.009 <--- *2

*1: these four lines will probably be different at your computer.
*2: the offset/jitter shown will be different. "reach" should become 377 after a while. If not: somethings is wrong. Check then if gpsd is running, and if rpi_gpio_ntp is running. If you use a GPS for PPS source, make sure it has a fix. You can verify this with the following program:
	cgps
Look for the following line:
	│    Status:     3D FIX (5 secs)            │
The "FIX" is the important one: if it is not there, then there won't be a usefull PPS. If the "secs" keeps resetting, then the GPS signal is too weak: move the antenna closer to a window or even outside (if it is build for that).
You can also run:
	gpsmon
This will show an "HDOP" value (right window). The lower this value is, the better. See e.g. http://en.wikipedia.org/wiki/Dilution_of_precision_(GPS) for an explanation of this value and a table showing what value means what rating. A value less than 5 should be good enough. At home, I get a value of 0.84(!).


note
----
This program is based on gpio-int-test.c written by Ridgerun.
I retrieved it from: https://www.ridgerun.com/developer/wiki/index.php/Gpio-int-test.c
