CocoaSlideShow
==============

CocoaSlideShow is a Mac OS X simple, fast image viewer, spiritual son of [Slides](http://richardk.info/slides/).

#### CocoaSlideShow is the perfect companion for iPhone GPS tagged photos.

With CocoaSlideShow you can:

  * easily select a few pictures out of big folders [screencast](http://seriot.ch/software/desktop/CocoaSlideShow/screencasts/spotlight.mov)
  * display your photos fullscreen, and use Apple Remote
  * see your photos on a Google Map, as in iPhoto [screencast](http://seriot.ch/software/desktop/CocoaSlideShow/screencasts/google_map.mov)
  * edit the metadata and find them with Spotlight [screencast](http://seriot.ch/software/desktop/CocoaSlideShow/screencasts/spotlight.mov)
  * export lightweight JPEG thumbnails, say for Facebook upload [screencast](http://seriot.ch/software/desktop/CocoaSlideShow/screencasts/resize_images.mov)
  * export KML files to Google Maps or Google Earth [screencast](http://seriot.ch/software/desktop/CocoaSlideShow/screencasts/export_kml.mov)

_I really liked the simplicity of CocoaSlideShow. It's refreshing to use a straightforward, elegant photo viewer that does exactly what it's supposed to with no fuss._ [-Nick Mead, Softonic](http://cocoaslideshow.en.softonic.com/mac)

![CocoaSlideShow](https://raw.github.com/nst/CocoaSlideShow/master/art/CocoaSlideShow_screenshot_small.jpg)
![CocoaSlideShow](https://raw.github.com/nst/CocoaSlideShow/master/art/CocoaSlideShow_Spotlight_screenshot_small.png)
![CocoaSlideShow](https://raw.github.com/nst/CocoaSlideShow/master/art/CocoaSlideShow_screenshot_map_small.png)

CocoaSlideShow embeds [EpegWrapper](http://www.entropy.ch/software/macosx/#epegwrapper), a Cocoa Framework for fast thumbnails generation, by entropy.ch.
<pre>
TODO:
  * show images at pixel resolution, not dpi resolution
  * continuous looping in the slideshow (Tim)
  * update Sparkle

Known bugs:
  * you sometimes have to type 'esc' twice to exit fullscreen

Version 0.5.8
  * Mac OS X 10.6 required
  * display the number of flagged and unflagged images in the tableview header
  * added an option to sort image names by natural order (germ...@gmail.com)
  * application could crash when opening corrupted images

Version 0.5.7
  * can drag multiple files from tableview
  * remember window last position
  * play success sound also after export
  * speed improvements
  * new 16x16 icon

Version 0.5.6
  * resize and export JPEGs in batch
  * much better google map integration
  * fixed crash on startup when default folder had more that 500 images
  * thumbnails are now properly rotated on the map

Version 0.5.5
  * show thumbnails on map
  * add local or remote thumbnails to KML export
  * use camera rotation data
  * remember user rotation
  * fixed "check updates at startup" setting

Version 0.5.4
  * updates with Sparkle
  * fix crash when setting a new default directory
  * fullscreen can use any display, not only the first one (thanks to 0xced)

Version 0.5.3
  * KML files export (Cyril Godefroy)
  * French version
  * important speed and memory optimisations

Version 0.5.2
  * fixed GPS mapping with coordinated at South and/or West

Version 0.5.1
  * can drag and drop from main image view
  * better Google Maps integration
  * fixed delay reset when interrupting slideshow
  * fixed a memory leak

Version 0.5:
  * read GPS tags and show photos on Google Map
  * slideshow can now run in a window (not fullscreen)
  * improved multiple files metadata edition

Version 0.4.6:

  * new toolbar images by Jan Perratt (perratt.com)
  * images are now ordered numerically rather than alphabetically
  * file names are editable by clicking on file name in the tableview

Version 0.4.5:

  * restored Tiger compatibility broken in 0.4.4
  * new toolbar images

Version 0.4.4:

  * speed improvement
  * moved window buttons into the toolbar

Version 0.4.3:

  * opens raw files
  * added an actual automatic slideshow

Version 0.4.2:

  * images do stretch to occupy full screen
  * enabled left/right arrows, work as up/down arrows

Version 0.4.1:

  * memory footprint improvement

Version 0.4:

  * flags
  * minimal undo manager
  * various bug fixes and improvements

Version 0.3:

  * EXIF user comments editor (a free string)
  * IPTC keywords editor (same as in Preview)
  * various bug fixes and improvements

Version 0.2:

  * esc key escapes full screen
  * folders drag and drop on application icon
  * check new updates at startup
  * app icon, credits dimensionofdeskmod.net

Version 0.1:

  * full screen mode
  * handles Apple Remote
  * rotate pictures
  * drag and drop files and folders (recursive)
  * add / remove / export / trash pictures
</pre>