# The annoying(ly exact) border clock

This is a little toy for the C64, demonstrating the possibility to create an
exactly running clock. It's compatible with PAL and NTSC machines and works
by polling a timer, so interrupts can be used undisturbed for VIC-II effects.
To demonstrate this, the clock is shown in the border.

Because polling the clock is done in a raster IRQ, the clock will go wrong
when IRQs are disabled, for example by the stock disk and tape I/O routines.

